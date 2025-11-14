---
title: Podman Migration
description: Understanding the Podman container runtime
---

# Podman Migration

ContainerPub uses **Podman** as its container runtime instead of Docker, providing enhanced security and better resource isolation.

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

## Usage in ContainerPub

### Building Functions
```dart
# Automatic - uses Podman internally
dart_cloud deploy ./my_function
```

### Manual Container Operations
```dart
# Build image
podman build -t my-function .

# Run container
podman run --rm my-function

# List images
podman images

# Remove image
podman rmi my-function
```

## Comparison: Docker vs Podman

| Feature | Docker | Podman |
|---------|--------|--------|
| **Architecture** | Client-server (daemon) | Daemonless |
| **Root Required** | Yes (daemon) | No (rootless) |
| **CLI Compatibility** | N/A | 100% Docker-compatible |
| **Security** | Good | Better (rootless) |
| **Resource Usage** | Higher (daemon) | Lower (no daemon) |
| **Single Point of Failure** | Yes (daemon) | No |
| **OCI Compliance** | Yes | Yes |

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

## Migration Impact

### Zero Breaking Changes
✅ No code changes required  
✅ Same API surface  
✅ Backward compatible  
✅ Dockerfiles work unchanged  
✅ Same deployment flow

### What Changed
- Container runtime: `docker` → `podman`
- Log messages: Updated to say "Podman"
- Documentation: Added Podman guides

### What Stayed the Same
- API methods and signatures
- Deployment workflow
- Dockerfile format
- Image building process
- Container execution

## Next Steps

- Read [Development Guide](/docs/development)
- Check [Architecture Overview](/docs/architecture)
- Explore [Best Practices](/docs/development/best-practices)
