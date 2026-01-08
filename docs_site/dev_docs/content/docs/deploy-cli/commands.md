---
title: Commands Reference
description: Complete reference for all dart_cloud_deploy commands and options
---

# Commands Reference

Complete documentation for all `dart_cloud_deploy` commands and their options.

## Command Overview

| Command           | Description                                |
| ----------------- | ------------------------------------------ |
| `init`            | Initialize Python venv and install Ansible |
| `config init`     | Create deployment configuration file       |
| `config validate` | Validate configuration file                |
| `config set`      | Set a configuration value                  |
| `deploy-local`    | Deploy locally using Podman/Docker         |
| `deploy-dev`      | Deploy to remote server using Ansible      |
| `secrets fetch`   | Fetch secrets from OpenBao                 |
| `secrets list`    | List available secrets                     |
| `secrets check`   | Check OpenBao connection                   |
| `show`            | Display current configuration              |

---

## `init`

Initialize the deployment environment by creating a Python virtual environment and installing Ansible with required collections.

### Usage

```dart
dart_cloud_deploy init [options]
```

### Options

| Option               | Short | Description                            | Default |
| -------------------- | ----- | -------------------------------------- | ------- |
| `--venv-path`        |       | Path for Python virtual environment    | `.venv` |
| `--force`            | `-f`  | Force reinstall even if already exists | `false` |
| `--skip-collections` |       | Skip installing Ansible collections    | `false` |

### Examples

```dart
# Basic initialization
dart_cloud_deploy init

# Custom venv path
dart_cloud_deploy init --venv-path /opt/ansible-venv

# Force reinstall
dart_cloud_deploy init --force

# Skip collections (faster, if already installed)
dart_cloud_deploy init --skip-collections
```

### What It Does

1. Creates config directory at `~/.dart-cloud-deploy/`
2. Checks Python installation
3. Creates Python virtual environment
4. Installs Ansible in the venv
5. Installs Ansible collections:
   - `ansible.posix`
   - `community.general`

---

## `config`

Configuration management commands.

### `config init`

Create a new deployment configuration file.

#### Usage

```dart
dart_cloud_deploy config init [options]
```

#### Options

| Option          | Short | Description                                       | Default       |
| --------------- | ----- | ------------------------------------------------- | ------------- |
| `--format`      | `-f`  | Configuration format (`yaml`, `toml`)             | `yaml`        |
| `--output`      | `-o`  | Output file path                                  | `deploy.yaml` |
| `--environment` | `-e`  | Target environment (`local`, `dev`, `production`) | `local`       |

#### Examples

```dart
# Local YAML config
dart_cloud_deploy config init -e local

# Dev YAML config with custom name
dart_cloud_deploy config init -e dev -o deploy-dev.yaml

# Production TOML config
dart_cloud_deploy config init -f toml -e production -o deploy-prod.toml
```

### `config validate`

Validate a deployment configuration file.

#### Usage

```dart
dart_cloud_deploy config validate [options]
```

#### Options

| Option     | Short | Description             | Default       |
| ---------- | ----- | ----------------------- | ------------- |
| `--config` | `-c`  | Configuration file path | `deploy.yaml` |

#### Examples

```dart
# Validate default config
dart_cloud_deploy config validate

# Validate specific config
dart_cloud_deploy config validate -c deploy-prod.yaml
```

#### Validation Checks

- Required fields: `name`, `environment`, `container`
- Container: `compose_file` required
- Non-local environments: `host` configuration required
- Warning if OpenBao not configured

### `config set`

Set a configuration value (manual editing recommended for complex changes).

#### Usage

```dart
dart_cloud_deploy config set [options]
```

#### Options

| Option     | Short | Description                      | Default       |
| ---------- | ----- | -------------------------------- | ------------- |
| `--config` | `-c`  | Configuration file path          | `deploy.yaml` |
| `--key`    | `-k`  | Configuration key (dot notation) | required      |
| `--value`  | `-v`  | Configuration value              | required      |

#### Examples

```dart
dart_cloud_deploy config set -k host.host -v server.example.com
dart_cloud_deploy config set -k container.runtime -v docker
```

---

## `deploy-local`

Deploy locally using Podman or Docker without Ansible.

### Usage

```dart
dart_cloud_deploy deploy-local [options]
```

