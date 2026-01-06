---
title: Python Podman Client
description: Python-based Podman API client for container operations
---

# Python Podman Client

The Python Podman Client (`podman_client.py`) is a command-line tool that provides JSON-based communication between the Dart backend and Podman API.

## Overview

**Location:** `tools/podman_client/podman_client.py`

**Purpose:**

- Bridge between Dart backend and Podman API
- Structured JSON communication
- Direct Podman Python SDK usage
- Container lifecycle management

**Architecture:**

```
Dart Backend → PodmanPyRuntime → Python Client → Podman API → Containers
```

## Features

### 1. JSON Communication

All commands return structured JSON responses:

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

### 2. Socket-Based Connection

Connects to Podman via Unix socket:

```bash
--socket /run/podman/podman.sock
```

**Configurable via:**

- Command-line argument: `--socket /path/to/socket`
- Environment variable: `PODMAN_SOCKET_PATH`
- Default: `/run/podman/podman.sock`

### 3. Container Operations

Full container lifecycle management:

- Build images
- Run containers
- Kill containers
- Remove containers
- List containers
- Inspect containers

### 4. Image Management

Complete image operations:

- Build images
- Remove images
- List images
- Inspect images
- Check existence
- Prune unused images

## Command Reference

### System Commands

#### version

Get Podman version information.

```bash
python3 podman_client.py --socket /run/podman/podman.sock version
```

**Response:**

```json
{
  "success": true,
  "data": "5.0.0"
}
```

#### ping

Test connection to Podman API.

```bash
python3 podman_client.py --socket /run/podman/podman.sock ping
```

**Response:**

```json
{
  "success": true,
  "data": "Pong"
}
```

#### info

Get system information.

```bash
python3 podman_client.py --socket /run/podman/podman.sock info
```

**With format:**

```bash
python3 podman_client.py --socket /run/podman/podman.sock info --format "{{.Host.Arch}}"
```

### Image Commands

#### build

Build a container image from Dockerfile.

```bash
python3 podman_client.py --socket /run/podman/podman.sock build . \
  --tag myapp:latest \
  --file Dockerfile \
  --platform linux/amd64
```

**Options:**

- `--tag, -t`: Image tag (e.g., myapp:latest)
- `--file, -f`: Dockerfile name (default: Dockerfile)
- `--build-arg`: Build arguments (format: KEY=VALUE)
- `--platform`: Target platform (e.g., linux/amd64, linux/arm64)
- `--no-cache`: Do not use cache when building
- `--force`: Force rebuild even if image exists

**Response:**

```json
{
  "success": true,
  "data": {
    "image_id": "sha256:abc123...",
    "tags": ["myapp:latest"],
    "platform": "linux/amd64",
    "logs": ["Step 1/5 : FROM dart:stable", ...]
  }
}
```

#### images

List all images.

```bash
python3 podman_client.py --socket /run/podman/podman.sock images
```

**With all images:**

```bash
python3 podman_client.py --socket /run/podman/podman.sock images --all
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": "sha256:abc123...",
      "tags": ["myapp:latest"],
      "size": 1234567890,
      "created": "2024-01-06T00:00:00Z",
      "digest": "sha256:def456..."
    }
  ]
}
```

#### exists

Check if an image exists.

```bash
python3 podman_client.py --socket /run/podman/podman.sock exists myapp:latest
```

**Response:**

```json
{
  "success": true,
  "data": true
}
```

#### inspect

Inspect an image.

```bash
python3 podman_client.py --socket /run/podman/podman.sock inspect myapp:latest
```

**With format:**

```bash
python3 podman_client.py --socket /run/podman/podman.sock inspect myapp:latest \
  --format "{{.Size}}"
```

**Response:**

```json
{
  "success": true,
  "data": {
    "Id": "sha256:abc123...",
    "Size": 1234567890,
    "Architecture": "amd64",
    "Os": "linux"
  }
}
```

#### rmi

Remove an image.

```bash
python3 podman_client.py --socket /run/podman/podman.sock rmi myapp:latest
```

**With force:**

```bash
python3 podman_client.py --socket /run/podman/podman.sock rmi myapp:latest --force
```

**Response:**

```json
{
  "success": true,
  "data": {
    "image": "myapp:latest",
    "message": "Image deleted successfully"
  }
}
```

#### prune

Remove unused images.

```bash
python3 podman_client.py --socket /run/podman/podman.sock prune
```

**Response:**

```json
{
  "success": true,
  "data": {
    "images_deleted": ["sha256:abc123..."],
    "space_reclaimed": 1234567890,
    "message": "Images pruned successfully"
  }
}
```

### Container Commands

#### run

Run a container from an image.

