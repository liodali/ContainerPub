# Dart Cloud Deploy CLI

A robust deployment CLI for managing Dart Cloud Backend deployments with OpenBao secrets management and Ansible integration.

> **New to the CLI?** Check out the [QUICKSTART.md](QUICKSTART.md) guide for simple examples.
> **Configuration Details?** See [ENVIRONMENT_BASED_CONFIG.md](ENVIRONMENT_BASED_CONFIG.md) for the new environment-based architecture.

## Features

- **Environment-Based Configuration**: Separate configs for local, staging, and production environments
- **Modular Architecture**: Small, focused configuration files for container, host, ansible, and registry settings
- **Local Deployment**: Deploy locally using Podman/Docker without Ansible
- **Dev Deployment**: Deploy to remote VPS using Ansible playbooks
- **Secrets Management**: Fetch secrets from OpenBao and generate `.env` files
- **Container Registry**: Build and push container images to Gitea/GitHub registries
- **Configuration**: Support for YAML and TOML configuration files
- **Python Venv Management**: Auto-creates Python venv and installs Ansible
- **Dynamic Playbooks**: Generates playbooks on-demand with modern Ansible syntax (`ansible.builtin.*`)
- **Auto Cleanup**: Removes generated playbooks after deployment
- **Interactive Menus**: User-friendly prompts for service management
- **Health Checks**: Automatic service health verification after deployment
- **System Prune**: Clean up all deployment configurations and cached data
- **Env Conversion**: Convert .env files to JSON format for easier debugging

## Installation

### Quick Install (Recommended)

```bash
# Clone the repository
git clone https://github.com/liodali/ContainerPub.git
cd ContainerPub/tools/dart_packages/dart_cloud_deploy_cli

# Build and install
./scripts/build.sh
./scripts/install.sh
```

### Manual Installation

```bash
# From the package directory
dart pub get

# Activate globally
dart pub global activate --source path .
```

### Uninstall

```bash
./scripts/uninstall.sh
```

## Quick Start

For detailed examples and use cases, see [QUICKSTART.md](QUICKSTART.md).

### 1. Initialize Environment

```bash
# Initialize Python venv and install Ansible
dart_cloud_deploy init

# Custom venv path
dart_cloud_deploy init --venv-path /path/to/venv

# Force reinstall everything
dart_cloud_deploy init --force

# Skip Ansible collections installation
dart_cloud_deploy init --skip-collections
```

### 2. Initialize Configuration

```bash
# Create a YAML config for local development
dart_cloud_deploy config init -e local

# Create a YAML config for dev environment
dart_cloud_deploy config init -e dev -o deploy-dev.yaml

# Create a TOML config
dart_cloud_deploy config init -f toml -e production

# Validate configuration
dart_cloud_deploy config validate -c deploy.yaml
```

### 3. Fetch Secrets (Optional)

```bash
# Fetch secrets for local environment (default)
dart_cloud_deploy secrets fetch

# Fetch secrets for staging environment
dart_cloud_deploy secrets fetch -e staging

# Fetch secrets for production environment
dart_cloud_deploy secrets fetch -e production

# Fetch to custom output file
dart_cloud_deploy secrets fetch -o .env.local

# Override secret path
dart_cloud_deploy secrets fetch -p secret/data/myapp/prod

# Check OpenBao connection for specific environment
dart_cloud_deploy secrets check -e staging

# List available secrets
dart_cloud_deploy secrets list -p secret/metadata/myapp
```

### 4. Deploy Locally

```bash
# Deploy all services locally (Podman/Docker)
dart_cloud_deploy deploy-local

# Deploy with forced rebuild
dart_cloud_deploy deploy-local --force

# Deploy specific service only
dart_cloud_deploy deploy-local -s backend
dart_cloud_deploy deploy-local -s postgres

# Skip secrets fetch
dart_cloud_deploy deploy-local --skip-secrets

# Skip build (use existing images)
dart_cloud_deploy deploy-local --no-build
```

### 5. Deploy to Dev Server

