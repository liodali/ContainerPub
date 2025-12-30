#!/usr/bin/env python3.14
import argparse
import json
import sys
from pathlib import Path
from podman import PodmanClient
from typing import Optional, Dict, Any, List


class PodmanCLI:
    def __init__(self, socket_path: str):
        self.socket_path = socket_path
        self.client = PodmanClient(base_url=f"unix://{self.socket_path}")

    def connect(self) -> bool:
        try:
            if(self.client.ping() != False) :
                self.client = PodmanClient(base_url=f"unix://{self.socket_path}")
                return True
            return False
        except Exception as e:
            self._output_error(f"Failed to connect to Podman socket: {str(e)}")
            return False

    def _output_success(self, data: Any):
        print(json.dumps({"success": True, "data": data}, indent=2))

    def _output_error(self, message: str):
        print(json.dumps({"success": False, "error": message}, indent=2), file=sys.stderr)

    def image_exists(self, image_tag: str) -> bool:
        """Check if an image exists locally."""
        try:
            self.client.images.get(image_tag)
            return True
        except Exception:
            return False

    def container_exists(self, container_name: str) -> bool:
        """Check if a container exists (running or stopped)."""
        try:
            self.client.containers.get(container_name)
            return True
        except Exception:
            return False

    def get_arch_platform(self) -> str:
        """Get the architecture platform (e.g., linux/amd64, linux/arm64)."""
        try:
            info = self.client.info()
            os_type = info.get('host', {}).get('os', 'linux')
            arch = info.get('host', {}).get('arch', 'amd64')
            return f"{os_type}/{arch}"
        except Exception as e:
            self._output_error(f"Failed to get architecture platform: {str(e)}")
            return "linux/amd64"

    def pull(self, imageName: str) -> None:
        """Pull an image from a registry."""
        try:
            repository, tag = imageName.split(':') if ':' in imageName else (imageName, 'latest')
            self.client.images.pull(repository, tag)
            self._output_success({"image": imageName, "message": "Image pulled successfully"})
        except Exception as e:
            self._output_error(f"Failed to pull image: {str(e)}")
    def list_images(self, all_images: bool = False) -> None:
        try:
            images = self.client.images.list(all=all_images)
            images_data = []
            for img in images:
                images_data.append({
                    "id": img.id,
                    "tags": img.tags,
                    "size": img.attrs.get("Size", 0),
                    "created": img.attrs.get("Created", ""),
                    "digest": img.attrs.get("Digest", ""),
                })
            self._output_success(images_data)
        except Exception as e:
            self._output_error(f"Failed to list images: {str(e)}")

    def build_image(self, context_path: str, tag: Optional[str] = None, 
                   dockerfile: str = "Dockerfile", buildargs: Optional[Dict[str, str]] = None,
                   platform: Optional[str] = None, nocache: bool = False,
                   rm: bool = True) -> None:
        """Build a container image from a Dockerfile.
        
        Args:
            context_path: Build context directory path
            tag: Image tag (e.g., myapp:latest)
            dockerfile: Dockerfile name (default: Dockerfile)
            buildargs: Build arguments as key-value pairs
            platform: Target platform (e.g., linux/amd64, linux/arm64)
            nocache: Do not use cache when building
            rm: Remove intermediate containers after build (default: True)
        """
        try:
            # Check if image already exists
            if tag and self.image_exists(tag):
                self._output_error(f"Image '{tag}' already exists. Use --force to rebuild or choose a different tag.")
                return

            # Auto-detect platform if not provided
            if not platform:
                platform = self.get_arch_platform()

            build_params = {
                "path": context_path,
                "dockerfile": dockerfile,
                "tag": tag,
                "rm": rm,
                "nocache": nocache,
                "platform": platform,
            }
            if buildargs:
                build_params["buildargs"] = buildargs

            image, build_logs = self.client.images.build(**build_params)
            
            logs = []
            for log in build_logs:
                if isinstance(log, dict):
                    if "stream" in log:
                        logs.append(log["stream"].strip())
                    elif "error" in log:
                        self._output_error(f"Build failed: {log['error']}")
                        return

            self._output_success({
                "image_id": image.id,
                "tags": image.tags,
                "platform": platform,
                "logs": logs
            })
        except Exception as e:
            self._output_error(f"Failed to build image: {str(e)}")

    def run_container(self, image: str, name: Optional[str] = None, 
                     detach: bool = True, ports: Optional[Dict[str, int]] = None,
                     environment: Optional[Dict[str, str]] = None,
                     volumes: Optional[Dict[str, Dict[str, str]]] = None,
                     command: Optional[List[str]] = None,
                     auto_remove: bool = True, network: str = "none",
                     mem_limit: str = "20m", mem_swap_limit: str = "20m",
                     cpu_quota: Optional[int] = None, cpus: float = 0.5,
                     storage_opt: Optional[Dict[str, str]] = None) -> None:
        """Run a container from an image.
        
        Args:
            image: Image name or ID
            name: Container name
            detach: Run in background (default: True)
            ports: Port mappings {container_port: host_port}
            environment: Environment variables {key: value}
            volumes: Volume mounts {host_path: {"bind": container_path, "mode": "rw"}}
            command: Command to run in container
            auto_remove: Automatically remove container when it exits (default: True)
            network: Network mode (default: "none")
            mem_limit: Memory limit (default: "20m")
            mem_swap_limit: Memory swap limit (default: "20m")
            cpu_quota: CPU quota in microseconds
            cpus: Number of CPUs (default: 0.5)
            storage_opt: Storage driver options
        """
        try:
            # Check if image exists
            if not self.image_exists(image):
                self._output_error(f"Image '{image}' does not exist. Pull or build it first.")
                return

            # Check if container name already exists
            if name and self.container_exists(name):
                self._output_error(f"Container '{name}' already exists. Remove it first or use a different name.")
                return

            run_params = {
                "image": image,
                "detach": detach,
                "auto_remove": auto_remove,
                "mem_limit": mem_limit,
                "mem_swappiness": 0,
                "network_mode": network,
            }

            # Add resource limits
            if mem_swap_limit:
                run_params["memswap_limit"] = mem_swap_limit
            if cpus:
                run_params["nano_cpus"] = int(cpus * 1e9)
            if storage_opt:
                run_params["storage_opt"] = storage_opt

            if name:
                run_params["name"] = name
            if ports:
                run_params["ports"] = ports
            if environment:
                run_params["environment"] = environment
            if volumes:
                run_params["volumes"] = volumes
            if command:
                run_params["command"] = command

            container = self.client.containers.run(**run_params)
            
            self._output_success({
                "container_id": container.id,
                "name": container.name,
                "status": container.status,
                "image": container.image.tags if container.image else image,
                "auto_remove": auto_remove,
            })
        except Exception as e:
            self._output_error(f"Failed to run container: {str(e)}")

    def kill_container(self, container_id: str, signal: str = "SIGKILL") -> None:
        """Kill a running container."""
        try:
            if not self.container_exists(container_id):
                self._output_error(f"Container '{container_id}' does not exist.")
                return

            container = self.client.containers.get(container_id)
            container.kill(signal=signal)
            self._output_success({
                "container_id": container_id,
                "message": f"Container killed with signal {signal}"
            })
        except Exception as e:
            self._output_error(f"Failed to kill container: {str(e)}")

    def delete_container(self, container_id: str, force: bool = False) -> None:
        """Delete a container."""
        try:
            if not self.container_exists(container_id):
                self._output_error(f"Container '{container_id}' does not exist.")
                return

            container = self.client.containers.get(container_id)
            container.remove(force=force)
            self._output_success({
                "container_id": container_id,
                "message": "Container deleted successfully"
            })
        except Exception as e:
            self._output_error(f"Failed to delete container: {str(e)}")

    def list_containers(self, all_containers: bool = False) -> None:
        """List containers."""
        try:
            containers = self.client.containers.list(all=all_containers)
            containers_data = []
            for container in containers:
                containers_data.append({
                    "id": container.id,
                    "name": container.name,
                    "status": container.status,
                    "image": container.image.tags if container.image else "unknown",
                    "created": container.attrs.get("Created", ""),
                })
            self._output_success(containers_data)
        except Exception as e:
            self._output_error(f"Failed to list containers: {str(e)}")

    def delete_image(self, image_tag: str, force: bool = True) -> None:
        """Delete an image."""
        try:
            if not self.image_exists(image_tag):
                self._output_error(f"Image '{image_tag}' does not exist.")
                return

            self.client.images.remove(image_tag, force=force)
            self._output_success({
                "image": image_tag,
                "message": "Image deleted successfully"
            })
        except Exception as e:
            self._output_error(f"Failed to delete image: {str(e)}")

    def prune_images(self) -> None:
        """Remove unused images."""
        try:
            result = self.client.images.prune()
            self._output_success({
                "images_deleted": result.get("ImagesDeleted", []),
                "space_reclaimed": result.get("SpaceReclaimed", 0),
                "message": "Images pruned successfully"
            })
        except Exception as e:
            self._output_error(f"Failed to prune images: {str(e)}")


