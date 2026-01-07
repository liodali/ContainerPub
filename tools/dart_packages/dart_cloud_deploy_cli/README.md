# Dart Cloud Deploy CLI

A robust deployment CLI for managing Dart Cloud Backend deployments with OpenBao secrets management and Ansible integration.

## Features

- **Local Deployment**: Deploy locally using Podman/Docker without Ansible
- **Dev Deployment**: Deploy to remote VPS using Ansible playbooks
- **Secrets Management**: Fetch secrets from OpenBao and generate `.env` files
- **Configuration**: Support for YAML and TOML configuration files
- **Python Venv Management**: Auto-creates Python venv and installs Ansible
- **Dynamic Playbooks**: Generates playbooks on-demand with modern Ansible syntax (`ansible.builtin.*`)
- **Auto Cleanup**: Removes generated playbooks after deployment

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

### 1. Initialize Environment

```bash
# Initialize Python venv and install Ansible
dart_cloud_deploy init

# Force reinstall
dart_cloud_deploy init --force
```

### 2. Initialize Configuration

```bash
# Create a YAML config for local development
dart_cloud_deploy config init -e local

# Create a YAML config for dev environment
dart_cloud_deploy config init -e dev -o deploy-dev.yaml
```

### 3. Fetch Secrets (Optional)

```bash
# Fetch secrets and write to .env
dart_cloud_deploy secrets fetch

# Check OpenBao connection
dart_cloud_deploy secrets check
```

### 4. Deploy Locally

```bash
# Deploy all services locally (Podman/Docker)
dart_cloud_deploy deploy-local

# Deploy with forced rebuild
dart_cloud_deploy deploy-local --force
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

# Dry run
dart_cloud_deploy deploy-dev --dry-run
```

## Configuration File (deploy.yaml)

```yaml
name: dart_cloud_backend
environment: dev
project_path: .
env_file_path: .env

openbao:
  address: http://localhost:8200
  token_path: ~/.openbao/token
  secret_path: secret/data/dart_cloud/dev

container:
  runtime: podman
  compose_file: docker-compose.yml
  project_name: dart_cloud
  services:
    backend: dart_cloud_backend
    postgres: dart_cloud_postgres

host:
  host: your-server.example.com
  port: 22
  user: deploy
  ssh_key_path: ~/.ssh/id_rsa

ansible:
  extra_vars:
    app_dir: /opt/dart_cloud
    postgres_user: dart_cloud
    postgres_db: dart_cloud
```

## Commands

| Command           | Description                                |
| ----------------- | ------------------------------------------ |
| `init`            | Initialize Python venv and install Ansible |
| `config init`     | Initialize deployment configuration        |
| `config validate` | Validate configuration file                |
| `deploy-local`    | Deploy locally using Podman/Docker         |
| `deploy-dev`      | Deploy to dev server using Ansible         |
| `secrets fetch`   | Fetch secrets from OpenBao                 |
| `secrets check`   | Check OpenBao connection                   |
| `show`            | Show current configuration                 |

## Architecture

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

## Requirements

- **Dart SDK**: ^3.10.4
- **Python**: 3.8+ (for Ansible venv)
- **Container Runtime**: Podman or Docker (for local deployment)
- **OpenBao/Vault**: Optional, for secrets management