### Options

| Option           | Short | Description                        | Default       |
| ---------------- | ----- | ---------------------------------- | ------------- |
| `--config`       | `-c`  | Configuration file path            | `deploy.yaml` |
| `--build`        | `-b`  | Force rebuild containers           | `true`        |
| `--force`        | `-f`  | Force recreate containers          | `false`       |
| `--skip-secrets` |       | Skip fetching secrets from OpenBao | `false`       |
| `--service`      | `-s`  | Deploy specific service only       | all           |

### Examples

```dart
# Deploy all services
dart_cloud_deploy deploy-local

# Deploy with custom config
dart_cloud_deploy deploy-local -c deploy-local.yaml

# Force recreate all containers
dart_cloud_deploy deploy-local --force

# Deploy backend only
dart_cloud_deploy deploy-local -s backend

# Deploy without rebuilding
dart_cloud_deploy deploy-local --no-build

# Skip secrets fetch
dart_cloud_deploy deploy-local --skip-secrets
```

### Interactive Menu

When services already exist, you'll see an interactive menu:

```dart
═══════════════════════════════════════════════════════════════
  Services Already Exist
═══════════════════════════════════════════════════════════════
What would you like to do?
  1. Start stopped services (without rebuilding)
  2. Rebuild backend only (keep PostgreSQL and data)
  3. Rebuild backend and remove its volume
  4. Remove everything (all containers + volumes)
  5. Cancel and exit
```

### Service Names

| Service    | Description          |
| ---------- | -------------------- |
| `backend`  | Dart backend service |
| `postgres` | PostgreSQL database  |

---

## `deploy-dev`

Deploy to a remote server using Ansible playbooks.

### Usage

```dart
dart_cloud_deploy deploy-dev [options]
```

### Options

| Option           | Short | Description                               | Default       |
| ---------------- | ----- | ----------------------------------------- | ------------- |
| `--config`       | `-c`  | Configuration file path                   | `deploy.yaml` |
| `--target`       | `-t`  | Deployment target                         | `all`         |
| `--skip-secrets` |       | Skip fetching secrets from OpenBao        | `false`       |
| `--verbose`      | `-v`  | Verbose Ansible output                    | `false`       |
| `--dry-run`      |       | Preview without executing                 | `false`       |
| `--tags`         |       | Ansible tags to run (multiple)            | none          |
| `--skip-tags`    |       | Ansible tags to skip (multiple)           | none          |
| `--extra-vars`   | `-e`  | Extra variables as `key=value` (multiple) | none          |

### Target Options

| Target     | Description                            |
| ---------- | -------------------------------------- |
| `all`      | Deploy everything (database + backend) |
| `backend`  | Deploy backend only                    |
| `database` | Deploy database only                   |
| `backup`   | Run backup playbook                    |

### Examples

```dart
# Deploy everything
dart_cloud_deploy deploy-dev

# Deploy with custom config
dart_cloud_deploy deploy-dev -c deploy-prod.yaml

# Deploy backend only
dart_cloud_deploy deploy-dev -t backend

# Deploy database only
dart_cloud_deploy deploy-dev -t database

# Run backup
dart_cloud_deploy deploy-dev -t backup

# Dry run (preview)
dart_cloud_deploy deploy-dev --dry-run

# Verbose output
dart_cloud_deploy deploy-dev -v

# Pass extra variables
dart_cloud_deploy deploy-dev -e app_version=2.0.0 -e debug=true

# Run specific tags
dart_cloud_deploy deploy-dev --tags setup,deploy

# Skip specific tags
dart_cloud_deploy deploy-dev --skip-tags cleanup
```

### Requirements

- Host configuration in `deploy.yaml`
- Ansible configuration in `deploy.yaml`
- SSH key access to target server

---

## `secrets`

Secrets management commands for OpenBao/Vault integration.

### `secrets fetch`

Fetch secrets from OpenBao and write to `.env` file.

#### Usage

```dart
dart_cloud_deploy secrets fetch [options]
```

#### Options

| Option     | Short | Description                     | Default       |
| ---------- | ----- | ------------------------------- | ------------- |
| `--config` | `-c`  | Configuration file path         | `deploy.yaml` |
| `--output` | `-o`  | Output .env file path           | from config   |
| `--path`   | `-p`  | Override secret path in OpenBao | from config   |

