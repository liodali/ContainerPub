# ContainerPub Deployment Guide

Quick reference for deploying and managing ContainerPub infrastructure.

## Prerequisites

```bash
# macOS
brew install podman dart-sdk

# Start Podman machine
podman machine init
podman machine start
```

## Security Setup (Important!)

**Before deploying, configure your secrets:**

```bash
# 1. Copy environment template
cp .env.example .env

# 2. Generate secure passwords
openssl rand -base64 32  # For POSTGRES_PASSWORD
openssl rand -base64 64  # For JWT_SECRET

# 3. Edit .env with your secure values
nano .env

# 4. Secure the file
chmod 600 .env
```

**See [SECURITY.md](SECURITY.md) for detailed security configuration.**

## Quick Start

### 1. Deploy Infrastructure (One Command)

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy everything (automatically loads .env)
./scripts/deploy.sh
```

This will:
- ✓ Load environment variables from .env
- ✓ Build PostgreSQL image with initialization scripts
- ✓ Build backend image (compiled Dart executable)
- ✓ Create network and volumes
- ✓ Start containers with secure configuration
- ✓ Run health checks

**Access:**
- Backend: http://localhost:8080 (or your BACKEND_PORT)
- PostgreSQL: localhost:5432 (or your POSTGRES_PORT)

**Note:** If `.env` file is not found, development defaults will be used (not secure for production!)

### 2. Install CLI

```bash
# Install globally
./scripts/install-cli.sh

# Add to PATH (if needed)
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc
source ~/.zshrc
```

### 3. Use CLI

```bash
# Login
dart_cloud login

# Deploy a function
dart_cloud deploy ./examples/hello-world

# List functions
dart_cloud list

# Invoke function
dart_cloud invoke <function-id>

# View logs
dart_cloud logs <function-id>

# Logout
dart_cloud logout
```

## Common Commands

### Infrastructure Management

```bash
# View running containers
podman ps

# View logs
podman logs -f containerpub-backend
podman logs -f containerpub-postgres

# Stop services
podman stop containerpub-backend containerpub-postgres

# Start services
podman start containerpub-postgres containerpub-backend

# Restart a service
podman restart containerpub-backend

# Remove everything
podman stop containerpub-backend containerpub-postgres
podman rm containerpub-backend containerpub-postgres
podman volume rm containerpub-postgres-data containerpub-functions-data
podman network rm containerpub-network
```

### Rebuild After Changes

```bash
# Rebuild backend only
./scripts/deploy.sh --backend-only --clean

# Rebuild database only
./scripts/deploy.sh --postgres-only --clean

# Rebuild everything
./scripts/deploy.sh --clean
```

### Database Access

```bash
# Connect to PostgreSQL
podman exec -it containerpub-postgres psql -U dart_cloud -d dart_cloud

# Run SQL query
podman exec containerpub-postgres psql -U dart_cloud -d dart_cloud -c "SELECT * FROM users;"

# Backup database
podman exec containerpub-postgres pg_dump -U dart_cloud dart_cloud > backup.sql

# Restore database
cat backup.sql | podman exec -i containerpub-postgres psql -U dart_cloud -d dart_cloud
```

## Deployment Options

### Option 1: Manual Podman (Default)

```bash
./scripts/deploy.sh
```

Directly uses Podman commands. Best for:
- Quick local development
- Testing changes
- Simple setups

### Option 2: OpenTofu/Terraform

```bash
# Install OpenTofu
brew install opentofu

# Deploy with OpenTofu
./scripts/deploy.sh --tofu
```

Uses infrastructure-as-code. Best for:
- Reproducible deployments
- Version-controlled infrastructure
- Team environments

## CLI Authentication

### Login Flow

```bash
$ dart_cloud login
Email: user@example.com
Password: ********

Authenticating...
✓ Successfully logged in!
```

**Token stored in:** `~/.dart_cloud/config.json`

### Logout Flow

```bash
$ dart_cloud logout
Logging out...
✓ Successfully logged out!
Your authentication token has been removed.
```

### Manual Token Management

```bash
# View current config
cat ~/.dart_cloud/config.json

# Manually clear token
rm ~/.dart_cloud/config.json

# Set custom server URL
echo '{"serverUrl": "http://localhost:9000"}' > ~/.dart_cloud/config.json
```

## Troubleshooting

### Container Issues

**Container won't start:**
```bash
# Check logs
podman logs containerpub-backend

# Check if port is in use
lsof -i :8080

# Restart container
podman restart containerpub-backend
```

**Database connection failed:**
```bash
# Check PostgreSQL is running
podman ps | grep postgres