```bash
# Deploy all components to dev server
dart_cloud_deploy deploy-dev

# Deploy only backend
dart_cloud_deploy deploy-dev -t backend

# Deploy only database
dart_cloud_deploy deploy-dev -t database

# Run backup
dart_cloud_deploy deploy-dev -t backup

# Dry run (preview without executing)
dart_cloud_deploy deploy-dev --dry-run

# Verbose Ansible output
dart_cloud_deploy deploy-dev -v

# Pass extra variables
dart_cloud_deploy deploy-dev -e app_version=1.2.0 -e debug=true

# Run specific Ansible tags
dart_cloud_deploy deploy-dev --tags setup,deploy

# Skip specific tags
dart_cloud_deploy deploy-dev --skip-tags cleanup
```

### 6. Build and Push Container Images

```bash
# Build and push to registry
dart_cloud_deploy build-push -i myapp/backend -t v1.0.0

# Build only (no push)
dart_cloud_deploy build-push -i myapp/backend --no-push

# Custom Dockerfile and build context
dart_cloud_deploy build-push -i myapp/backend -d Dockerfile.prod -c ./backend

# With build arguments
dart_cloud_deploy build-push -i myapp/backend --build-arg NODE_ENV=production --build-arg VERSION=1.0.0

# Verbose build output
dart_cloud_deploy build-push -i myapp/backend -v
```

### 7. System Management

```bash
# Convert .env to JSON for debugging
dart_cloud_deploy env-to-json -f .env.local

# Show current configuration
dart_cloud_deploy show

# Clean up all configurations and cached data
dart_cloud_deploy prune -y
```

## Configuration File (deploy.yaml)

The new environment-based configuration allows you to define separate settings for each environment (local, staging, production) in a single file.

```yaml
name: dart_cloud_backend
project_path: .

# Shared configurations across all environments
openbao:
  address: http://localhost:8200
  # Per-environment token managers and policies
  # token_manager is used to generate secret-id for AppRole login
  # It can be:
  #   - A file path containing base64-encoded token (e.g., ~/.openbao/token)
  #   - A direct base64-encoded token string
  local:
    token_manager: ~/.openbao/local_token
    policy: dart-cloud-local
    secret_path: secret/data/dart_cloud/local
    role_id: local-role-uuid
    role_name: stg-local
  staging:
    token_manager: ~/.openbao/staging_token
    policy: dart-cloud-staging
    secret_path: secret/data/dart_cloud/staging
    role_id: staging-role-uuid
    role_name: stg-staging
  production:
    token_manager: aHZzLnByb2R1Y3Rpb24tdG9rZW4=
    policy: dart-cloud-production
    secret_path: secret/data/dart_cloud/production
    role_id: production-role-uuid
    role_name: stg-production

registry:
  url: ghcr.io
  username: myuser
  token_base64: base64_encoded_token

# Local environment configuration
local:
  container:
    runtime: podman
    compose_file: docker-compose.local.yml
    project_name: dart_cloud_local
    network_name: dart_cloud_local_network
    services:
      backend: dart_cloud_backend
      postgres: dart_cloud_postgres
    rebuild_strategy: all
  env_file_path: .env.local

# Staging environment configuration
staging:
  container:
    runtime: podman
    compose_file: docker-compose.staging.yml
    project_name: dart_cloud_staging
    network_name: dart_cloud_staging_network
    services:
      backend: dart_cloud_backend
      postgres: dart_cloud_postgres
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
      app_dir: /opt/dart_cloud
      postgres_user: dart_cloud
      postgres_db: dart_cloud

# Production environment configuration
production:
  container:
    runtime: docker
    compose_file: docker-compose.prod.yml
    project_name: dart_cloud_prod
    network_name: dart_cloud_prod_network
    services:
      backend: dart_cloud_backend
      postgres: dart_cloud_postgres
      redis: dart_cloud_redis
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
      app_dir: /opt/dart_cloud
      postgres_user: dart_cloud
      postgres_db: dart_cloud
      enable_monitoring: true
      enable_alerting: true
```

### Configuration Structure

