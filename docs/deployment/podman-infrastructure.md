# Podman Infrastructure

## Overview

ContainerPub uses **Podman** as the container runtime instead of Docker. Podman is a daemonless, rootless container engine that provides better security while maintaining full Docker CLI compatibility.

## Why Podman?

### Security Advantages

1. **Daemonless Architecture**

   - No root daemon running in the background
   - No single point of failure
   - Reduced attack surface

2. **Rootless Containers**

   - Containers run as regular users by default
   - No privilege escalation required
   - Better process isolation

3. **User Namespace Separation**

   - Each container runs in its own user namespace
   - Enhanced security boundaries
   - Protection against container breakout

4. **No Daemon Socket**
   - No `/var/run/docker.sock` to secure
   - Eliminates daemon socket privilege escalation risks
   - Simpler security model

### Compatibility

Podman is **100% Docker CLI compatible**:

```bash
# Docker commands
docker build -t myimage .
docker run myimage
docker ps
docker rmi myimage

# Exact same commands with Podman
podman build -t myimage .
podman run myimage
podman ps
podman rmi myimage
```

### OCI Compliance

- Podman is fully OCI (Open Container Initiative) compliant
- Works with standard Docker images
- Compatible with Docker Hub and other registries
- Uses same Dockerfile format

## Installation

### macOS

```bash
brew install podman

# Initialize Podman machine (required on macOS)
podman machine init
podman machine start
```

### Linux

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y podman

# Fedora/RHEL
sudo dnf install -y podman

# Arch Linux
sudo pacman -S podman
```

### Verify Installation

```bash
podman --version
# Output: podman version 4.x.x

podman info
# Shows Podman configuration and status
```

## Configuration

### Environment Variables

Update your `.env` file with Podman-compatible settings:

```bash
# Container Runtime (Podman)
DOCKER_REGISTRY=localhost:5000
DOCKER_BASE_IMAGE=dart:stable

# Function Execution Limits
FUNCTION_TIMEOUT_SECONDS=5
FUNCTION_MAX_MEMORY_MB=128
FUNCTION_MAX_CONCURRENT=10
```

### Registry Setup

For local development, use Podman's built-in registry:

```bash
# Start a local registry
podman run -d -p 5000:5000 --name registry registry:2

# Or use Docker Hub
DOCKER_REGISTRY=docker.io/yourusername
```

## Usage in ContainerPub

### How It Works

The `DockerService` class uses Podman for all container operations:

```dart
// lib/services/docker_service.dart
class DockerService {
  // Uses 'podman' instead of 'docker'
  static const String _containerRuntime = 'podman';

  // Build image with Podman
  static Future<String> buildImage(String functionId, String functionDir) async {
    final buildProcess = await Process.start(
      _containerRuntime, // 'podman'
      ['build', '-t', imageTag, functionDir],
    );
  }

  // Run container with Podman
  static Future<Map<String, dynamic>> runContainer({...}) async {
    final runProcess = await Process.start(
      _containerRuntime, // 'podman'
      ['run', '--rm', '--name', containerName, imageTag],
    );
  }
}
```

### Deployment Flow

1. **Upload Function Archive**

   - Archive uploaded to S3
   - Extracted to local directory

2. **Build Container Image (Podman)**

   ```bash
   podman build -t dart-function-{id}-v{version}:latest /path/to/function
   ```

   - Rootless build (no root required)
   - OCI-compliant image
   - Cached layers for faster builds

3. **Execute Function (Podman)**
   ```bash
   podman run --rm \
     --name dart-function-{timestamp} \
     --memory 128m \
     --cpus 0.5 \
     --network none \
     -e FUNCTION_INPUT='{}' \
     dart-function-{id}-v{version}:latest
   ```
   - Rootless execution
   - Resource limits enforced
   - Network isolation
   - Auto-cleanup after execution

## Security Features

### Rootless Execution

Podman runs containers as the current user:

```bash
# Check container user
podman run --rm dart:stable whoami
# Output: your-username (not root!)

# Check process owner
ps aux | grep podman
# Shows processes owned by your user
```

### Resource Limits

Containers are restricted by:

```dart
// Memory limit
'--memory', '128m'

// CPU limit
'--cpus', '0.5'

// Network isolation
'--network', 'none'
```

### Namespace Isolation

Each container runs in isolated namespaces:

- **PID namespace**: Isolated process tree
- **Network namespace**: Isolated network stack
- **Mount namespace**: Isolated filesystem
- **User namespace**: Isolated user IDs

## Comparison: Docker vs Podman

| Feature                     | Docker                    | Podman                   |
| --------------------------- | ------------------------- | ------------------------ |
| **Architecture**            | Client-server (daemon)    | Daemonless               |
| **Root Required**           | Yes (daemon runs as root) | No (rootless by default) |
| **CLI Compatibility**       | N/A                       | 100% Docker-compatible   |
| **OCI Compliance**          | Yes                       | Yes                      |
| **Security**                | Good                      | Better (rootless)        |
| **Single Point of Failure** | Yes (daemon)              | No                       |
| **Systemd Integration**     | Limited                   | Native                   |
| **Pod Support**             | No                        | Yes (Kubernetes-like)    |

## Migration from Docker

### Zero Code Changes Required

The codebase is already Podman-ready! Simply:

1. Install Podman
2. Ensure `podman` command is available
3. Start the backend

The `DockerService` automatically uses Podman.

### Dockerfile Compatibility

All Dockerfiles work with Podman without modifications:

```dockerfile
FROM dart:stable
WORKDIR /app
COPY . .
RUN dart pub get
CMD ["dart", "run", "main.dart"]
```

This works identically with both Docker and Podman.

## Troubleshooting

### Podman Not Found

```bash
# Check if Podman is installed
which podman

