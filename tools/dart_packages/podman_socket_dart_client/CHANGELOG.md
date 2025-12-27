## 1.1.0

### Added

- **Docker-compatible (compat) API support**
  - `CompatContainerConfig` - Docker-compatible container creation configuration
  - `CompatHostConfig` - Docker-compatible host configuration
  - `CompatHealthcheck` - Docker-compatible healthcheck configuration
  - `CompatNetworkingConfig` - Docker-compatible networking configuration
- **Container Operations API** (`ContainerOperations` class)
  - `killContainer()` - Kill a container with signal support
  - `killContainersWithFilter()` - Kill multiple containers using filters
  - `pauseContainer()` - Pause a container
  - `pauseContainersWithFilter()` - Pause multiple containers using filters
  - `unpauseContainer()` - Unpause a container
  - `restartContainer()` - Restart a container with timeout
  - `restartContainersWithFilter()` - Restart multiple containers using filters
  - `stopContainer()` - Stop a container with timeout
  - `stopContainersWithFilter()` - Stop multiple containers using filters
  - `waitContainer()` - Wait for container to meet a condition
  - `containerExists()` - Check if container exists (libpod API)
  - `listContainers()` - List containers with filters

### Changed

- Updated `PodmanSocketClient` to support both compat and libpod endpoints
- Added `containerOps` property to `PodmanClient` for accessing container operations
- Updated API path routing to handle both `/v4.0.0/containers/...` (compat) and `/v4.0.0/libpod/...` (libpod) endpoints

### Documentation

- Added `COMPAT_API.md` - Comprehensive compat API documentation
- Added `example/compat_api_example.dart` - Complete usage examples

## 1.0.0

- Initial version.
