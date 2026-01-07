---
title: Quick Start Guide
description: Get started with the Backend Deploy CLI in 5 minutes
---

# Quick Start Guide

This guide will help you deploy your Dart backend in minutes.

## Prerequisites

Before you begin, ensure you have:

- **Dart SDK** ^3.10.4
- **Python** 3.8+ (for Ansible)
- **Podman** or **Docker** (for local deployment)

## Installation

```bash
# Navigate to the CLI package
cd ContainerPub/tools/dart_packages/dart_cloud_deploy_cli

# Build and install
./scripts/build.sh
./scripts/install.sh

# Verify installation
dart_cloud_deploy --help
```

## Local Deployment

The simplest way to deploy your Dart backend locally.

### Step 1: Initialize Environment

```bash
dart_cloud_deploy init
```

This creates a Python virtual environment and installs Ansible with required collections.

**Output:**

```
═══════════════════════════════════════════════════════════════
  Initializing Deployment Environment
═══════════════════════════════════════════════════════════════
✓ Config directory: ~/.dart-cloud-deploy
✓ Python found: python3
✓ Virtual environment created
✓ Ansible installed: ansible 2.15.0
✓ Collections installed
```

### Step 2: Create Configuration

```bash
dart_cloud_deploy config init -e local
```

This creates `deploy.yaml` with local deployment settings.

**Generated `deploy.yaml`:**

```yaml
name: dart_cloud_backend
environment: local
project_path: .
env_file_path: .env

container:
  runtime: podman
  compose_file: docker-compose.yml
  project_name: dart_cloud
  services:
    backend: dart_cloud_backend
    postgres: dart_cloud_postgres
```

### Step 3: Deploy

```bash
dart_cloud_deploy deploy-local
```

**Output:**

```
═══════════════════════════════════════════════════════════════
  Dart Cloud Local Deployment
═══════════════════════════════════════════════════════════════
✓ podman is available
✓ Compose is available
✓ .env file found

═══════════════════════════════════════════════════════════════
  Starting Services
═══════════════════════════════════════════════════════════════
Deploying all services...
✓ PostgreSQL is ready
✓ Backend is ready

═══════════════════════════════════════════════════════════════
  Deployment Complete!
═══════════════════════════════════════════════════════════════
Service Endpoints:
  Backend API:    http://localhost:8080
  Health Check:   http://localhost:8080/health
  PostgreSQL:     postgres:5432 (internal network)
```

### Step 4: Verify

```bash
# Check health endpoint
curl http://localhost:8080/health

# View logs
podman-compose logs -f
```

## Remote Deployment

Deploy to a remote server using Ansible.

### Step 1: Initialize Environment

```bash
dart_cloud_deploy init
```

### Step 2: Create Dev Configuration

```bash
dart_cloud_deploy config init -e dev -o deploy-dev.yaml
```

### Step 3: Configure Server

Edit `deploy-dev.yaml` with your server details:

```yaml
name: dart_cloud_backend
environment: dev
project_path: .
env_file_path: .env

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

### Step 4: Deploy

```bash
# Preview what will happen (dry run)
dart_cloud_deploy deploy-dev -c deploy-dev.yaml --dry-run

# Deploy for real
dart_cloud_deploy deploy-dev -c deploy-dev.yaml
```

## Working with Secrets

### Option A: Using OpenBao

Add OpenBao configuration to your `deploy.yaml`:

```yaml
openbao:
  address: http://localhost:8200
  token_path: ~/.openbao/token
  secret_path: secret/data/dart_cloud/dev
```

Fetch secrets:

```bash
# Check connection
dart_cloud_deploy secrets check

# Fetch and write to .env
dart_cloud_deploy secrets fetch
```

### Option B: Manual .env

If you don't use OpenBao:

```bash
# Create .env from example
cp .env.example .env

# Edit with your values
nano .env

# Deploy without fetching secrets
dart_cloud_deploy deploy-local --skip-secrets
```

## Common Tasks

### Rebuild Backend Only

When you've made code changes:

```bash
dart_cloud_deploy deploy-local
# Select: "Rebuild backend only (keep PostgreSQL and data)"
```

### Force Full Rebuild

Start fresh:

```bash
dart_cloud_deploy deploy-local --force
```

### Deploy Specific Service

```bash
# Backend only
dart_cloud_deploy deploy-local -s backend

# Database only
dart_cloud_deploy deploy-local -s postgres
```

### View Configuration

```bash
dart_cloud_deploy show
```

### Validate Configuration

```bash
dart_cloud_deploy config validate -c deploy.yaml
```

## Multi-Environment Setup

Create separate configs for each environment:

```bash
# Local development
dart_cloud_deploy config init -e local -o deploy-local.yaml

# Development server
dart_cloud_deploy config init -e dev -o deploy-dev.yaml

# Production server
dart_cloud_deploy config init -e production -o deploy-prod.yaml
```

Deploy to specific environment:

```bash
# Local
dart_cloud_deploy deploy-local -c deploy-local.yaml

# Dev server
dart_cloud_deploy deploy-dev -c deploy-dev.yaml

# Production
dart_cloud_deploy deploy-dev -c deploy-prod.yaml
```

## Troubleshooting

### Python Not Found

```bash
# macOS
brew install python3

# Ubuntu/Debian
sudo apt install python3 python3-venv

# Fedora
sudo dnf install python3
```

### Container Runtime Not Found

```bash
# Check if installed
podman --version
docker --version

# Update config to use available runtime
# In deploy.yaml: container.runtime: docker
```

### OpenBao Connection Failed

```bash
# Check status
dart_cloud_deploy secrets check

# Verify token
cat ~/.openbao/token

# Skip if not needed
dart_cloud_deploy deploy-local --skip-secrets
```

### Ansible Connection Failed

```bash
# Test SSH manually
ssh -i ~/.ssh/id_rsa user@host

# Run with verbose output
dart_cloud_deploy deploy-dev -v
```

## Next Steps

- Read the [Commands Reference](./commands.md) for all options
- Set up [CI/CD Integration](./cicd.md) for automated deployments
- Review the [Overview](./index.md) for architecture details