# Install if missing (macOS)
brew install podman
podman machine init
podman machine start
```

### Permission Denied

```bash
# Podman should run rootless
# If you see permission errors, check:
podman system info | grep rootless
# Should show: rootless: true

# Reset Podman machine (macOS)
podman machine stop
podman machine rm
podman machine init
podman machine start
```

### Image Build Fails

```bash
# Check Podman status
podman info

# Verify base image is accessible
podman pull dart:stable

# Check build logs
podman build -t test-image . --log-level=debug
```

### Container Won't Start

```bash
# Check running containers
podman ps -a

# View container logs
podman logs <container-name>

# Inspect container
podman inspect <container-name>
```

### macOS-Specific Issues

```bash
# Podman machine not running
podman machine start

# Check machine status
podman machine list

# SSH into machine for debugging
podman machine ssh
```

## Performance

### Build Performance

Podman build performance is comparable to Docker:

- **Layer caching**: Same as Docker
- **Parallel builds**: Supported
- **Build time**: ~5-30 seconds per function

### Runtime Performance

Container execution overhead:

- **Startup time**: ~100-200ms
- **Memory overhead**: ~10-20MB
- **CPU overhead**: Negligible

### Resource Usage

Podman is more efficient than Docker:

- **No daemon**: Saves ~50-100MB RAM
- **Rootless**: Lower privilege overhead
- **Direct execution**: No daemon communication

## Best Practices

### 1. Use Rootless Mode

Always run Podman rootless (default):

```bash
# Verify rootless mode
podman system info | grep rootless
# Should show: rootless: true
```

### 2. Clean Up Old Images

Regularly remove unused images:

```bash
# Remove dangling images
podman image prune

# Remove all unused images
podman image prune -a

# Remove old function images
podman images | grep dart-function | awk '{print $3}' | xargs podman rmi
```

### 3. Monitor Resource Usage

Track container resource consumption:

```bash
# View running containers with stats
podman stats

# Check system resource usage
podman system df
```

### 4. Use Local Registry

For faster deployments, use a local registry:

```bash
# Start local registry
podman run -d -p 5000:5000 --name registry registry:2

# Configure in .env
DOCKER_REGISTRY=localhost:5000
```

### 5. Enable Auto-Updates

Keep Podman updated for security:

```bash
# macOS
brew upgrade podman

# Linux (Ubuntu/Debian)
sudo apt-get update && sudo apt-get upgrade podman
```

## Advanced Features

### Pods (Kubernetes-like)

Podman supports pods for multi-container deployments:

```bash
# Create a pod
podman pod create --name function-pod -p 8080:8080

# Run containers in pod
podman run -d --pod function-pod dart-function
podman run -d --pod function-pod redis
```

### Systemd Integration

Run containers as systemd services:

```bash
# Generate systemd unit file
podman generate systemd --name my-container > ~/.config/systemd/user/container.service

# Enable and start service
systemctl --user enable container.service
systemctl --user start container.service
```

### Remote Execution

Execute containers on remote Podman hosts:

```bash
# Set remote connection
podman system connection add remote ssh://user@host/run/podman/podman.sock

# Use remote connection
podman --remote run dart:stable
```

## Monitoring

### Container Logs

View container logs:

```bash
# Follow logs
podman logs -f <container-name>

# Last 100 lines
podman logs --tail 100 <container-name>

# Logs since timestamp
podman logs --since 2024-01-01T00:00:00 <container-name>
```

### Resource Monitoring

Monitor resource usage:

```bash
# Real-time stats
podman stats

# System resource usage
podman system df

# Detailed container info
podman inspect <container-name>
```

### Health Checks

Implement health checks in Dockerfiles:

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD dart run health_check.dart || exit 1
```

## Production Deployment

### Recommendations

1. **Use Podman 4.0+**: Latest features and security fixes
2. **Enable SELinux**: Additional security layer (Linux)
3. **Set Resource Limits**: Prevent resource exhaustion
4. **Monitor Logs**: Track container behavior
5. **Regular Updates**: Keep Podman updated
6. **Backup Images**: Store images in registry

### High Availability

For production, consider:

- **Load balancing**: Multiple backend instances
- **Image registry**: Centralized image storage
- **Monitoring**: Prometheus + Grafana
- **Logging**: Centralized log aggregation
- **Auto-scaling**: Scale based on load

## References

- [Podman Official Documentation](https://docs.podman.io/)
- [Podman vs Docker](https://docs.podman.io/en/latest/Introduction.html)
- [Rootless Containers](https://rootlesscontaine.rs/)
- [OCI Specification](https://opencontainers.org/)