#### Examples

```dart
# Fetch with default settings
dart_cloud_deploy secrets fetch

# Fetch to custom file
dart_cloud_deploy secrets fetch -o .env.local

# Fetch from different path
dart_cloud_deploy secrets fetch -p secret/data/myapp/prod

# Use different config
dart_cloud_deploy secrets fetch -c deploy-prod.yaml
```

### `secrets list`

List available secrets in OpenBao.

#### Usage

```dart
dart_cloud_deploy secrets list [options]
```

#### Options

| Option     | Short | Description               | Default                      |
| ---------- | ----- | ------------------------- | ---------------------------- |
| `--config` | `-c`  | Configuration file path   | `deploy.yaml`                |
| `--path`   | `-p`  | Path to list secrets from | `secret/metadata/dart_cloud` |

#### Examples

```dart
# List with default path
dart_cloud_deploy secrets list

# List from specific path
dart_cloud_deploy secrets list -p secret/metadata/myapp
```

### `secrets check`

Check OpenBao connection and authentication.

#### Usage

```dart
dart_cloud_deploy secrets check [options]
```

#### Options

| Option     | Short | Description             | Default       |
| ---------- | ----- | ----------------------- | ------------- |
| `--config` | `-c`  | Configuration file path | `deploy.yaml` |

#### Examples

```dart
# Check connection
dart_cloud_deploy secrets check

# Check with specific config
dart_cloud_deploy secrets check -c deploy-prod.yaml
```

#### Output

```
═══════════════════════════════════════════════════════════════
  Checking OpenBao Connection
═══════════════════════════════════════════════════════════════
Address:      http://localhost:8200
Secret Path:  secret/data/dart_cloud/dev
✓ OpenBao is healthy and reachable
✓ Successfully accessed secrets (5 keys)
Available keys:
  - DATABASE_URL
  - JWT_SECRET
  - API_KEY
  - POSTGRES_PASSWORD
  - REDIS_URL
```

---

## `show`

Display current configuration settings.

### Usage

```dart
dart_cloud_deploy show [options]
```

### Options

| Option     | Short | Description             | Default       |
| ---------- | ----- | ----------------------- | ------------- |
| `--config` | `-c`  | Configuration file path | `deploy.yaml` |

### Examples

```dart
# Show default config
dart_cloud_deploy show

# Show specific config
dart_cloud_deploy show -c deploy-prod.yaml
```

---

## Global Options

These options are available for all commands:

| Option      | Description           |
| ----------- | --------------------- |
| `--help`    | Show help for command |
| `--version` | Show CLI version      |

## Configuration File Reference

### Minimal Local Config

```dart
name: my_app
environment: local
project_path: .

container:
  runtime: podman
  compose_file: docker-compose.yml
  project_name: my_app
```

### Full Config with All Options

```dart
name: my_app
environment: dev
project_path: .
env_file_path: .env

openbao:
  address: http://vault.example.com:8200
  token: hvs.xxxxx # Or use token_path
  token_path: ~/.openbao/token
  secret_path: secret/data/my_app/dev
  namespace: admin # Optional

container:
  runtime: podman # or docker
  compose_file: docker-compose.yml
  project_name: my_app
  network_name: my_app_network
  services:
    backend: my_app_backend
    postgres: my_app_postgres

host:
  host: server.example.com
  port: 22
  user: deploy
  ssh_key_path: ~/.ssh/id_rsa
  # password: xxx  # Not recommended

ansible:
  backend_playbook: playbooks/backend.yml
  database_playbook: playbooks/database.yml
  backup_playbook: playbooks/backup.yml
  extra_vars:
    deploy_user: deploy
    app_dir: /opt/my_app
    postgres_user: my_app
    postgres_db: my_app
```

## Exit Codes

| Code | Description         |
| ---- | ------------------- |
| 0    | Success             |
| 1    | General error       |
| 2    | Configuration error |
| 3    | Connection error    |
| 4    | Deployment error    |

## Next Steps

- Set up [CI/CD Integration](./cicd.md) for automated deployments
- Review the [Overview](./index.md) for architecture details
- Follow the [Quick Start](./quickstart.md) for step-by-step guide
