#!/usr/bin/env python3.14
import argparse
import json
import sys
import re
from pathlib import Path
from podman import PodmanClient
from podman.errors import ImageNotFound
from typing import Optional, Dict, Any, List


class PodmanCLI:
    def __init__(self, socket_path: str):
        self.socket_path = socket_path
        self.client = PodmanClient(base_url=f"http+unix://{self.socket_path}",version="6.0.0")

    def connect(self) -> bool:
        try:
            if(self.client.ping() != False) :
                self.client = PodmanClient(base_url=f"http+unix://{self.socket_path}",version="6.0.0")
                return True
            return False
        except Exception as e:
            self._output_error(f"Failed to connect to Podman socket: {e}")
            return False

    def _output_success(self, data: Any):
        print(json.dumps({"success": True, "data": data}))

    def _output_error(self, message: str):
        print(json.dumps({"success": False, "error": message}, indent=2), file=sys.stderr)
    def version(self):
        try:
            versionInfo = self.client.version()
            self._output_success(versionInfo.get('Version'))
        except Exception as e:
            self._output_error(f"Failed to get version: {str(e)}")
    def ping(self):
        try:
            self.client.ping()
            self._output_success("Pong")
        except Exception as e:
            self._output_error(f"Failed to ping: {str(e)}")
    
    def infoPodman(self,format:str|None) -> None:

        info = self.client.info()
        if format:
            # Use our dynamic formatter
            self._output_success(self.format_inspect(info, format))
        else:
            self._output_success(info)
    def image_exists(self, image_tag: str) -> bool:
        """Check if an image exists locally."""
        try:
            self.client.images.get(image_tag)
            self._output_success(True)
        except Exception:
            self._output_error("Image does not exist")
    def inspect_image(self,image_tag:str,format:str|None):
        try:
            imageInspect = self.client.images.get(image_tag)
            if format:
                # Use our dynamic formatter
                self._output_success(self.format_inspect(imageInspect.attrs, format))
            else:
                self._output_success(json.dumps(imageInspect.attrs, indent=4))
        except Exception as e:
            self._output_error(f"Failed to inspect image: {str(e)}")
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

    def _wait_for_container_exit(self, container, timeout: Optional[int], auto_remove: bool) -> bool:
        """Wait for container to exit with optional timeout.
        
        Args:
            container: Container object to wait for
            timeout: Timeout in seconds (None or 0 for no timeout)
            auto_remove: Whether to remove container on timeout
            
        Returns:
            True if container exited normally, False if timeout occurred
        """
        import time
        
        start_time = time.time()
        
        while True:
            container.reload()
            status = container.status
            print(f"Container '{container.name}' status: {status}")
            # Container has exited (could be 'exited', 'stopped', or 'dead')
            if status in ['exited', 'stopped', 'dead']:
                return True
            
            # Check if timeout exceeded
            if timeout and (time.time() - start_time) >= timeout:
                # Timeout exceeded - kill the container
                # container.stop()
                # try:
                #     container.kill()
                # except Exception as kill_error:
                #     print(f"Warning: Failed to kill container: {kill_error}")
                
                self._output_error(f"Container '{container.name}' exceeded timeout of {timeout}s and was killed")
                # if auto_remove:
                #     try:
                #         container.remove()
                #     except Exception:
                #         pass
                return False
            
            # Sleep briefly before checking again
            time.sleep(0.5)

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
            if self.client.images.exists(tag):
                self._output_success({"image": tag, "message": "Image already exists"})
                return



            build_params = {
                "path": context_path,
                "dockerfile": dockerfile,
                "tag": tag,
                "rm": rm,
                "nocache": nocache,
                
            }
            # Auto-detect platform if not provided
            if not platform:
                platform = self.get_arch_platform()
                build_params["platform"] = platform

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
        except ImageNotFound:
            self._output_error(f"Image '{tag}' not found. Please build the image first.")
        except Exception as e:
            self._output_error(f"Failed to build image: {str(e)}")

    def run_container(self, image: str, name: Optional[str] = None, 
                     detach: bool = False, ports: Optional[Dict[str, int]] = None,
                     environment: Optional[Dict[str, str]] = None,
                     volumes: Optional[Dict[str, Dict[str, str]]] = None,
                     command: Optional[List[str]] = None,
                     auto_remove: bool = True, network_mode: str = "none",
                     mem_limit: str = "20m", mem_swap_limit: str = "20m",
                     cpus: float = 0.5,
                     storage_opt: Optional[Dict[str, str]] = None,
                     timeout: Optional[int] = 5,
                     working_dir: Optional[str] = None,entrypoint: Optional[str] = None) -> None:
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
            timeout: Timeout in seconds (default: None)
            working_dir: Working directory inside the container
            entrypoint: Entrypoint to run in container
        """
        try:
            # Check if image exists
            # Check if image already exists
            imageContainer = self.client.images.get(image)
            
            # # Check if container name already exists
            # if name and self.container_exists(name):
            #     self._output_error(f"Container '{name}' already exists. Remove it first or use a different name.")
            #     return
            # print(f"run container from image {image} with name {name}")
            run_params = {
                # "image": image,
                "detach": detach,
                "user": "root:root",
                "auto_remove": False, #auto_remove,
                "mem_limit": mem_limit,
                "stderr": True,
                "stdout": True,
                "privileged": True,
                # "mem_swappiness": 0,
                "network_mode": network_mode,
            }

            if entrypoint:
                run_params["entrypoint"] = entrypoint


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
            if working_dir:
                run_params["working_dir"] = working_dir
            
            containerImage = self.client.containers.run(image=imageContainer, **run_params)
            containerImage.wait()
            # Wait for container to exit with timeout
            # self._wait_for_container_exit(containerImage, timeout, auto_remove)
            
            # Refresh container status after wait
            containerImage.reload()
            logs = []
            for log in containerImage.logs():
                logs.append(log.decode('utf-8'))
            containerImage.reload()
            # Check exit code for success/failure
            exit_code = containerImage.attrs.get('State', {}).get('ExitCode', -1)
            if containerImage.status == "exited" and exit_code == 0:
                self._output_success({
                    "container_id": containerImage.id,
                    "name": containerImage.name,
                    "status": containerImage.status,
                    "exit_code": exit_code,
                    "image": containerImage.image.tags if containerImage.image else image,
                    "auto_remove": auto_remove,
                    "logs": logs,
                })
                if auto_remove:
                    containerImage.remove()
                sys.exit(0)
            else:
                self._output_error(f"Container '{containerImage.name}' failed with exit code {exit_code},logs:{logs},error: {containerImage.attrs.get('State', {}).get('Error', '')}")
                if auto_remove:
                    containerImage.remove()
                sys.exit(1)
         
        except ImageNotFound:
            self._output_error(f"Image '{image}' does not exist. Pull or build it first.")
            sys.exit(1)
        except Exception as e:
            self._output_error(f"Failed to run container: {str(e)}")
            sys.exit(1)

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
    def get_nested_value(self,data, path):
        """Recursively finds values like 'Config.Cmd' in image attributes."""
        keys = path.strip('.').split('.')
        current = data
        for key in keys:
            if not isinstance(current, dict):
                return None
            
            # 1. Direct Match (Case-Sensitive)
            if key in current:
                current = current[key]
            else:
                # 2. Case-Insensitive Fallback (Crucial for Host vs host)
                mapping = {k.lower(): k for k in current.keys()}
                target_key = mapping.get(key.lower())
                
                if target_key:
                    current = current[target_key]
                else:
                    return None
                    
        return current

    def format_inspect(self,attrs, format_str):
        """Replaces {{.Path}} with values from the attributes dictionary."""
        # Find all Go-style placeholders {{.Something}}
        patterns = re.findall(r'\{\{\s*\.(.*?)\s*\}\}', format_str)
        
        output = format_str
        for p in patterns:
            value = self.get_nested_value(attrs, p)
            # Convert list/dict values to string for display (like CLI does)
            val_str = json.dumps(value) if isinstance(value, (list, dict)) else str(value)
            output = output.replace(f"{{{{.{p}}}}}", val_str)
        
        return output


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

    subparsers.add_parser("version", help="Get Podman version")
    subparsers.add_parser("ping", help="Ping Podman")
    existParser = subparsers.add_parser("exists", help="Check if an image exists")
    existParser.add_argument(
        "tag",
        type=str,
        help="Image tag (e.g., myapp:latest)"
    )
    info_parser = subparsers.add_parser("info", help="Get Podman info")
    info_parser.add_argument(
        "--format","-f",
        type=str,
        required=False,
        help="Format the output",
    )
    images_parser = subparsers.add_parser("images", help="List images")
    images_parser.add_argument(
        "--all", "-a",
        action="store_true",
        help="Show all images (including intermediate)"
    )
    inspect_image_parser = subparsers.add_parser("inspect", help="inspect an image")
    inspect_image_parser.add_argument(
        "tag",
        type=str,
        help="Image tag (e.g., myapp:latest)"
    )
    inspect_image_parser.add_argument(
        "--format",
        type=str,
        required=False,
        help="Format the output",
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
        "--entrypoint",
        type=str,
        help="Entrypoint to run in container"
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
    # run_parser.add_argument(
    #     "--run-command","-c",
    #     nargs="*",
    #     help="Command to run in container"
    # )
    run_parser.add_argument(
        "--no-auto-remove",
        action="store_true",
        help="Do not automatically remove container after exit (default: auto-remove enabled)"
    )
    run_parser.add_argument(
        "--network-mode",
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
    run_parser.add_argument(
        "--timeout",
        type=int,
        default=5,
        help="Timeout in seconds to wait for container to exit (default: 5)"
    )
    run_parser.add_argument(
        "--workdir", "-w",
        type=str,
        help="Working directory inside the container"
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

    subparsers.add_parser("prune", help="Remove unused images")

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
    if args.command == "version":
        cli.version()
    elif args.command == "ping":
        cli.ping()
    elif args.command == "info":
        cli.infoPodman(format=args.format)
    elif args.command == "images":
        cli.list_images(all_images=args.all)
    elif args.command == "exists":
        cli.image_exists(args.tag)
    elif args.command == "inspect":
        cli.inspect_image(image_tag=args.tag,format=args.format)
    # elif args.command == "pull" : 
    #     cli.pull(args.image)
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
                parts = vol.split(":")
                if len(parts) == 2:
                    host, container = parts
                    mode = "rw"
                elif len(parts) == 3:
                    host, container, mode = parts
                else:
                    raise ValueError(f"Invalid volume format: {vol}. Expected host:container or host:container:mode")
                volumes[host] = {"bind": container, "mode": mode}
        detach = False
        if args.detach == True or args.detach == "true":
            detach = True
        
        # auto_remove is True by default, unless --no-auto-remove is set
        auto_remove = not args.no_auto_remove
        
        # run_command = None
        # if args.run_command:
        #     if len(args.run_command) == 1:
        #         run_command = ["/bin/sh", "-c", args.run_command[0]]
        #     else:
        #         run_command = args.run_command

        cli.run_container(
            image=args.image,
            name=args.name,
            detach=detach,
            ports=ports,
            environment=environment,
            volumes=volumes,
            command=None,
            auto_remove=auto_remove,
            network_mode=args.network_mode,
            mem_limit=args.memory,
            mem_swap_limit=args.memory_swap,
            cpus=args.cpus,
            timeout=args.timeout,
            working_dir=args.workdir
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