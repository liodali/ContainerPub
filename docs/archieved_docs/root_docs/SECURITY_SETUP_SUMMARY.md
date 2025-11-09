# Security Setup Summary

## What Was Changed

Your ContainerPub infrastructure has been refactored to follow security best practices by removing hardcoded secrets and implementing runtime secret injection.

### 🔒 Security Improvements

1. **Removed Hardcoded Secrets**
   - `Dockerfile.postgres` - No longer contains `POSTGRES_PASSWORD`
   - `local-podman.tf` - Removed default values for sensitive variables
   - All secrets now injected at runtime

2. **Environment-Based Configuration**
   - `.env` file for local development
   - `terraform.tfvars` for OpenTofu deployments
   - Environment variables for CI/CD
   - Support for secrets management tools

3. **Git Protection**
   - `.env` excluded from version control
   - `*.tfvars` excluded (except examples)
   - Terraform state files excluded

4. **Automated Secret Generation**
   - New `generate-secrets.sh` script
   - Uses cryptographically secure random generation
   - Automatic file permission setting (chmod 600)

## Files Modified

### Infrastructure Files

1. **`infrastructure/Dockerfile.postgres`**
   - Removed: `ENV POSTGRES_PASSWORD=dev_password`
   - Now: Password injected via `-e` flag at runtime

2. **`infrastructure/local/local-podman.tf`**
   - Removed: Default values for `postgres_password` and `jwt_secret`
   - Now: Must be provided via `.tfvars` or environment variables

### Deployment Scripts

3. **`scripts/deploy.sh`**
   - Added: `load_env()` function to load `.env` file
   - Updated: All `podman run` commands use environment variables
   - Updated: OpenTofu deployment exports TF_VAR_* variables
   - Fallback: Uses safe defaults if `.env` not found (with warning)

### Configuration Files

4. **`.env.example`**
   - Created: Template for environment variables
   - Contains: All required configuration options
   - Includes: Instructions for generating secure values

5. **`infrastructure/local/terraform.tfvars.example`**
   - Created: Template for OpenTofu variables
   - Contains: All required Terraform variables
   - Includes: Security notes

6. **`.gitignore`**
   - Added: `.env` files
   - Added: `*.tfvars` files (except examples)
   - Added: Terraform state files

### New Scripts

7. **`scripts/generate-secrets.sh`**
   - Purpose: Generate secure random passwords
   - Creates: `.env` file with secure configuration
   - Sets: Proper file permissions (600)
   - Backs up: Existing `.env` if found

### Documentation

8. **`SECURITY.md`**
   - Comprehensive security guide
   - Multiple configuration methods
   - Best practices and compliance
   - Troubleshooting section

9. **`DEPLOYMENT.md`**
   - Updated: Added security setup section
   - Updated: Deployment instructions mention `.env`

10. **`scripts/README.md`**
    - Added: `generate-secrets.sh` documentation
    - Updated: Deployment workflow includes secrets

11. **`Makefile`**
    - Added: `make secrets` target
    - Updated: `make full-setup` includes secrets generation
    - Updated: `make start-db` loads `.env`

## How to Use

### Quick Start (Recommended)

```bash
# 1. Generate secure secrets
make secrets

# 2. Deploy infrastructure
make deploy

# 3. Install CLI
make install-cli
```

### Manual Setup

```bash
# 1. Generate secrets
./scripts/generate-secrets.sh

# 2. Review and edit if needed
nano .env

# 3. Deploy
./scripts/deploy.sh
```

### OpenTofu Deployment

```bash
# 1. Create terraform.tfvars
cd infrastructure/local
cp terraform.tfvars.example terraform.tfvars

# 2. Edit with secure values
nano terraform.tfvars

# 3. Deploy with OpenTofu
./scripts/deploy.sh --tofu
```

## Security Features

### ✅ What's Secure Now

- **No secrets in version control** - All sensitive data excluded
- **Runtime injection** - Secrets provided at container start
- **Secure file permissions** - `.env` set to 600 (owner only)
- **Random generation** - Cryptographically secure passwords
- **Flexible configuration** - Multiple methods supported
- **Audit trail** - Environment loading logged
- **Fallback safety** - Warns if using defaults

### ⚠️ What You Need to Do

1. **Generate secrets** before deploying
2. **Secure .env file** (chmod 600)
3. **Never commit** `.env` or `*.tfvars`
4. **Rotate secrets** regularly
5. **Use different secrets** per environment
6. **Backup .env** securely (encrypted)

## Configuration Methods

### Method 1: .env File (Local Development)

```bash
# Generate
./scripts/generate-secrets.sh

# Or manually create
cp .env.example .env
nano .env

# Deploy
./scripts/deploy.sh
```

**Pros:** Simple, automatic loading
**Cons:** File-based, must secure permissions

