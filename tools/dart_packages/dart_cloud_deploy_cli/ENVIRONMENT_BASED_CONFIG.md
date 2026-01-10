# Environment-Based Configuration

## Overview

The deploy configuration has been redesigned to support environment-based settings. Each environment (local, staging, production) can have its own configuration for:

- **Container**: Runtime, compose file, services, network settings
- **Host**: SSH connection details for remote deployments
- **Environment File**: Path to environment-specific .env file
- **Ansible**: Playbooks and inventory for infrastructure automation

OpenBao and Registry configurations remain shared across all environments.

## Architecture

### Modular File Structure

The configuration system is split into small, focused files:

```
lib/src/models/
├── deploy_config.dart          # Main config with environment management
├── environment_config.dart     # Environment-specific settings
├── container_config.dart       # Container runtime configuration
├── host_config.dart           # SSH host configuration
├── ansible_config.dart        # Ansible playbook configuration
├── registry_config.dart       # Container registry configuration
└── openbao_config.dart        # OpenBao secret management (with TokenManagerConfig)
```

### Configuration Classes

#### `DeployConfig`

Main configuration class that holds:

- `name`: Project name
- `projectPath`: Path to project directory
- `openbao`: OpenBao configuration (shared)
- `registry`: Container registry configuration (shared)
- `local`: Local environment configuration
- `staging`: Staging environment configuration
- `production`: Production environment configuration

**Helper Methods:**

```dart
// Get environment-specific config
config.getEnvironmentConfig(Environment.local)

// Set active environment for backward compatibility
config.setCurrentEnvironment(Environment.staging)

// Access active environment properties
config.container  // Returns active environment's container config
config.host       // Returns active environment's host config
config.envFilePath // Returns active environment's env file path
config.ansible    // Returns active environment's ansible config
```

#### `EnvironmentConfig`

Environment-specific configuration containing:

- `environment`: Environment enum (local, staging, production)
- `container`: Container configuration
- `host`: SSH host configuration (optional)
- `envFilePath`: Path to .env file (optional)
- `ansible`: Ansible configuration (optional)

#### `ContainerConfig`

Container runtime settings:

- `runtime`: 'podman' or 'docker'
- `composeFile`: Path to docker-compose.yml
- `projectName`: Compose project name
- `networkName`: Network name
- `services`: Map of service names
- `rebuildStrategy`: 'all' or 'changed'

#### `HostConfig`

SSH connection details:

- `host`: Hostname or IP
- `port`: SSH port (default: 22)
- `user`: SSH username
- `sshKeyPath`: Path to SSH private key
- `password`: SSH password (optional)

#### `AnsibleConfig`

Ansible automation settings:

- `inventoryPath`: Path to inventory file
- `backendPlaybook`: Backend deployment playbook
- `databasePlaybook`: Database setup playbook
- `backupPlaybook`: Backup configuration playbook
- `extraVars`: Additional variables

#### `OpenBaoConfig`

Secret management (shared across environments):

- `address`: OpenBao server address
- `namespace`: OpenBao namespace
- `local`, `staging`, `production`: Environment-specific TokenManagerConfig

## Configuration File Format

### Environment-Based YAML

```yaml
name: dart_cloud_deploy
project_path: /path/to/project

# Shared configurations
openbao:
  address: http://localhost:8200
  namespace: admin
  local:
    token_manager: auth/approle/login
    policy: dart-cloud-local
    secret_path: secret/data/dart-cloud/local
    role_id: local-role-id
    role_name: dart-cloud-local

registry:
  url: ghcr.io
  username: myuser
  token_base64: base64_token

# Environment-specific configurations
local:
  container:
    runtime: podman
    compose_file: docker-compose.local.yml
    project_name: dart_cloud_local
    network_name: dart_cloud_local_network
    services:
      backend: dart_cloud_backend
      postgres: postgres
    rebuild_strategy: all
  env_file_path: .env.local

staging:
  container:
    runtime: podman
    compose_file: docker-compose.staging.yml
    project_name: dart_cloud_staging
    network_name: dart_cloud_staging_network
    services:
      backend: dart_cloud_backend
      postgres: postgres
    rebuild_strategy: changed
  host:
    host: staging.example.com
    port: 22
    user: deploy
    ssh_key_path: ~/.ssh/staging_key
  env_file_path: .env.staging
  ansible:
    inventory_path: ansible/inventory/staging.yml
    backend_playbook: ansible/playbooks/backend.yml
    database_playbook: ansible/playbooks/database.yml
    backup_playbook: ansible/playbooks/backup.yml
    extra_vars:
      environment: staging

production:
  container:
    runtime: docker
    compose_file: docker-compose.prod.yml
    project_name: dart_cloud_prod
    network_name: dart_cloud_prod_network
    services:
      backend: dart_cloud_backend
      postgres: postgres
      redis: redis
    rebuild_strategy: changed
  host:
    host: prod.example.com
    port: 22
    user: deploy
    ssh_key_path: ~/.ssh/prod_key
  env_file_path: .env.production
  ansible:
    inventory_path: ansible/inventory/production.yml
    backend_playbook: ansible/playbooks/backend.yml
    database_playbook: ansible/playbooks/database.yml
    backup_playbook: ansible/playbooks/backup.yml
    extra_vars:
      environment: production
      enable_monitoring: true
```

## Usage

### Loading Configuration

```dart
// Load from YAML file
final config = await DeployConfig.load('deploy.yaml');

// Access environment-specific config
final localEnv = config.local;
final stagingEnv = config.staging;
final prodEnv = config.production;

// Get config for specific environment
final envConfig = config.getEnvironmentConfig(Environment.staging);
```

### Backward Compatibility

For existing code that expects direct property access:

```dart
// Set active environment
config.setCurrentEnvironment(Environment.staging);

// Access properties from active environment
final container = config.container;  // Returns staging container config
final host = config.host;            // Returns staging host config
final envFile = config.envFilePath;  // Returns staging env file path
final ansible = config.ansible;      // Returns staging ansible config
```

### Environment Checks

```dart
if (config.hasEnvironment(Environment.production)) {
  // Production environment is configured
}

if (config.isLocal) {
  // Current environment is local
}
```

## Benefits

1. **Clear Separation**: Each environment has its own isolated configuration
2. **Modular Design**: Small, focused files are easier to maintain
3. **Type Safety**: Strong typing prevents configuration errors
4. **Flexibility**: Easy to add new environments or configuration options
5. **Backward Compatible**: Existing code continues to work with helper methods
6. **Shared Resources**: OpenBao and Registry configs shared across environments

## Migration from Old Format

Old format (single environment):

```yaml
name: dart_cloud
environment: staging
container:
  runtime: podman
  compose_file: docker-compose.yml
host:
  host: staging.example.com
```

New format (multi-environment):

```yaml
name: dart_cloud
staging:
  container:
    runtime: podman
    compose_file: docker-compose.yml
  host:
    host: staging.example.com
```

## Examples

See `example/deploy_environment_based.yaml` for a complete configuration example.
