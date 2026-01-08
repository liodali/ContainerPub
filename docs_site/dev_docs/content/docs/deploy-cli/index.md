---
title: Backend Deploy CLI
description: Deployment CLI for managing Dart Cloud Backend deployments with OpenBao secrets and Ansible
---

# Backend Deploy CLI

The `dart_cloud_deploy` CLI is a robust deployment tool for managing Dart Cloud Backend deployments with OpenBao secrets management and Ansible integration.

## Overview

The Deploy CLI enables DevOps and developers to:

- **Deploy Locally** - Deploy using Podman/Docker without Ansible
- **Deploy Remotely** - Deploy to VPS/servers using Ansible playbooks
- **Manage Secrets** - Fetch secrets from OpenBao and generate `.env` files
- **Multi-Environment** - Support for local, dev, and production environments
- **CI/CD Ready** - Integrate with GitHub Actions and other CI/CD pipelines

## Quick Links

- [Quick Start](./quickstart.md) - Get started in 5 minutes
- [Commands Reference](./commands.md) - Complete command documentation
- [CI/CD Integration](./cicd.md) - Pipeline setup and examples

## Key Features

### Local Deployment

- **Container Runtime** - Works with Podman or Docker
- **Compose Support** - Uses docker-compose/podman-compose
- **Interactive Menus** - User-friendly prompts for service management
- **Health Checks** - Automatic service health verification
- **Selective Rebuild** - Rebuild backend only, keeping database data

### Remote Deployment

- **Ansible Integration** - Uses Ansible for remote deployments
- **Dynamic Playbooks** - Generates playbooks on-demand
- **Modern Syntax** - Uses `ansible.builtin.*` modules
- **Auto Cleanup** - Removes generated playbooks after deployment
- **SSH Key Auth** - Secure SSH key-based authentication

### Secrets Management

- **OpenBao/Vault** - Fetch secrets from OpenBao or HashiCorp Vault
- **Auto .env Generation** - Writes secrets to `.env` files
- **Path Override** - Fetch from different secret paths
- **Health Check** - Verify OpenBao connectivity

### Configuration

- **YAML & TOML** - Support for both configuration formats
- **Environment Templates** - Generate configs for local/dev/production
- **Validation** - Validate configuration before deployment
- **Flexible Paths** - Custom paths for all components

## Installation

### Quick Install

```dart
cd ContainerPub/tools/dart_packages/dart_cloud_deploy_cli
./scripts/build.sh
./scripts/install.sh
```

### Manual Install

```dart
cd tools/dart_packages/dart_cloud_deploy_cli
dart pub get
dart pub global activate --source path .
```

### Verify Installation

```dart
dart_cloud_deploy --help
```

## Quick Start

```dart
# 1. Initialize environment (Python venv + Ansible)
dart_cloud_deploy init

# 2. Create configuration
dart_cloud_deploy config init -e local

# 3. Deploy locally
dart_cloud_deploy deploy-local
```

## Architecture

### Workflow

```dart
┌─────────────────────────────────────────────────────────────┐
│                    dart_cloud_deploy                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────────────────┐   │
│  │   init   │───▶│  config  │───▶│  deploy-local/dev    │   │
│  └──────────┘    └──────────┘    └──────────────────────┘   │
│       │               │                    │                 │
│       ▼               ▼                    ▼                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────────────────┐   │
│  │  Python  │    │  YAML/   │    │  Podman/Docker or    │   │
│  │   venv   │    │  TOML    │    │  Ansible Playbooks   │   │
│  │ +Ansible │    │  Config  │    └──────────────────────┘   │
│  └──────────┘    └──────────┘                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Local Deployment Flow

1. Load configuration from `deploy.yaml`
2. Check container runtime (Podman/Docker)
3. Fetch secrets from OpenBao (optional)
4. Start services with docker-compose
5. Wait for health checks
6. Display service endpoints

### Remote Deployment Flow

1. Load configuration from `deploy.yaml`
2. Check Ansible environment
3. Fetch secrets from OpenBao (optional)
4. Generate Ansible inventory
5. Generate playbooks from templates
6. Run Ansible playbooks
7. Cleanup temporary files

## Configuration Example

```dart
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
```

## Requirements

| Requirement   | Version  | Purpose            |
| ------------- | -------- | ------------------ |
| Dart SDK      | ^3.10.4  | CLI runtime        |
| Python        | 3.8+     | Ansible venv       |
| Podman/Docker | Latest   | Local deployment   |
| OpenBao/Vault | Optional | Secrets management |

## Directory Structure

```dart
~/.dart-cloud-deploy/
├── config.yaml       # Global configuration
├── credentials.yaml  # Stored credentials
├── cache/            # Cached data
├── logs/             # Log files
├── playbooks/        # Generated playbooks
└── inventory/        # Ansible inventory files
```

## Next Steps

- Follow the [Quick Start Guide](./quickstart.md) to deploy your first backend
- Read the [Commands Reference](./commands.md) for all available options
- Set up [CI/CD Integration](./cicd.md) for automated deployments

## Support

For issues, questions, or contributions:

- GitHub: [liodali/ContainerPub](https://github.com/liodali/ContainerPub)
- Documentation: [ContainerPub Docs](/)
