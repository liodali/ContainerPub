# Security Configuration Guide

This guide explains how to securely configure ContainerPub infrastructure with proper secrets management.

## Overview

**⚠️ IMPORTANT:** Never commit secrets to version control!

All sensitive data (passwords, JWT secrets, API keys) should be:
- Stored in `.env` files (excluded from Git)
- Injected at runtime via environment variables
- Generated with strong, random values

## Quick Setup

### 1. Create Environment File

```bash
# Copy the example file
cp .env.example .env

# Generate secure passwords
openssl rand -base64 32
```

### 2. Edit `.env` File

```bash
# Open in your editor
nano .env  # or vim, code, etc.
```

Fill in secure values:

```bash
POSTGRES_USER=dart_cloud
POSTGRES_PASSWORD=your_secure_random_password_here
POSTGRES_DB=dart_cloud
POSTGRES_PORT=5432

BACKEND_PORT=8080
JWT_SECRET=your_long_random_jwt_secret_at_least_32_chars

FUNCTION_TIMEOUT_SECONDS=5
FUNCTION_MAX_MEMORY_MB=128
FUNCTION_MAX_CONCURRENT=10
```

### 3. Deploy with Secure Configuration

```bash
# The deploy script automatically loads .env
./scripts/deploy.sh

# Or use make
make deploy
```

## Configuration Methods

### Method 1: Environment File (.env) - Recommended

**Best for:** Local development, single-server deployments

```bash
# Create .env from example
cp .env.example .env

# Edit with secure values
vim .env

# Deploy (automatically loads .env)
./scripts/deploy.sh
```

**Pros:**
- Simple to use
- Centralized configuration
- Automatically loaded by scripts

**Cons:**
- File must be secured (chmod 600)
- Not suitable for multi-environment setups

### Method 2: Environment Variables

**Best for:** CI/CD pipelines, containerized deployments

```bash
# Set environment variables
export POSTGRES_PASSWORD="secure_password"
export JWT_SECRET="long_random_secret"

# Deploy
./scripts/deploy.sh
```

**Pros:**
- No files to manage
- Perfect for CI/CD
- Most secure (no disk storage)

**Cons:**
- Variables lost when session ends
- Must be set every time

### Method 3: Secrets Management Tools

**Best for:** Production, enterprise environments

Use tools like:
- HashiCorp Vault
- AWS Secrets Manager
- Azure Key Vault
- Google Secret Manager

Example with Vault:

```bash
# Store secrets in Vault
vault kv put secret/containerpub \
  postgres_password="secure_password" \
  jwt_secret="long_random_secret"

# Retrieve and deploy
export POSTGRES_PASSWORD=$(vault kv get -field=postgres_password secret/containerpub)
export JWT_SECRET=$(vault kv get -field=jwt_secret secret/containerpub)
./scripts/deploy.sh
```

## Generating Secure Secrets

### PostgreSQL Password

```bash
# Generate 32-character random password
openssl rand -base64 32
```

### JWT Secret

```bash
# Generate 64-character random secret
openssl rand -base64 64
```

## Security Best Practices

### File Permissions

```bash
# Secure .env file (owner read/write only)
chmod 600 .env
```

### Git Protection

The `.gitignore` file already excludes `.env`.

**Verify before committing:**

```bash
# Check what will be committed
git status

# Ensure .env is not listed
git ls-files | grep '.env$'
```

### Container Security

**Never bake secrets into images:**

```dockerfile
# ❌ BAD - Don't do this
ENV POSTGRES_PASSWORD=hardcoded_password

# ✅ GOOD - Inject at runtime
# (no ENV for password in Dockerfile)
```