# Test connection
podman exec containerpub-postgres pg_isready -U dart_cloud

# Check network
podman network inspect containerpub-network
```

**Out of disk space:**
```bash
# Clean up unused images
podman image prune -a

# Clean up unused volumes
podman volume prune

# Check disk usage
podman system df
```

### CLI Issues

**Command not found:**
```bash
# Check installation
which dart_cloud

# Reinstall
./scripts/install-cli.sh

# Add to PATH
export PATH="$PATH:$HOME/.local/bin"
```

**Authentication failed:**
```bash
# Clear old token
dart_cloud logout

# Login again
dart_cloud login

# Check server is running
curl http://localhost:8080/api/health
```

**Connection refused:**
```bash
# Check backend is running
podman ps | grep backend

# Check backend logs
podman logs containerpub-backend

# Restart backend
podman restart containerpub-backend
```

## Configuration

### Environment Variables

Create `.env` file in project root:

```bash
# Database
POSTGRES_USER=dart_cloud
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=dart_cloud

# Backend
PORT=8080
JWT_SECRET=your-secret-key-here

# Functions
FUNCTION_TIMEOUT_SECONDS=5
FUNCTION_MAX_MEMORY_MB=128
FUNCTION_MAX_CONCURRENT=10
```

### Custom Ports

Edit `infrastructure/local/local-podman.tf`:

```hcl
variable "backend_port" {
  default = 9000  # Change from 8080
}

variable "postgres_port" {
  default = 5433  # Change from 5432
}
```

Then redeploy:
```bash
./scripts/deploy.sh --tofu
```

## Production Deployment

⚠️ **Do not use default configuration in production!**

### Security Checklist

- [ ] Change default passwords
- [ ] Use strong JWT secret (32+ random characters)
- [ ] Enable SSL/TLS
- [ ] Set up firewall rules
- [ ] Use secrets management (Vault, AWS Secrets Manager)
- [ ] Enable audit logging
- [ ] Set up monitoring and alerts
- [ ] Configure backups
- [ ] Use non-root users
- [ ] Scan images for vulnerabilities

### Production Environment Variables

```bash
# Use strong, random values
POSTGRES_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 32)

# Use production database
DATABASE_URL=postgres://user:pass@prod-db:5432/containerpub

# Restrict resources
FUNCTION_TIMEOUT_SECONDS=3
FUNCTION_MAX_MEMORY_MB=64
FUNCTION_MAX_CONCURRENT=5
```

## Monitoring

### Health Checks

```bash
# Backend health
curl http://localhost:8080/api/health

# Database health
podman exec containerpub-postgres pg_isready -U dart_cloud
```

### Metrics

```bash
# Container stats
podman stats

# Specific container
podman stats containerpub-backend

# Disk usage
podman system df
```

### Logs

```bash
# Follow logs
podman logs -f containerpub-backend

# Last 100 lines
podman logs --tail 100 containerpub-backend

# Since timestamp
podman logs --since 2024-01-01T00:00:00 containerpub-backend

# Save logs to file
podman logs containerpub-backend > backend.log
```

## Backup and Restore

### Database Backup

```bash
# Full backup
podman exec containerpub-postgres pg_dump -U dart_cloud dart_cloud > backup-$(date +%Y%m%d).sql

# Compressed backup
podman exec containerpub-postgres pg_dump -U dart_cloud dart_cloud | gzip > backup-$(date +%Y%m%d).sql.gz

# All databases
podman exec containerpub-postgres pg_dumpall -U dart_cloud > full-backup-$(date +%Y%m%d).sql
```

### Database Restore

```bash
# Restore from backup
cat backup.sql | podman exec -i containerpub-postgres psql -U dart_cloud -d dart_cloud

# Restore compressed backup
gunzip -c backup.sql.gz | podman exec -i containerpub-postgres psql -U dart_cloud -d dart_cloud
```

### Volume Backup

```bash
# Backup volume to tar
podman volume export containerpub-postgres-data > postgres-data-backup.tar

# Restore volume from tar
podman volume import containerpub-postgres-data < postgres-data-backup.tar
```

## Useful Links

- **Scripts Documentation:** [scripts/README.md](scripts/README.md)
- **Infrastructure Config:** [infrastructure/local/README.md](infrastructure/local/README.md)
- **Podman Docs:** https://docs.podman.io/
- **OpenTofu Docs:** https://opentofu.org/docs/
- **Dart SDK:** https://dart.dev/

## Support

For issues or questions:
1. Check logs: `podman logs containerpub-backend`
2. Review documentation in `docs/` directory
3. Check GitHub issues
4. Run health checks: `curl http://localhost:8080/api/health`