- **Global Settings**: `name`, `project_path`, `openbao`, `registry` (shared across all environments)
- **Environment-Specific**: `local`, `staging`, `production` (each with their own container, host, env_file_path, ansible)

See [ENVIRONMENT_BASED_CONFIG.md](ENVIRONMENT_BASED_CONFIG.md) for detailed documentation on the configuration system.

## Commands Reference

### `init` - Initialize Environment

Initializes Python virtual environment and installs Ansible with required collections.

| Option               | Short | Description                            | Default |
| -------------------- | ----- | -------------------------------------- | ------- |
| `--venv-path`        |       | Path for Python virtual environment    | `.venv` |
| `--force`            | `-f`  | Force reinstall even if already exists | `false` |
| `--skip-collections` |       | Skip installing Ansible collections    | `false` |

### `config` - Configuration Management

#### `config init` - Create Configuration

| Option          | Short | Description                                       | Default       |
| --------------- | ----- | ------------------------------------------------- | ------------- |
| `--format`      | `-f`  | Configuration file format (`yaml`, `toml`)        | `yaml`        |
| `--output`      | `-o`  | Output file path                                  | `deploy.yaml` |
| `--environment` | `-e`  | Target environment (`local`, `dev`, `production`) | `local`       |

#### `config validate` - Validate Configuration

| Option     | Short | Description             | Default       |
| ---------- | ----- | ----------------------- | ------------- |
| `--config` | `-c`  | Configuration file path | `deploy.yaml` |

#### `config set` - Set Configuration Value

| Option     | Short | Description                      | Default       |
| ---------- | ----- | -------------------------------- | ------------- |
| `--config` | `-c`  | Configuration file path          | `deploy.yaml` |
| `--key`    | `-k`  | Configuration key (dot notation) | required      |
| `--value`  | `-v`  | Configuration value              | required      |

### `deploy-local` - Local Deployment

Deploy locally using Podman/Docker without Ansible.

| Option           | Short | Description                                          | Default       |
| ---------------- | ----- | ---------------------------------------------------- | ------------- |
| `--config`       | `-c`  | Configuration file path                              | `deploy.yaml` |
| `--build`        | `-b`  | Force rebuild containers                             | `true`        |
| `--force`        | `-f`  | Force recreate containers                            | `false`       |
| `--skip-secrets` |       | Skip fetching secrets from OpenBao                   | `false`       |
| `--service`      | `-s`  | Deploy specific service only (`backend`, `postgres`) | all           |

### `deploy-dev` - Remote Deployment

Deploy to dev/production server using Ansible.

| Option           | Short | Description                                                | Default       |
| ---------------- | ----- | ---------------------------------------------------------- | ------------- |
| `--config`       | `-c`  | Configuration file path                                    | `deploy.yaml` |
| `--target`       | `-t`  | Deployment target (`all`, `backend`, `database`, `backup`) | `all`         |
| `--skip-secrets` |       | Skip fetching secrets from OpenBao                         | `false`       |
| `--verbose`      | `-v`  | Verbose Ansible output                                     | `false`       |
| `--dry-run`      |       | Show what would be done without executing                  | `false`       |
| `--tags`         |       | Ansible tags to run (multiple allowed)                     | none          |
| `--skip-tags`    |       | Ansible tags to skip (multiple allowed)                    | none          |
| `--extra-vars`   | `-e`  | Extra variables as `key=value` (multiple allowed)          | none          |

### `secrets` - Secrets Management

#### `secrets fetch` - Fetch Secrets

| Option     | Short | Description                                           | Default       |
| ---------- | ----- | ----------------------------------------------------- | ------------- |
| `--config` | `-c`  | Configuration file path                               | `deploy.yaml` |
| `--output` | `-o`  | Output .env file path                                 | from config   |
| `--path`   | `-p`  | Override secret path in OpenBao                       | from config   |
| `--env`    | `-e`  | Environment to use (`local`, `staging`, `production`) | `local`       |

#### `secrets list` - List Secrets