def main():
    parser = argparse.ArgumentParser(
        description="Podman API CLI - Manage containers and images via Podman socket"
    )
    parser.add_argument(
        "--socket",
        type=str,
        default="/run/podman/podman.sock",
        help="Path to Podman socket (default: /run/podman/podman.sock)"
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    images_parser = subparsers.add_parser("images", help="List images")
    images_parser.add_argument(
        "--all", "-a",
        action="store_true",
        help="Show all images (including intermediate)"
    )

    build_parser = subparsers.add_parser("build", help="Build an image")
    build_parser.add_argument(
        "context",
        type=str,
        help="Build context path"
    )
    build_parser.add_argument(
        "--tag", "-t",
        type=str,
        help="Image tag (e.g., myapp:latest)"
    )
    build_parser.add_argument(
        "--file", "-f",
        type=str,
        default="Dockerfile",
        help="Dockerfile name (default: Dockerfile)"
    )
    build_parser.add_argument(
        "--build-arg",
        action="append",
        help="Build arguments (format: KEY=VALUE)"
    )
    build_parser.add_argument(
        "--platform",
        type=str,
        help="Target platform (e.g., linux/amd64, linux/arm64)"
    )
    build_parser.add_argument(
        "--no-cache",
        action="store_true",
        help="Do not use cache when building"
    )
    build_parser.add_argument(
        "--force",
        action="store_true",
        help="Force rebuild even if image exists"
    )

    run_parser = subparsers.add_parser("run", help="Run a container")
    run_parser.add_argument(
        "image",
        type=str,
        help="Image name or ID"
    )
    run_parser.add_argument(
        "--name",
        type=str,
        help="Container name"
    )
    run_parser.add_argument(
        "--detach","-d",
        type=bool,
        default=True,
        help="Run container in background (default: true)"
    )
    run_parser.add_argument(
        "--port", "-p",
        action="append",
        help="Port mapping (format: HOST:CONTAINER)"
    )
    run_parser.add_argument(
        "--env", "-e",
        action="append",
        help="Environment variables (format: KEY=VALUE)"
    )
    run_parser.add_argument(
        "--volume", "-v",
        action="append",
        help="Volume mapping (format: HOST:CONTAINER)"
    )
    run_parser.add_argument(
        "--run-command","-c",
        nargs="*",
        help="Command to run in container"
    )
    run_parser.add_argument(
        "--no-auto-remove",
        action="store_true",
        help="Do not automatically remove container after exit (default: auto-remove enabled)"
    )
    run_parser.add_argument(
        "--network",
        type=str,
        default="none",
        help="Network mode (default: none)"
    )
    run_parser.add_argument(
        "--memory",
        type=str,
        default="20m",
        help="Memory limit (default: 20m)"
    )
    run_parser.add_argument(
        "--memory-swap",
        type=str,
        default="20m",
        help="Memory swap limit (default: 20m)"
    )
    run_parser.add_argument(
        "--cpus",
        type=float,
        default=0.5,
        help="Number of CPUs (default: 0.5)"
    )

    kill_parser = subparsers.add_parser("kill", help="Kill a running container")
    kill_parser.add_argument(
        "container_id",
        type=str,
        help="Container ID or name"
    )
    kill_parser.add_argument(
        "--signal", "-s",
        type=str,
        default="SIGKILL",
        help="Signal to send (default: SIGKILL)"
    )

    rm_parser = subparsers.add_parser("rm", help="Delete a container")
    rm_parser.add_argument(
        "container_id",
        type=str,
        help="Container ID or name"
    )
    rm_parser.add_argument(
        "--force", "-f",
        action="store_true",
        help="Force delete (stop if running)"
    )

    rmi_parser = subparsers.add_parser("rmi", help="Delete an image")
    rmi_parser.add_argument(
        "image_tag",
        type=str,
        help="Image tag or ID"
    )
    rmi_parser.add_argument(
        "--force", "-f",
        action="store_true",
        default=True,
        help="Force delete (default: true)"
    )

    prune_parser = subparsers.add_parser("prune", help="Remove unused images")

    ps_parser = subparsers.add_parser("ps", help="List containers")
    ps_parser.add_argument(
        "--all", "-a",
        action="store_true",
        help="Show all containers (including stopped)"
    )

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    cli = PodmanCLI(args.socket)
    if not cli.connect():
        sys.exit(1)

    if args.command == "images":
        cli.list_images(all_images=args.all)
    elif args.command == "pull" : 
        cli.list_images
    elif args.command == "build":
        buildargs = None
        if args.build_arg:
            buildargs = {}
            for arg in args.build_arg:
                key, value = arg.split("=", 1)
                buildargs[key] = value
        
        # Handle force flag - if set, remove existing image first
        if args.force and args.tag and cli.image_exists(args.tag):
            cli.delete_image(args.tag, force=True)
        
        cli.build_image(
            context_path=args.context,
            tag=args.tag,
            dockerfile=args.file,
            buildargs=buildargs,
            platform=args.platform,
            nocache=args.no_cache
        )
    
    elif args.command == "run":
        ports = None
        if args.port:
            ports = {}
            for port in args.port:
                host, container = port.split(":")
                ports[container] = int(host)
        
        environment = None
        if args.env:
            environment = {}
            for env in args.env:
                key, value = env.split("=", 1)
                environment[key] = value
        
        volumes = None
        if args.volume:
            volumes = {}
            for vol in args.volume:
                host, container = vol.split(":")
                volumes[host] = {"bind": container, "mode": "rw"}
        detach = True
        if args.detach == False or args.detach == "false":
            detach = False
        
        # auto_remove is True by default, unless --no-auto-remove is set
        auto_remove = not args.no_auto_remove
        
        run_command = None
        if args.run_command:
            if len(args.run_command) == 1:
                run_command = ["/bin/sh", "-c", args.run_command[0]]
            else:
                run_command = args.run_command
        
        cli.run_container(
            image=args.image,
            name=args.name,
            detach=detach,
            ports=ports,
            environment=environment,
            volumes=volumes,
            command=run_command,
            auto_remove=auto_remove,
            network=args.network,
            mem_limit=args.memory,
            mem_swap_limit=args.memory_swap,
            cpus=args.cpus
        )
    
    elif args.command == "kill":
        cli.kill_container(args.container_id, signal=args.signal)
    
    elif args.command == "rm":
        cli.delete_container(args.container_id, force=args.force)
    
    elif args.command == "rmi":
        cli.delete_image(args.image_tag, force=args.force)
    
    elif args.command == "prune":
        cli.prune_images()
    
    elif args.command == "ps":
        cli.list_containers(all_containers=args.all)


if __name__ == "__main__":
    main()