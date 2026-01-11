# Quick Start Guide

This guide provides simple examples to get you started with the Dart Cloud Deploy CLI.

## Table of Contents

- [Installation](#installation)
- [Basic Local Deployment](#basic-local-deployment)
- [Remote Server Deployment](#remote-server-deployment)
- [Container Registry Operations](#container-registry-operations)
- [Working with Secrets](#working-with-secrets)
- [System Management](#system-management)
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

## Container Registry Operations

Build and push container images to Gitea/GitHub registries.

### Basic Build and Push

```bash
# Build and push with default settings
dart_cloud_deploy build-push -i myapp/backend -t v1.0.0
```

### Build Options

```bash
# Build only (no push)
dart_cloud_deploy build-push -i myapp/backend --no-push

# Custom Dockerfile
dart_cloud_deploy build-push -i myapp/backend -d Dockerfile.prod

# Custom build context
dart_cloud_deploy build-push -i myapp/backend -c ./backend

# With build arguments
dart_cloud_deploy build-push -i myapp/backend \
  --build-arg NODE_ENV=production \
  --build-arg VERSION=1.0.0

# Verbose output
dart_cloud_deploy build-push -i myapp/backend -v
```

### Registry Configuration

Configure your registry in `deploy.yaml`:

```yaml
registry:
  url: ghcr.io # or your Gitea instance
  username: myuser
  token_base64: base64_encoded_token
```

---

## System Management

### Environment File Conversion

Convert `.env` files to JSON for debugging:

```bash
# Convert default .env file
dart_cloud_deploy env-to-json

# Convert specific file
dart_cloud_deploy env-to-json -f .env.production

# Output example
{
  "DATABASE_URL": "postgres://user:pass@localhost:5432/db",
  "API_KEY": "secret-key",
  "DEBUG": "true"
}
```

### System Cleanup

Remove all deployment configurations and cached data:

```bash
# Interactive cleanup
dart_cloud_deploy prune

# Force cleanup (skip confirmation)
dart_cloud_deploy prune -y
```

This removes:

- Virtual environment (`.venv/`)
- Deployment configs
- Cache and logs
- Generated playbooks
- Ansible inventory files

---

## Working with Secrets

### Option A: Using OpenBao/Vault

Configure OpenBao with per-environment token managers in your `deploy.yaml`:

```yaml
openbao:
  address: http://localhost:8200
  # Per-environment configuration
  # token_manager is used to generate secret-id for AppRole login
  local:
    token_manager: ~/.openbao/local_token # base64-encoded token file
    policy: myapp-local
    secret_path: secret/data/myapp/local
    role_id: local-role-uuid
    role_name: stg-local
  staging:
    token_manager: ~/.openbao/staging_token # base64-encoded token file
    policy: myapp-staging
    secret_path: secret/data/myapp/staging
    role_id: staging-role-uuid
    role_name: stg-staging
  production:
    token_manager: aHZzLnByb2R1Y3Rpb24tdG9rZW4= # direct base64 token
    policy: myapp-production
    secret_path: secret/data/myapp/production
    role_id: production-role-uuid
    role_name: stg-production
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

### Build and Deploy Workflow

```bash
# 1. Build and push new version
dart_cloud_deploy build-push -i myapp/backend -t v2.0.0

# 2. Deploy with new image
dart_cloud_deploy deploy-dev

# 3. Or deploy locally for testing
dart_cloud_deploy deploy-local
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

### Example 4: Container Registry Workflow

Build and push images before deployment:

```bash
# 1. Build and push backend image
dart_cloud_deploy build-push -i myapp/backend -t v1.2.0

# 2. Build and push frontend image
dart_cloud_deploy build-push -i myapp/frontend -t v1.2.0

# 3. Deploy with new images
dart_cloud_deploy deploy-dev -c deploy-prod.yaml
```

### Example 5: Database Backup

Run a backup on your remote server:

```bash
dart_cloud_deploy deploy-dev -t backup -c deploy-prod.yaml
```

### Example 6: Verbose Debugging

When deployment fails and you need more info:

```bash
# Verbose Ansible output
dart_cloud_deploy deploy-dev -v

# Check secrets connection
dart_cloud_deploy secrets check

# Validate config
dart_cloud_deploy config validate
```

### Example 7: Custom Ansible Variables

Pass extra variables to Ansible:

```bash
dart_cloud_deploy deploy-dev \
  -e app_version=2.0.0 \
  -e debug_mode=true \
  -e max_connections=100
```

### Example 8: Selective Deployment with Tags

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
    role_id: local-role-uuid
    role_name: stg-local
  staging:
    token_manager: ~/.openbao/staging_token # base64-encoded
    policy: my-app-staging
    secret_path: secret/data/my_app/staging
    role_id: staging-role-uuid
    role_name: stg-staging
  production:
    token_manager: ~/.openbao/prod_token # base64-encoded
    policy: my-app-production
    secret_path: secret/data/my_app/production
    role_id: production-role-uuid
    role_name: stg-production

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

| Task                   | Command                                         |
| ---------------------- | ----------------------------------------------- |
| Initialize environment | `dart_cloud_deploy init`                        |
| Create local config    | `dart_cloud_deploy config init -e local`        |
| Create staging config  | `dart_cloud_deploy config init -e staging`      |
| Validate config        | `dart_cloud_deploy config validate`             |
| Deploy locally         | `dart_cloud_deploy deploy-local`                |
| Deploy to server       | `dart_cloud_deploy deploy-dev`                  |
| Build and push image   | `dart_cloud_deploy build-push -i myapp/backend` |
| Fetch secrets          | `dart_cloud_deploy secrets fetch`               |
| Check secrets          | `dart_cloud_deploy secrets check`               |
| Convert .env to JSON   | `dart_cloud_deploy env-to-json -f .env`         |
| Show config            | `dart_cloud_deploy show`                        |
| Clean system           | `dart_cloud_deploy prune -y`                    |
| Dry run                | `dart_cloud_deploy deploy-dev --dry-run`        |
| Verbose mode           | `dart_cloud_deploy deploy-dev -v`               |
| Force rebuild          | `dart_cloud_deploy deploy-local --force`        |

---

## Next Steps

- Read the full [README.md](README.md) for detailed command reference
- Check out the [Architecture section](README.md#architecture) to understand how playbooks are generated
- Review [Troubleshooting](README.md#troubleshooting) if you encounter issues