| Option     | Short | Description                                           | Default                      |
| ---------- | ----- | ----------------------------------------------------- | ---------------------------- |
| `--config` | `-c`  | Configuration file path                               | `deploy.yaml`                |
| `--path`   | `-p`  | Path to list secrets from                             | `secret/metadata/dart_cloud` |
| `--env`    | `-e`  | Environment to use (`local`, `staging`, `production`) | `local`                      |

#### `secrets check` - Check Connection

| Option     | Short | Description                                           | Default       |
| ---------- | ----- | ----------------------------------------------------- | ------------- |
| `--config` | `-c`  | Configuration file path                               | `deploy.yaml` |
| `--env`    | `-e`  | Environment to use (`local`, `staging`, `production`) | `local`       |

### `build-push` - Build and Push Container Images

Build container images and push to Gitea/GitHub registry.

| Option         | Short | Description                                       | Default       |
| -------------- | ----- | ------------------------------------------------- | ------------- |
| `--config`     | `-c`  | Configuration file path                           | `deploy.yaml` |
| `--image-name` | `-i`  | Image name (without registry URL)                 | required      |
| `--tag`        | `-t`  | Image tag                                         | `latest`      |
| `--dockerfile` | `-d`  | Path to Dockerfile                                | `Dockerfile`  |
| `--context`    |       | Build context path                                | `.`           |
| `--build-arg`  |       | Build arguments as `key=value` (multiple allowed) | none          |
| `--no-push`    |       | Build only, do not push to registry               | `false`       |
| `--verbose`    | `-v`  | Verbose output                                    | `false`       |

### `prune` - Clean System

Remove all deployment configurations and virtual environment.

| Option  | Short | Description              | Default |
| ------- | ----- | ------------------------ | ------- |
| `--yes` | `-y`  | Skip confirmation prompt | `false` |

### `env-to-json` - Convert .env to JSON

Convert .env file to JSON format for debugging.

| Option   | Short | Description    | Default |
| -------- | ----- | -------------- | ------- |
| `--file` | `-f`  | .env file path | `.env`  |

### `show` - Show Configuration

Display current configuration settings.

## Architecture

### Configuration System

The configuration system uses a **modular, environment-based design**:

**Model Files:**

- `host_config.dart` - SSH host configuration (host, port, user, ssh_key_path, password)
- `container_config.dart` - Container runtime settings (runtime, compose_file, services, rebuild_strategy)
- `ansible_config.dart` - Ansible playbook configuration (inventory_path, playbooks, extra_vars)
- `registry_config.dart` - Container registry settings (url, username, token)
- `openbao_config.dart` - OpenBao secret management (address, namespace, per-environment token managers)
- `environment_config.dart` - Environment-specific wrapper (local, staging, production)
- `deploy_config.dart` - Main configuration class

**Benefits:**

- **Small, focused files** - Each file has a single responsibility
- **Environment isolation** - Each environment (local, staging, production) has its own configuration
- **Type safety** - Strong typing prevents configuration errors
- **Backward compatibility** - Helper methods allow existing code to work seamlessly
- **Easy maintenance** - Clear separation of concerns

See [ENVIRONMENT_BASED_CONFIG.md](ENVIRONMENT_BASED_CONFIG.md) for detailed architecture documentation.

### Playbook Generation

Playbooks are **generated on-demand** from Dart templates and **deleted after deployment**:

1. `deploy-dev` command generates playbooks in `.deploy_playbooks/`
2. Ansible runs the generated playbooks from the venv
3. Playbooks are cleaned up after deployment (success or failure)

### Modern Ansible Syntax

Generated playbooks use modern Ansible syntax:

- `ansible.builtin.file` instead of `file`
- `ansible.builtin.copy` instead of `copy`
- `ansible.builtin.shell` instead of `shell`
- `ansible.posix.synchronize` for rsync
- `true/false` instead of `yes/no`

### Python Virtual Environment

The CLI manages its own Python venv:

- Location: `.venv/` in project directory
- Auto-installs: `ansible`, `ansible.posix`, `community.general`
- Isolated from system Python

### Configuration Directory

The CLI stores configuration in `~/.dart-cloud-deploy/`:

- `config.yaml` - Global configuration
- `credentials.yaml` - Stored credentials
- `cache/` - Cached data
- `logs/` - Log files
- `playbooks/` - Generated playbooks
- `inventory/` - Ansible inventory files
- `hive/` - Encrypted token storage

### OpenBao Authentication

The CLI uses **AppRole authentication** for secure secrets retrieval:

1. **Manager Token**: Uses the provided `token_manager` (file or string) to authenticate and generate a `secret-id` via the configured `role_name`.
2. **AppRole Login**: Logs in using the configured `role_id` and generated `secret-id`.
3. **Token Caching**: The resulting client token is cached in a secure Hive database (LazyBox) with a 1-hour TTL.
4. **Auto-Renewal**: Tokens are automatically checked for validity before use and refreshed transparently if expired.

## Requirements

- **Dart SDK**: ^3.10.4
- **Python**: 3.8+ (for Ansible venv)
- **Container Runtime**: Podman or Docker (for local deployment)
- **OpenBao/Vault**: Optional, for secrets management
- **openbao_api**: Dart package for OpenBao integration (included as dependency)

## Generic Usage Patterns

### Using with Any Dart Backend

The CLI is designed to work with any containerized Dart backend:

1. Create a `docker-compose.yml` with your services
2. Initialize configuration: `dart_cloud_deploy config init -e local`
3. Update `deploy.yaml` with your service names
4. Deploy: `dart_cloud_deploy deploy-local`

### Multi-Environment Setup

With the new environment-based configuration, you can manage all environments in a single file:

```bash
# Create a single config file with all environments
dart_cloud_deploy config init -e local

# Edit deploy.yaml to add staging and production sections
# (See Configuration File section above for example)

# Deploy to local environment
dart_cloud_deploy deploy-local -c deploy.yaml

# Deploy to staging environment
dart_cloud_deploy deploy-dev -c deploy.yaml

# Deploy to production environment
dart_cloud_deploy deploy-dev -c deploy.yaml
```

Or use separate config files for each environment:

```bash
# Create configs for each environment
dart_cloud_deploy config init -e local -o deploy-local.yaml
dart_cloud_deploy config init -e staging -o deploy-staging.yaml
dart_cloud_deploy config init -e production -o deploy-prod.yaml

# Deploy to specific environment
dart_cloud_deploy deploy-local -c deploy-local.yaml
dart_cloud_deploy deploy-dev -c deploy-staging.yaml
dart_cloud_deploy deploy-dev -c deploy-prod.yaml
```

### CI/CD Integration

```yaml
# GitHub Actions example
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      - name: Install CLI
        run: dart pub global activate --source path tools/dart_packages/dart_cloud_deploy_cli
      - name: Initialize
        run: dart_cloud_deploy init
      - name: Deploy
        run: dart_cloud_deploy deploy-dev -c deploy-prod.yaml
```

### Without OpenBao (Manual Secrets)

If you don't use OpenBao, create `.env` manually:

```bash
# Skip secrets fetch during deployment
dart_cloud_deploy deploy-local --skip-secrets

# Or create .env from example
cp .env.example .env
# Edit .env with your values
dart_cloud_deploy deploy-local
```

## Troubleshooting

### Common Issues

**Python not found**

```bash
# macOS
brew install python3

# Ubuntu/Debian
sudo apt install python3 python3-venv

# Fedora
sudo dnf install python3
```

**Container runtime not found**

```bash
# Check if podman/docker is installed
podman --version
docker --version

# Update config to use available runtime
# In deploy.yaml: container.runtime: docker
```

**OpenBao connection failed**

```bash
# Check OpenBao status
dart_cloud_deploy secrets check

# Verify token is valid
cat ~/.openbao/token

# Skip secrets if not needed
dart_cloud_deploy deploy-local --skip-secrets
```

**Ansible connection failed**

```bash
# Test SSH connection manually
ssh -i ~/.ssh/id_rsa user@host

# Check inventory
cat .deploy_inventory/inventory.ini

# Run with verbose output
dart_cloud_deploy deploy-dev -v
```

## License

MIT License - see LICENSE file for details.