```bash
python3 podman_client.py --socket /run/podman/podman.sock run myapp:latest \
  --name mycontainer \
  --env KEY=VALUE \
  --mount /host/path:/container/path:Z,rshared \
  --memory 20m \
  --cpus 0.5 \
  --timeout 10
```

**Options:**

- `--name`: Container name
- `--entrypoint`: Entrypoint to run in container
- `--detach, -d`: Run container in background (default: true)
- `--port, -p`: Port mapping (format: HOST:CONTAINER)
- `--env, -e`: Environment variables (format: KEY=VALUE)
- `--volume, -v`: Volume mapping (format: HOST:CONTAINER)
- `--mount, -m`: Mount mapping (format: source:target:relabel,propagation)
- `--run-command, -c`: Command to run in container
- `--no-auto-remove`: Do not automatically remove container after exit
- `--network-mode`: Network mode (default: none)
- `--memory`: Memory limit (default: 20m)
- `--memory-swap`: Memory swap limit (default: 20m)
- `--cpus`: Number of CPUs (default: 0.5)
- `--timeout`: Timeout in seconds (default: 5)
- `--workdir, -w`: Working directory inside the container

**Mount Format:**

```
source:target:relabel,propagation,size
```

- `source`: Host path
- `target`: Container path
- `relabel`: SELinux relabel (e.g., Z, z)
- `propagation`: Mount propagation (e.g., rshared, shared, private)
- `size`: Optional size limit

**Response:**

```json
{
  "success": true,
  "data": {
    "container_id": "abc123",
    "name": "mycontainer",
    "status": "exited",
    "exit_code": 0,
    "image": ["myapp:latest"],
    "auto_remove": true,
    "stdout": {
      "statusCode": 200,
      "body": { "result": "success" }
    }
  }
}
```

#### ps

List containers.

```bash
python3 podman_client.py --socket /run/podman/podman.sock ps
```

**With all containers:**

```bash
python3 podman_client.py --socket /run/podman/podman.sock ps --all
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": "abc123",
      "name": "mycontainer",
      "status": "exited",
      "image": ["myapp:latest"],
      "created": "2024-01-06T00:00:00Z"
    }
  ]
}
```

#### kill

Kill a running container.

```bash
python3 podman_client.py --socket /run/podman/podman.sock kill mycontainer
```

**With signal:**

```bash
python3 podman_client.py --socket /run/podman/podman.sock kill mycontainer --signal SIGTERM
```

**Response:**

```json
{
  "success": true,
  "data": {
    "container_id": "mycontainer",
    "message": "Container killed with signal SIGKILL"
  }
}
```

#### rm

Remove a container.

```bash
python3 podman_client.py --socket /run/podman/podman.sock rm mycontainer
```

**With force:**

```bash
python3 podman_client.py --socket /run/podman/podman.sock rm mycontainer --force
```

**Response:**

```json
{
  "success": true,
  "data": {
    "container_id": "mycontainer",
    "message": "Container deleted successfully"
  }
}
```

## Implementation Details

### PodmanCLI Class

**Location:** `tools/podman_client/podman_client.py`

**Key Methods:**

```python
class PodmanCLI:
    def __init__(self, socket_path: str):
        """Initialize with Podman socket path"""

    def connect(self) -> bool:
        """Connect to Podman API"""

    def build_image(self, context_path: str, tag: str, ...):
        """Build container image"""

    def run_container(self, image: str, name: str, ...):
        """Run container with options"""

    def kill_container(self, container_id: str, signal: str):
        """Kill running container"""

    def delete_container(self, container_id: str, force: bool):
        """Delete container"""

    def delete_image(self, image_tag: str, force: bool):
        """Delete image"""
```

### Response Formatting

**Success Output:**

```python
def _output_success(self, data: Any):
    print(json.dumps({"success": True, "data": data}))
```

**Error Output:**

```python
def _output_error(self, message: str):
    print(json.dumps({"success": False, "error": message}), file=sys.stderr)
```

### Format String Support

Supports Go-style template formatting:

```python
def format_inspect(self, attrs, format_str):
    """Replaces {{.Path}} with values from attributes"""
    patterns = re.findall(r'\{\{\s*\.(.*?)\s*\}\}', format_str)
    # ... replace patterns with actual values
```

**Example:**

```bash
python3 podman_client.py inspect myapp --format "{{.Size}}"
# Output: {"success": true, "data": "1234567890"}
```

## Integration with Dart Backend

### PodmanPyRuntime

**Location:** `dart_cloud_backend/lib/services/docker/podman_py_runtime.dart`

**Execution Flow:**