### Method 2: Environment Variables (CI/CD)

```bash
# Set variables
export POSTGRES_PASSWORD="secure_password"
export JWT_SECRET="long_random_secret"

# Deploy
./scripts/deploy.sh
```

**Pros:** No files, perfect for automation
**Cons:** Lost when session ends

### Method 3: Terraform Variables (IaC)

```bash
# Create terraform.tfvars
cp infrastructure/local/terraform.tfvars.example infrastructure/local/terraform.tfvars

# Edit
nano infrastructure/local/terraform.tfvars

# Deploy
./scripts/deploy.sh --tofu
```

**Pros:** Infrastructure-as-code, version-controlled structure
**Cons:** More complex, requires OpenTofu knowledge

### Method 4: Secrets Manager (Production)

```bash
# Example with AWS Secrets Manager
export POSTGRES_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id prod/postgres --query SecretString --output text)

# Deploy
./scripts/deploy.sh
```

**Pros:** Enterprise-grade, audit logs, rotation
**Cons:** Requires cloud provider, additional cost

## Verification

### Check Configuration

```bash
# Verify .env exists
ls -la .env

# Should show: -rw------- (600 permissions)

# Check what will be loaded (without exposing values)
grep -v "PASSWORD\|SECRET" .env
```

### Test Deployment

```bash
# Deploy and watch for environment loading
./scripts/deploy.sh 2>&1 | grep -i "environment"

# Should see: "✓ Environment variables loaded"
```

### Verify No Secrets in Git

```bash
# Check git status
git status

# Verify .env is ignored
git check-ignore .env
# Should output: .env

# Search for potential leaks
git log -p | grep -i "password.*=" | grep -v "POSTGRES_PASSWORD="
# Should return nothing
```

## Migration from Old Setup

If you had the old setup with hardcoded secrets:

```bash
# 1. Generate new secrets
./scripts/generate-secrets.sh

# 2. Clean old deployment
./scripts/deploy.sh --clean

# 3. Deploy with new secrets
./scripts/deploy.sh

# 4. Update any saved credentials
# (CLI, database clients, etc.)
```

## Environment Variables Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_USER` | Database username | `dart_cloud` |
| `POSTGRES_PASSWORD` | Database password | `[generated]` |
| `POSTGRES_DB` | Database name | `dart_cloud` |
| `JWT_SECRET` | JWT signing secret | `[generated]` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_PORT` | `5432` | PostgreSQL port |
| `BACKEND_PORT` | `8080` | Backend API port |
| `FUNCTION_TIMEOUT_SECONDS` | `5` | Function timeout |
| `FUNCTION_MAX_MEMORY_MB` | `128` | Max memory per function |
| `FUNCTION_MAX_CONCURRENT` | `10` | Max concurrent executions |

## Troubleshooting

### "Environment variables not loaded"

```bash
# Check if .env exists
ls -la .env

# Verify format (no spaces around =)
cat .env | grep "="

# Reload manually
source .env
```

### "Permission denied" on .env

```bash
# Fix permissions
chmod 600 .env

# Verify
ls -la .env
```

### "Secrets in Git history"

```bash
# If you accidentally committed secrets:
# 1. Rotate all secrets immediately
./scripts/generate-secrets.sh

# 2. Clean Git history (use with caution!)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .env' \
  --prune-empty --tag-name-filter cat -- --all

# 3. Force push (if remote)
git push origin --force --all
```

## Best Practices

### Development

- ✅ Use `generate-secrets.sh` for local setup
- ✅ Keep `.env` file permissions at 600
- ✅ Don't share `.env` via chat/email
- ✅ Use different secrets than production

### Production

- ✅ Use secrets management tool (Vault, AWS, etc.)
- ✅ Rotate secrets every 30-60 days
- ✅ Use strong, random passwords (32+ chars)
- ✅ Enable audit logging
- ✅ Implement least privilege access
- ✅ Regular security audits

### Team Collaboration

- ✅ Share `.env.example`, not `.env`
- ✅ Document secret rotation procedures
- ✅ Use different secrets per developer
- ✅ Implement secret approval workflows
- ✅ Regular security training

## Next Steps

1. **Review SECURITY.md** - Comprehensive security guide
2. **Generate secrets** - Run `make secrets`
3. **Deploy infrastructure** - Run `make deploy`
4. **Test deployment** - Verify everything works
5. **Document procedures** - For your team
6. **Plan rotation** - Schedule regular updates
7. **Monitor access** - Set up logging and alerts

## Support

For security questions:
- Review: [SECURITY.md](SECURITY.md)
- Check: [DEPLOYMENT.md](DEPLOYMENT.md)
- Read: [scripts/README.md](scripts/README.md)

**Remember:** Security is an ongoing process, not a one-time setup!
