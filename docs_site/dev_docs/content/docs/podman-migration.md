---
title: Podman Migration
description: Understanding the Podman container runtime and Python client
---

# Podman Migration

ContainerPub uses **Podman** as its container runtime instead of Docker, providing enhanced security and better resource isolation. The backend communicates with Podman through a **Python client** that uses the Podman API for reliable container operations.

## Why Podman?

### Security Advantages

**Daemonless Architecture**

- No root daemon running in background
- No single point of failure
- Reduced attack surface

**Rootless Containers**

- Containers run as regular users
- No privilege escalation
- Better process isolation

**User Namespace Separation**

- Each container in own namespace
- Enhanced security boundaries
- Protection against breakout

### Compatibility

- **100% Docker CLI compatible** - Same commands work
- **OCI-compliant** - Works with Docker images
- **Same Dockerfile format** - No changes needed
- **Works with Docker Hub** - Access to all images

### Performance

- **No daemon overhead** - Saves 50-100MB RAM
- **Direct execution** - No daemon communication
- **Same build performance** - Layer caching works identically
- **Lower privilege overhead** - Rootless execution

## Installation

### macOS

```dart
brew install podman
podman machine init
podman machine start
```

### Linux

```dart
# Ubuntu/Debian
sudo apt-get install -y podman

# Fedora/RHEL
sudo dnf install -y podman
```

### Verify Installation

```dart
podman --version
podman info
```

## Architecture

### Python Podman Client

ContainerPub uses a **Python-based Podman client** (`podman_client.py`) that communicates with the Podman API via Unix socket:

**Location:** `tools/podman_client/podman_client.py`

**Key Features:**

- JSON-based communication with Dart backend
- Direct Podman API access via Python SDK
- Structured error handling
- Support for all container operations

**Communication Flow:**

```
Dart Backend → PodmanPyRuntime → Python Script → Podman API → Container
```

### PodmanPyRuntime

**Location:** `dart_cloud_backend/lib/services/docker/podman_py_runtime.dart`

The `PodmanPyRuntime` class implements the `ContainerRuntime` interface and manages Python client execution:

**Features:**

- Executes Python client with JSON responses
- Configurable socket path via `--dart-define=PODMAN_SOCKET_PATH`
- Timeout handling for container operations
- Structured error parsing

**Socket Configuration:**

```dart
// Default socket path
/run/podman/podman.sock

// Custom socket via environment
--dart-define=PODMAN_SOCKET_PATH=/custom/path/podman.sock
```

## Usage in ContainerPub

### Building Functions

```bash
# Automatic - uses Podman internally via Python client
dart_cloud deploy ./my_function
```

### Python Client Operations

The Python client supports all Podman operations:

```bash
# Build image
python3 podman_client.py --socket /run/podman/podman.sock build . --tag my-function

# Run container
python3 podman_client.py --socket /run/podman/podman.sock run my-function --name test

# List images
python3 podman_client.py --socket /run/podman/podman.sock images

# Remove image
python3 podman_client.py --socket /run/podman/podman.sock rmi my-function

# Check version
python3 podman_client.py --socket /run/podman/podman.sock version
```

### Manual Container Operations

```bash
# Build image
podman build -t my-function .

# Run container
podman run --rm my-function

# List images
podman images

# Remove image
podman rmi my-function
```

## Python Client API

### Supported Commands

| Command   | Description           | Example                                          |
| --------- | --------------------- | ------------------------------------------------ |
| `version` | Get Podman version    | `python3 podman_client.py version`               |
| `ping`    | Test connection       | `python3 podman_client.py ping`                  |
| `info`    | Get system info       | `python3 podman_client.py info`                  |
| `build`   | Build image           | `python3 podman_client.py build . --tag myapp`   |
| `run`     | Run container         | `python3 podman_client.py run myapp --name test` |
| `images`  | List images           | `python3 podman_client.py images`                |
| `ps`      | List containers       | `python3 podman_client.py ps --all`              |
| `rmi`     | Remove image          | `python3 podman_client.py rmi myapp`             |
| `kill`    | Kill container        | `python3 podman_client.py kill test`             |
| `prune`   | Remove unused images  | `python3 podman_client.py prune`                 |
| `exists`  | Check if image exists | `python3 podman_client.py exists myapp`          |
| `inspect` | Inspect image         | `python3 podman_client.py inspect myapp`         |

### JSON Response Format

**Success Response:**

```json
{
  "success": true,
  "data": {
    "container_id": "abc123",
    "status": "exited",
    "stdout": {...}
  }
}
```

**Error Response:**

```json
{
  "success": false,
  "error": "Container execution failed",
  "exit_code": 1
}
```

## Comparison: Docker vs Podman

