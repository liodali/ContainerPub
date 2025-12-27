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
    def pull(self,imageName:str)->None: 
        try:
            repository,tag = zip(imageName.split(':'))
            self.client.images.pull(repository,tag)
        except Exception as e:
            self._output_error(f"failed to pull image {str(e)}")
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
                   dockerfile: str = "Dockerfile", buildargs: Optional[Dict[str, str]] = None) -> None:
        try:
            build_params = {
                "path": context_path,
                "dockerfile": dockerfile,
                "tag": tag,
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
                "logs": logs
            })
        except Exception as e:
            self._output_error(f"Failed to build image: {str(e)}")

    def run_container(self, image: str, name: Optional[str] = None, 
                     detach: bool = True, ports: Optional[Dict[str, int]] = None,
                     environment: Optional[Dict[str, str]] = None,
                     volumes: Optional[Dict[str, Dict[str, str]]] = None,
                     command: Optional[List[str]] = None) -> None:
        try:
            run_params = {
                "image": image,
                "detach": detach,
            }
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
            })
        except Exception as e:
            self._output_error(f"Failed to run container: {str(e)}")

    def delete_container(self, container_id: str, force: bool = False) -> None:
        try:
            container = self.client.containers.get(container_id)
            container.remove(force=force)
            self._output_success({
                "container_id": container_id,
                "message": "Container deleted successfully"
            })
        except Exception as e:
            self._output_error(f"Failed to delete container: {str(e)}")

    def list_containers(self, all_containers: bool = False) -> None:
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
        "--detach", "-d",
        action="store_true",
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
        "command",
        nargs="*",
        help="Command to run in container"
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
        cli.build_image(
            context_path=args.context,
            tag=args.tag,
            dockerfile=args.file,
            buildargs=buildargs
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
        
        cli.run_container(
            image=args.image,
            name=args.name,
            detach=args.detach,
            ports=ports,
            environment=environment,
            volumes=volumes,
            command=args.command if args.command else None
        )
    
    elif args.command == "rm":
        cli.delete_container(args.container_id, force=args.force)
    
    elif args.command == "ps":
        cli.list_containers(all_containers=args.all)


if __name__ == "__main__":
    main()