```dart
Future<Map<String, dynamic>> _executePythonCommand(
  List<String> args, {
  Duration? timeout,
}) async {
  final fullArgs = [
    _pythonClientPath,
    '--socket',
    _socketPath,
    ...args,
  ];

  final process = await Process.start(_pythonExecutable, fullArgs);

  // Capture stdout/stderr
  // Parse JSON response
  // Handle timeout
  // Return structured result
}
```

### Example Usage

**Build Image:**

```dart
final result = await _executePythonCommand([
  'build',
  contextDir,
  '--tag',
  imageTag,
  '--file',
  dockerfilePath,
]);

if (result['success'] == true) {
  final data = result['data'] as Map<String, dynamic>;
  final logs = data['logs'] as List<dynamic>? ?? [];
  // Process build logs
}
```

**Run Container:**

```dart
final result = await _executePythonCommand([
  'run',
  imageTag,
  '--name',
  containerName,
  '--mount',
  'functions_data:/app/functions:Z,rshared',
  '--memory',
  '20m',
  '--cpus',
  '0.5',
  '--timeout',
  timeout.inSeconds.toString(),
]);

if (result['success'] == true) {
  final data = result['data'] as Map<String, dynamic>;
  final containerId = data['container_id'];
  final stdout = data['stdout'];
  // Process container output
}
```

## Configuration

### Socket Path

**Default:**

```bash
/run/podman/podman.sock
```

**Custom via Command Line:**

```bash
python3 podman_client.py --socket /custom/path/podman.sock <command>
```

**Custom via Environment:**

```bash
export PODMAN_SOCKET_PATH=/custom/path/podman.sock
```

### Python Executable

**Default:** `python3`

**Custom in PodmanPyRuntime:**

```dart
final runtime = PodmanPyRuntime(
  pythonExecutable: '/usr/bin/python3.11',
);
```

### Client Path

**Default:** `podman_client.py` (relative to backend)

**Custom in PodmanPyRuntime:**

```dart
final runtime = PodmanPyRuntime(
  pythonClientPath: '/path/to/podman_client.py',
);
```

## Dependencies

### Python Requirements

```python
podman>=5.0.0  # Podman Python SDK
```

**Installation:**

```bash
pip3 install podman
```

### System Requirements

- Python 3.x
- Podman installed and running
- Podman socket enabled

## Troubleshooting

### Connection Failed

**Error:**

```json
{
  "success": false,
  "error": "Failed to connect to Podman socket: ..."
}
```

**Solution:**

```bash
# Check socket exists
ls -la /run/podman/podman.sock

# Start Podman socket
podman system service --time=0 unix:///run/podman/podman.sock

# Test connection
python3 podman_client.py --socket /run/podman/podman.sock ping
```

### Python SDK Not Found

**Error:**

```
ModuleNotFoundError: No module named 'podman'
```

**Solution:**

```bash
# Install Podman SDK
pip3 install podman

# Verify installation
python3 -c "import podman; print(podman.__version__)"
```

### JSON Parse Error

**Error:**

```json
{
  "success": false,
  "error": "Failed to parse JSON response: ..."
}
```

**Solution:**

```bash
# Test Python client directly
python3 podman_client.py --socket /run/podman/podman.sock version

# Should output valid JSON
# {"success": true, "data": "5.0.0"}
```

### Timeout Issues

**Error:**

```json
{
  "success": false,
  "error": "Container 'name' exceeded timeout of 5s and was killed"
}
```

**Solution:**

```bash
# Increase timeout
python3 podman_client.py run myapp --timeout 30

# Or in Dart backend
final result = await _executePythonCommand(
  args,
  timeout: Duration(seconds: 30),
);
```

## Best Practices

### 1. Error Handling

Always check `success` field in response:

```python
result = json.loads(output)
if result['success']:
    data = result['data']
    # Process data
else:
    error = result['error']
    # Handle error
```

### 2. Timeout Configuration

Set appropriate timeouts for operations:

```bash
# Short timeout for quick operations
python3 podman_client.py run myapp --timeout 5

# Longer timeout for complex functions
python3 podman_client.py run myapp --timeout 30
```

### 3. Resource Limits

Always specify resource limits:

```bash
python3 podman_client.py run myapp \
  --memory 20m \
  --memory-swap 50m \
  --cpus 0.5
```

### 4. Mount Configuration

Use proper SELinux labels and propagation:

```bash
# SELinux label for container access
--mount /host/path:/container/path:Z,rshared

# Z = private label
# z = shared label
# rshared = recursive shared propagation
```

### 5. Network Isolation

Use network isolation for security:

```bash
python3 podman_client.py run myapp --network-mode none
```

## See Also

- [Podman Migration](../podman-migration.md) - Overview of Podman integration
- [Function Execution](./function-execution.md) - How functions are executed
- [Architecture Overview](./architecture.md) - System architecture
- [Development Guide](../development.md) - Development setup