| Feature                     | Docker                 | Podman                 | Podman + Python Client |
| --------------------------- | ---------------------- | ---------------------- | ---------------------- |
| **Architecture**            | Client-server (daemon) | Daemonless             | Daemonless + API       |
| **Root Required**           | Yes (daemon)           | No (rootless)          | No (rootless)          |
| **CLI Compatibility**       | N/A                    | 100% Docker-compatible | Python SDK             |
| **Security**                | Good                   | Better (rootless)      | Better (rootless)      |
| **Resource Usage**          | Higher (daemon)        | Lower (no daemon)      | Lower (no daemon)      |
| **Single Point of Failure** | Yes (daemon)           | No                     | No                     |
| **OCI Compliance**          | Yes                    | Yes                    | Yes                    |
| **API Access**              | REST API               | REST API               | Python SDK             |

## Benefits for ContainerPub

### For Developers

- **Better security** - Rootless containers
- **Easier debugging** - No daemon to manage
- **Faster startup** - No daemon overhead
- **Same workflow** - Docker commands work

### For Operations

- **Simpler deployment** - No daemon to configure
- **Better isolation** - User namespaces
- **Lower resource usage** - No daemon overhead
- **Easier monitoring** - Direct process execution

### For Security

- **No root daemon** - Reduced attack surface
- **Rootless execution** - No privilege escalation
- **Namespace isolation** - Better boundaries
- **No socket exposure** - Simpler security model

## Troubleshooting

### Podman Not Found

```dart
# Install Podman
brew install podman  # macOS
sudo apt-get install podman  # Linux

# Initialize (macOS only)
podman machine init
podman machine start
```

### Permission Denied

```dart
# Verify rootless mode
podman system info | grep rootless
# Should show: rootless: true

# Reset if needed (macOS)
podman machine stop
podman machine rm
podman machine init
podman machine start
```

### Build Fails

```dart
# Check Podman status
podman info

# Test base image
podman pull dart:stable

# Check build logs
podman build -t test . --log-level=debug
```

## Python Client Implementation

### Dependencies

**Python Requirements:**

```python
podman>=5.0.0  # Podman Python SDK
```

**Installation:**

```bash
pip3 install podman
```

### Key Features

**1. Mount Support**

- Volume mounts: `--volume host:container:mode`
- Bind mounts: `--mount source:target:relabel,propagation`
- Shared volumes for function data

**2. Resource Limits**

- Memory limits: `--memory 20m`
- Memory swap: `--memory-swap 50m`
- CPU limits: `--cpus 0.5`

**3. Network Isolation**

- Default: `--network-mode none`
- Configurable network modes

**4. Timeout Handling**

- Container execution timeout
- Automatic cleanup on timeout
- Graceful error handling

## Migration Impact

### Zero Breaking Changes

✅ No code changes required  
✅ Same API surface  
✅ Backward compatible  
✅ Dockerfiles work unchanged  
✅ Same deployment flow

### What Changed

- Container runtime: `docker` → `podman` → `podman_py_runtime`
- Communication: Direct CLI → Python client → Podman API
- Log messages: Updated to say "PodmanPy"
- Documentation: Added Python client guides
- Socket configuration: Environment-based socket path

### What Stayed the Same

- API methods and signatures
- Deployment workflow
- Dockerfile format
- Image building process
- Container execution flow

## Configuration

### Socket Path Configuration

**Default Socket:**

```bash
/run/podman/podman.sock
```

**Custom Socket (via dart-define):**

```bash
dart run --dart-define=PODMAN_SOCKET_PATH=/custom/path/podman.sock bin/server.dart
```

**Environment Variable:**

```bash
export PODMAN_SOCKET_PATH=/custom/path/podman.sock
```

### Python Client Path

**Default Path:**

```
podman_client.py (relative to backend)
```

**Custom Path:**

```dart
final runtime = PodmanPyRuntime(
  pythonClientPath: '/path/to/podman_client.py',
);
```

## Troubleshooting

### Python Client Not Found

```bash
# Verify Python installation
python3 --version

# Install Podman SDK
pip3 install podman

# Test Python client
python3 podman_client.py --socket /run/podman/podman.sock ping
```

### Socket Connection Failed

```bash
# Check Podman socket
ls -la /run/podman/podman.sock

# Start Podman socket (if needed)
podman system service --time=0 unix:///run/podman/podman.sock

# Test connection
curl --unix-socket /run/podman/podman.sock http://localhost/v4.0.0/libpod/info
```

### JSON Parse Error

```bash
# Test Python client output
python3 podman_client.py --socket /run/podman/podman.sock version

# Should output valid JSON:
# {"success": true, "data": "5.0.0"}
```

## Next Steps

- Read [Function Execution](./backend/function-execution) for shared volume details
- Check [Architecture Overview](./backend/architecture) for system design
- Explore [Development Guide](./development)
