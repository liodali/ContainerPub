# Podman Compat API Documentation

This document describes the Docker-compatible (compat) API implementation for the Podman Dart client.

## Overview

The Podman compat API provides Docker-compatible endpoints that allow you to use Docker-style configurations and commands with Podman. This package supports both:

- **Compat API**: Docker-compatible endpoints (`/v4.0.0/containers/...`)
- **Libpod API**: Podman-native endpoints (`/v4.0.0/libpod/containers/...`)

## Container Configuration

### CompatContainerConfig

Docker-compatible container creation configuration that aligns with Docker's `CreateContainerConfig`.

```dart
final config = CompatContainerConfig(
  image: 'docker.io/library/alpine:latest',
  name: 'my-container',
  cmd: ['sleep', '3600'],
  hostname: 'my-host',
  env: ['VAR1=value1', 'VAR2=value2'],
  labels: {'app': 'myapp', 'env': 'production'},
  hostConfig: CompatHostConfig(
    autoRemove: true,
    memory: 536870912, // 512MB in bytes
    cpuShares: 512,
    binds: ['/host/path:/container/path:ro'],
    privileged: false,
    portBindings: {
      '80/tcp': [{'HostPort': '8080'}]
    },
  ),
);
```

### CompatHostConfig

Host-specific configuration (non-portable settings):

```dart
final hostConfig = CompatHostConfig(
  // Resource limits
  memory: 1073741824,           // 1GB
  memoryReservation: 536870912, // 512MB
  memorySwap: 2147483648,       // 2GB
  cpuShares: 1024,
  cpuPeriod: 100000,
  cpuQuota: 50000,
  cpusetCpus: '0-3',
  cpusetMems: '0',

  // Storage
  binds: ['/host/data:/container/data:rw'],
  volumesFrom: ['other-container'],

  // Network
  dns: ['8.8.8.8', '8.8.4.4'],
  dnsSearch: ['example.com'],
  extraHosts: ['host1:192.168.1.1'],
  portBindings: {
    '80/tcp': [{'HostPort': '8080', 'HostIp': '0.0.0.0'}],
    '443/tcp': [{'HostPort': '8443'}],
  },

  // Security
  privileged: false,
  capAdd: ['NET_ADMIN', 'SYS_TIME'],
  capDrop: ['MKNOD'],
  securityOpt: ['no-new-privileges'],

  // Behavior
  autoRemove: true,
  restartPolicy: {
    'Name': 'unless-stopped',
    'MaximumRetryCount': 3,
  },
);
```

## Container Operations

### ContainerOperations API

Access via `client.containerOps`:

```dart
final client = PodmanClient();
final ops = client.containerOps;
```

### Kill Container

Kill a single container or multiple containers with filters:

```dart
// Kill single container
await ops.killContainer(
  name: 'my-container',
  signal: 'SIGTERM', // or 'SIGKILL', 'SIGHUP', etc.
);

// Kill all containers matching filter
final killed = await ops.killContainersWithFilter(
  filters: {
    'label': ['app=myapp'],
    'status': ['running'],
  },
  signal: 'SIGTERM',
);
print('Killed: $killed');
```

### Pause/Unpause Container

```dart
// Pause single container
await ops.pauseContainer('my-container');

// Pause multiple containers with filter
final paused = await ops.pauseContainersWithFilter(
  filters: {
    'label': ['env=production'],
  },
);

// Unpause container
await ops.unpauseContainer('my-container');
```

### Restart Container

```dart
// Restart single container
await ops.restartContainer(
  name: 'my-container',
  timeout: 10, // seconds before force kill
);

// Restart multiple containers with filter
final restarted = await ops.restartContainersWithFilter(
  filters: {
    'status': ['paused', 'exited'],
  },
  timeout: 5,
);
```

### Stop Container

```dart
// Stop single container
await ops.stopContainer(
  name: 'my-container',
  timeout: 10, // seconds before force kill
);

// Stop multiple containers with filter
final stopped = await ops.stopContainersWithFilter(
  filters: {
    'label': ['app=myapp'],
  },
  timeout: 5,
);
```

### Wait for Container

Wait for a container to meet a specific condition:

```dart
final response = await ops.waitContainer(
  name: 'my-container',
  condition: 'stopped', // or 'running', 'paused', 'exited', etc.
  interval: '250ms',
);

// Response contains exit code and error (if any)
print(response.body);
```

### Check Container Exists (Libpod)

Quick check if a container exists:

```dart
final exists = await ops.containerExists('my-container');
if (exists) {
  print('Container exists');
} else {
  print('Container not found');
}
```

### List Containers

List containers with filters:

```dart
final response = await ops.listContainers(
  all: true, // include stopped containers
  filters: {
    'name': ['test-'],
    'status': ['running', 'paused'],
    'label': ['app=myapp', 'env=prod'],
    'ancestor': ['alpine:latest'],
  },
);

final containers = jsonDecode(response.body);
```

## Filters

Filters are JSON-encoded maps with string keys and list of string values:

```dart
final filters = {
  'label': ['key1=value1', 'key2=value2'],
  'name': ['prefix-'],
  'status': ['running', 'paused', 'exited'],
  'ancestor': ['alpine:latest'],
  'id': ['abc123'],
  'before': ['container-id'],
  'since': ['container-id'],
  'health': ['healthy', 'unhealthy', 'starting', 'none'],
};
```

## Available Conditions for Wait

- `configured` - Container is configured
- `created` - Container is created
- `exited` - Container has exited
- `paused` - Container is paused
- `running` - Container is running
- `stopped` - Container is stopped (default)

## Response Codes

### Success Codes

- `200` - OK (with body)
- `204` - No Content (success, no body)
- `304` - Not Modified (container already in desired state)

### Error Codes

- `400` - Bad Request
- `404` - Container Not Found
- `409` - Conflict
- `500` - Internal Server Error

## Complete Example

```dart
import 'package:podman_socket_dart_client/podman_socket_dart_client.dart';

void main() async {
  final client = PodmanClient();

  // Create container with compat API
  final config = CompatContainerConfig(
    image: 'alpine:latest',
    name: 'test-app',
    cmd: ['sh', '-c', 'while true; do echo hello; sleep 5; done'],
    labels: {'app': 'test', 'version': '1.0'},
    hostConfig: CompatHostConfig(
      autoRemove: true,
      memory: 536870912,
      restartPolicy: {'Name': 'unless-stopped'},
    ),
  );

  // Check if exists
  if (await client.containerOps.containerExists('test-app')) {
    print('Container already exists');

    // Restart it
    await client.containerOps.restartContainer(
      name: 'test-app',
      timeout: 5,
    );
  }

  // Pause all test containers
  final paused = await client.containerOps.pauseContainersWithFilter(
    filters: {'label': ['app=test']},
  );
  print('Paused: $paused');

  // Wait for specific condition
  await client.containerOps.waitContainer(
    name: 'test-app',
    condition: 'paused',
  );

  // Unpause
  await client.containerOps.unpauseContainer('test-app');

  // Stop with timeout
  await client.containerOps.stopContainer(
    name: 'test-app',
    timeout: 10,
  );
}
```

## Differences: Compat vs Libpod

### Compat API

- Docker-compatible endpoints
- Uses Docker-style configuration
- Path: `/v4.0.0/containers/...`
- Compatible with Docker clients

### Libpod API

- Podman-native endpoints
- Uses Podman-specific features
- Path: `/v4.0.0/libpod/containers/...`
- More Podman-specific functionality

Both APIs are supported by this client and can be used interchangeably based on your needs.
