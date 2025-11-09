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

### Method 2: OpenTofu Variables File

**Best for:** Infrastructure-as-code, team environments

```bash
# Create terraform.tfvars from example
cd infrastructure/local
cp terraform.tfvars.example terraform.tfvars

# Edit with secure values
vim terraform.tfvars

# Deploy with OpenTofu
./scripts/deploy.sh --tofu
```

**Pros:**
- Infrastructure-as-code best practices
- Version-controlled infrastructure (not secrets)
- Easy to replicate environments

**Cons:**
- Requires OpenTofu knowledge
- More complex setup

### Method 3: Environment Variables

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

### Method 4: Secrets Management Tools

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

# Or use pwgen
pwgen -s 32 1

# Or use /dev/urandom
tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 32
```

### JWT Secret

```bash
# Generate 64-character random secret
openssl rand -base64 64

# Or use uuidgen multiple times
echo "$(uuidgen)$(uuidgen)" | tr -d '-'
```

### Full Setup Script

```bash
#!/bin/bash
# generate-secrets.sh

cat > .env << EOF
POSTGRES_USER=dart_cloud
POSTGRES_PASSWORD=$(openssl rand -base64 32)
POSTGRES_DB=dart_cloud
POSTGRES_PORT=5432

BACKEND_PORT=8080
JWT_SECRET=$(openssl rand -base64 64)

FUNCTION_TIMEOUT_SECONDS=5
FUNCTION_MAX_MEMORY_MB=128
FUNCTION_MAX_CONCURRENT=10
EOF

chmod 600 .env
echo "✓ Secure .env file created"
```

## Security Best Practices

### File Permissions

```bash
# Secure .env file (owner read/write only)
chmod 600 .env

# Verify permissions
ls -la .env
# Should show: -rw------- (600)
```

### Git Protection

The `.gitignore` file already excludes:
- `.env`
- `*.tfvars` (except `.tfvars.example`)
- `terraform.tfstate`

**Verify before committing:**

```bash
# Check what will be committed
git status

# Ensure .env is not listed
git ls-files | grep -E '\.env$|\.tfvars$'
# Should return nothing
```

### Rotation Policy

**Rotate secrets regularly:**

1. **Development:** Every 90 days
2. **Production:** Every 30-60 days
3. **After breach:** Immediately

**Rotation process:**

```bash
# 1. Generate new secrets
NEW_PASSWORD=$(openssl rand -base64 32)
NEW_JWT=$(openssl rand -base64 64)

# 2. Update .env
sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$NEW_PASSWORD/" .env
sed -i "s/JWT_SECRET=.*/JWT_SECRET=$NEW_JWT/" .env

# 3. Redeploy
./scripts/deploy.sh --clean
```

### Container Security

**Never bake secrets into images:**

```dockerfile
# ❌ BAD - Don't do this
ENV POSTGRES_PASSWORD=hardcoded_password

# ✅ GOOD - Inject at runtime
# (no ENV for password in Dockerfile)
```

**Verify no secrets in images:**

```bash
# Inspect image environment
podman inspect containerpub-postgres:latest | grep -i password
# Should return nothing

# Check image history
podman history containerpub-postgres:latest
# Should not show passwords
```

## Environment-Specific Configuration

### Development

```bash
# .env.development
POSTGRES_PASSWORD=dev_password_not_for_production
JWT_SECRET=dev_secret_not_for_production
```

### Staging

```bash
# .env.staging
POSTGRES_PASSWORD=$(vault kv get -field=password secret/staging/postgres)
JWT_SECRET=$(vault kv get -field=jwt secret/staging/backend)
```

### Production

```bash
# .env.production
POSTGRES_PASSWORD=$(aws secretsmanager get-secret-value --secret-id prod/postgres --query SecretString --output text)
JWT_SECRET=$(aws secretsmanager get-secret-value --secret-id prod/jwt --query SecretString --output text)
```

## Verification

### Check Configuration

```bash
# Verify environment variables are loaded
./scripts/deploy.sh 2>&1 | grep "Loading environment"

# Should see: "✓ Environment variables loaded"
```

### Test Database Connection

```bash
# Connect with configured credentials
podman exec -it containerpub-postgres \
  psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT version();"
```

### Verify No Hardcoded Secrets

```bash
# Search codebase for potential hardcoded secrets
grep -r "password.*=" --include="*.tf" --include="*.sh" infrastructure/
grep -r "secret.*=" --include="*.tf" --include="*.sh" infrastructure/

# Should only find variable declarations, not values
```

## Troubleshooting

### "Authentication failed" Error

```bash
# Check if .env exists
ls -la .env

# Verify environment variables are set
echo $POSTGRES_PASSWORD
echo $JWT_SECRET

# Reload environment
source .env
```

### "Permission denied" on .env

```bash
# Fix permissions
chmod 600 .env

# Verify owner
ls -la .env
```

### Secrets Not Loading

```bash
# Check .env format (no spaces around =)
cat .env | grep "="

# Should be: KEY=value
# Not: KEY = value

# Test loading manually
set -a
source .env
set +a
echo $POSTGRES_PASSWORD
```

## Production Checklist

Before deploying to production:

- [ ] Generate strong, random passwords (32+ characters)
- [ ] Use secrets management tool (Vault, AWS Secrets Manager, etc.)
- [ ] Set `.env` file permissions to 600
- [ ] Verify `.env` is in `.gitignore`
- [ ] Never commit `.env` or `*.tfvars` files
- [ ] Use different secrets for each environment
- [ ] Enable audit logging for secret access
- [ ] Set up secret rotation schedule
- [ ] Document secret recovery procedures
- [ ] Test secret rotation process
- [ ] Enable SSL/TLS for database connections
- [ ] Use encrypted volumes for data at rest
- [ ] Implement network segmentation
- [ ] Set up monitoring and alerting
- [ ] Regular security audits

## Secret Storage Locations

### Local Development

```
~/.env                          # Project environment variables
~/.dart_cloud/config.json       # CLI authentication token
```

### OpenTofu State

```
infrastructure/local/terraform.tfstate    # Contains secrets! Secure this file
```

**Secure Terraform state:**

```bash
# Use remote backend for production
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "containerpub/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## Compliance

### GDPR / Data Protection

- Encrypt secrets at rest
- Implement access controls
- Maintain audit logs
- Regular security reviews

### SOC 2 / ISO 27001

- Document secret management procedures
- Implement least privilege access
- Regular penetration testing
- Incident response plan

## Additional Resources

- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [12-Factor App: Config](https://12factor.net/config)

## Support

For security issues:
1. **Do not** create public GitHub issues
2. Email security concerns privately
3. Follow responsible disclosure practices

---

**Remember:** Security is not a one-time setup. Regularly review and update your security practices.
