# Quick Start Guide

This guide provides simple examples to get you started with the Dart Cloud Deploy CLI.

## Table of Contents

- [Installation](#installation)
- [Basic Local Deployment](#basic-local-deployment)
- [Remote Server Deployment](#remote-server-deployment)
- [Working with Secrets](#working-with-secrets)
- [Common Workflows](#common-workflows)
- [Examples by Use Case](#examples-by-use-case)

---

## Installation

```bash
# Option 1: Quick install
cd ContainerPub/tools/dart_packages/dart_cloud_deploy_cli
./scripts/build.sh && ./scripts/install.sh

# Option 2: Dart pub global
dart pub global activate --source path .
```

Verify installation:

```bash
dart_cloud_deploy --help
```

---

## Basic Local Deployment

The simplest way to deploy your Dart backend locally.

### Step 1: Initialize the Environment

```bash
dart_cloud_deploy init
```

This creates a Python virtual environment and installs Ansible.

### Step 2: Create Configuration

```bash
dart_cloud_deploy config init -e local
```

This creates `deploy.yaml` with local deployment settings.

### Step 3: Deploy

```bash
dart_cloud_deploy deploy-local
```

That's it! Your services are now running.

### Verify Deployment

```bash
# Check health endpoint
curl http://localhost:8080/health

# View logs
podman-compose logs -f
```

---

## Remote Server Deployment

Deploy to a remote VPS or server using Ansible.

### Step 1: Initialize Environment

```bash
dart_cloud_deploy init
```

### Step 2: Create Dev Configuration

```bash
dart_cloud_deploy config init -e dev -o deploy-dev.yaml
```

### Step 3: Configure Your Server

Edit `deploy-dev.yaml`:

```yaml
host:
  host: your-server.example.com
  port: 22
  user: deploy
  ssh_key_path: ~/.ssh/id_rsa
```

### Step 4: Deploy

```bash
dart_cloud_deploy deploy-dev -c deploy-dev.yaml
```

### Preview Without Deploying

```bash
dart_cloud_deploy deploy-dev -c deploy-dev.yaml --dry-run
```

---

## Working with Secrets

### Option A: Using OpenBao/Vault

Configure OpenBao with per-environment token managers in your `deploy.yaml`:

```yaml
openbao:
  address: http://localhost:8200
  # Per-environment configuration
  # token_manager can be:
  #   - A file path containing base64-encoded token
  #   - A direct base64-encoded token string
  local:
    token_manager: ~/.openbao/local_token # file path
    policy: myapp-local
    secret_path: secret/data/myapp/local
  staging:
    token_manager: ~/.openbao/staging_token # file path
    policy: myapp-staging
    secret_path: secret/data/myapp/staging
  production:
    token_manager: aHZzLnByb2R1Y3Rpb24tdG9rZW4= # direct base64 token
    policy: myapp-production
    secret_path: secret/data/myapp/production
```

To create a base64-encoded token file:

```bash
# Encode your OpenBao token and save to file
echo -n "hvs.your-openbao-token" | base64 > ~/.openbao/local_token

# Or use direct base64 in config (no file needed)
echo -n "hvs.your-openbao-token" | base64
# Output: aHZzLnlvdXItb3BlbmJhby10b2tlbg==
```

Fetch secrets:

```bash
# Check connection for local environment (default)
dart_cloud_deploy secrets check

# Check connection for staging
dart_cloud_deploy secrets check -e staging

# Fetch secrets for local environment (default)
dart_cloud_deploy secrets fetch

# Fetch secrets for staging
dart_cloud_deploy secrets fetch -e staging

# Fetch secrets for production
dart_cloud_deploy secrets fetch -e production
```

### Option B: Manual .env File

If you don't use OpenBao:

```bash
# Create .env from example
cp .env.example .env

# Edit with your values
nano .env

# Deploy without fetching secrets
dart_cloud_deploy deploy-local --skip-secrets
```

---

## Common Workflows

### Rebuild Backend Only

When you've made code changes and need to rebuild:

```bash
dart_cloud_deploy deploy-local
# Select option: "Rebuild backend only (keep PostgreSQL and data)"
```

### Full Clean Rebuild

Start fresh with no existing data:

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

### View Current Configuration

```bash
dart_cloud_deploy show
```

### Validate Configuration

```bash
dart_cloud_deploy config validate -c deploy.yaml
```

---

## Examples by Use Case

### Example 1: Simple Dart Backend

For a basic Dart backend with PostgreSQL:

```bash
# 1. Initialize
dart_cloud_deploy init
dart_cloud_deploy config init -e local

# 2. Deploy
dart_cloud_deploy deploy-local
```

### Example 2: Multi-Environment Setup

Managing local, dev, and production environments:

```bash
# Create environment-specific configs
dart_cloud_deploy config init -e local -o deploy-local.yaml
dart_cloud_deploy config init -e dev -o deploy-dev.yaml
dart_cloud_deploy config init -e production -o deploy-prod.yaml

# Deploy to local
dart_cloud_deploy deploy-local -c deploy-local.yaml

# Deploy to dev
dart_cloud_deploy deploy-dev -c deploy-dev.yaml

# Deploy to production
dart_cloud_deploy deploy-dev -c deploy-prod.yaml
```

### Example 3: CI/CD Pipeline

GitHub Actions workflow:

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install CLI
        run: |
          cd tools/dart_packages/dart_cloud_deploy_cli
          dart pub get
          dart pub global activate --source path .

      - name: Initialize
        run: dart_cloud_deploy init

      - name: Deploy
        run: dart_cloud_deploy deploy-dev -c deploy-prod.yaml
        env:
          SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
```

### Example 4: Database Backup

Run a backup on your remote server:

```bash
dart_cloud_deploy deploy-dev -t backup -c deploy-prod.yaml
```

### Example 5: Verbose Debugging

When deployment fails and you need more info:

```bash
# Verbose Ansible output
dart_cloud_deploy deploy-dev -v

# Check secrets connection
dart_cloud_deploy secrets check

# Validate config
dart_cloud_deploy config validate
```

### Example 6: Custom Ansible Variables

Pass extra variables to Ansible:

```bash
dart_cloud_deploy deploy-dev \
  -e app_version=2.0.0 \
  -e debug_mode=true \
  -e max_connections=100
```

### Example 7: Selective Deployment with Tags

Run only specific parts of the playbook:

```bash
# Only run setup tasks
dart_cloud_deploy deploy-dev --tags setup

# Skip cleanup tasks
dart_cloud_deploy deploy-dev --skip-tags cleanup

# Multiple tags
dart_cloud_deploy deploy-dev --tags setup,deploy --skip-tags test
```

---

## Configuration Templates

### Minimal Local Config

```yaml
name: my_app
environment: local
project_path: .

container:
  runtime: podman
  compose_file: docker-compose.yml
  project_name: my_app
```

### Full Dev Config

```yaml
name: my_app
environment: staging
project_path: .
env_file_path: .env

openbao:
  address: http://vault.example.com:8200
  # token_manager files contain base64-encoded tokens
  local:
    token_manager: ~/.openbao/local_token # base64-encoded
    policy: my-app-local
    secret_path: secret/data/my_app/local
  staging:
    token_manager: ~/.openbao/staging_token # base64-encoded
    policy: my-app-staging
    secret_path: secret/data/my_app/staging
  production:
    token_manager: ~/.openbao/prod_token # base64-encoded
    policy: my-app-production
    secret_path: secret/data/my_app/production

container:
  runtime: podman
  compose_file: docker-compose.yml
  project_name: my_app
  network_name: my_app_network
  services:
    backend: my_app_backend
    postgres: my_app_postgres

host:
  host: dev.example.com
  port: 22
  user: deploy
  ssh_key_path: ~/.ssh/id_rsa

ansible:
  extra_vars:
    app_dir: /opt/my_app
    postgres_user: my_app
    postgres_db: my_app
```

### TOML Format

```bash
dart_cloud_deploy config init -f toml -e dev -o deploy.toml
```

```toml
name = "my_app"
environment = "dev"
project_path = "."

[container]
runtime = "podman"
compose_file = "docker-compose.yml"
project_name = "my_app"

[host]
host = "dev.example.com"
port = 22
user = "deploy"
ssh_key_path = "~/.ssh/id_rsa"
```

---

## Quick Reference

| Task                   | Command                                    |
| ---------------------- | ------------------------------------------ |
| Initialize environment | `dart_cloud_deploy init`                   |
| Create local config    | `dart_cloud_deploy config init -e local`   |
| Create staging config  | `dart_cloud_deploy config init -e staging` |
| Validate config        | `dart_cloud_deploy config validate`        |
| Deploy locally         | `dart_cloud_deploy deploy-local`           |
| Deploy to server       | `dart_cloud_deploy deploy-dev`             |
| Fetch secrets          | `dart_cloud_deploy secrets fetch`          |
| Check secrets          | `dart_cloud_deploy secrets check`          |
| Show config            | `dart_cloud_deploy show`                   |
| Dry run                | `dart_cloud_deploy deploy-dev --dry-run`   |
| Verbose mode           | `dart_cloud_deploy deploy-dev -v`          |
| Force rebuild          | `dart_cloud_deploy deploy-local --force`   |

---

## Next Steps

- Read the full [README.md](README.md) for detailed command reference
- Check out the [Architecture section](README.md#architecture) to understand how playbooks are generated
- Review [Troubleshooting](README.md#troubleshooting) if you encounter issues
