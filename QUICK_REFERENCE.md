# ContainerPub Quick Reference

## 🚀 Quick Start (3 Commands)

```bash
make secrets      # Generate secure passwords
make deploy       # Deploy infrastructure
make install-cli  # Install CLI tool
```

## 🔐 Security Setup

```bash
# Generate secure secrets
./scripts/generate-secrets.sh

# Or manually
cp .env.example .env
openssl rand -base64 32  # For passwords
openssl rand -base64 64  # For JWT secret
nano .env
chmod 600 .env
```

## 📦 Deployment

```bash
# Full deployment
./scripts/deploy.sh

# Backend only
./scripts/deploy.sh --backend-only

# Clean deployment (removes data)
./scripts/deploy.sh --clean

# With OpenTofu
./scripts/deploy.sh --tofu
```

## 🛠️ CLI Installation

```bash
# Install globally
./scripts/install-cli.sh

# Development mode
./scripts/install-cli.sh --dev

# Uninstall
./scripts/install-cli.sh --uninstall
```

## 💻 CLI Usage

```bash
# Authentication
dart_cloud login          # Login
dart_cloud logout         # Logout

# Function management
dart_cloud deploy ./fn    # Deploy function
dart_cloud list           # List functions
dart_cloud logs <id>      # View logs
dart_cloud invoke <id>    # Invoke function
dart_cloud delete <id>    # Delete function

# Help
dart_cloud --help         # Show help
dart_cloud --version      # Show version
```

## 🐳 Container Management

```bash
# View status
podman ps

# View logs
podman logs -f containerpub-backend
podman logs -f containerpub-postgres

# Restart
podman restart containerpub-backend

# Stop/Start
podman stop containerpub-backend containerpub-postgres
podman start containerpub-postgres containerpub-backend

# Remove
podman rm -f containerpub-backend containerpub-postgres
podman volume rm containerpub-postgres-data containerpub-functions-data
```

## 🗄️ Database

```bash
# Connect to database
podman exec -it containerpub-postgres psql -U dart_cloud -d dart_cloud

# Run query
podman exec containerpub-postgres psql -U dart_cloud -d dart_cloud -c "SELECT * FROM users;"

# Backup
podman exec containerpub-postgres pg_dump -U dart_cloud dart_cloud > backup.sql

# Restore
cat backup.sql | podman exec -i containerpub-postgres psql -U dart_cloud -d dart_cloud
```

## 🔧 Make Commands

```bash
make help             # Show all commands
make secrets          # Generate secrets
make deploy           # Deploy infrastructure
make deploy-clean     # Clean deployment
make install-cli      # Install CLI
make full-setup       # Complete setup (secrets + deploy + CLI)

make start-db         # Start PostgreSQL
make stop-db          # Stop PostgreSQL
make start-backend    # Start backend (dev mode)

make podman-build     # Build images
make podman-up        # Start with podman-compose
make podman-down      # Stop containers

make tofu-init        # Initialize OpenTofu
make tofu-apply       # Apply infrastructure
make tofu-destroy     # Destroy infrastructure

make clean            # Clean test data
make clean-all        # Clean everything
```

## 📍 Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Backend API | http://localhost:8080 | - |
| PostgreSQL | localhost:5432 | See .env file |
| Health Check | http://localhost:8080/api/health | - |

## 📁 Important Files

| File | Purpose |
|------|---------|
| `.env` | Environment variables (secrets) |
| `.env.example` | Template for .env |
| `infrastructure/Dockerfile.backend` | Backend container image |
| `infrastructure/Dockerfile.postgres` | PostgreSQL container image |
| `infrastructure/local/local-podman.tf` | OpenTofu configuration |
| `scripts/deploy.sh` | Deployment automation |
| `scripts/install-cli.sh` | CLI installation |
| `scripts/generate-secrets.sh` | Secret generation |

## 🔍 Troubleshooting

### Container won't start
```bash
podman logs containerpub-backend
podman logs containerpub-postgres
```

### Port already in use
```bash
lsof -i :8080
lsof -i :5432
```

### Authentication failed
```bash
dart_cloud logout
dart_cloud login
```

### Database connection failed
```bash
podman exec containerpub-postgres pg_isready -U dart_cloud
podman restart containerpub-postgres
```

### Secrets not loading
```bash
ls -la .env
source .env
echo $POSTGRES_PASSWORD
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [SECURITY.md](SECURITY.md) | Security configuration guide |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Deployment quick reference |
| [SECURITY_SETUP_SUMMARY.md](SECURITY_SETUP_SUMMARY.md) | Security changes summary |
| [scripts/README.md](scripts/README.md) | Scripts documentation |
| [infrastructure/DOCKER_SETUP.md](infrastructure/DOCKER_SETUP.md) | Architecture details |
| [infrastructure/local/README.md](infrastructure/local/README.md) | OpenTofu guide |

## 🔐 Security Checklist

- [ ] Generated secure secrets with `make secrets`
- [ ] Set `.env` permissions to 600
- [ ] Verified `.env` is in `.gitignore`
- [ ] Never committed `.env` to Git
- [ ] Using different secrets per environment
- [ ] Rotated secrets regularly
- [ ] Backed up `.env` securely

## 🎯 Common Workflows

### First Time Setup
```bash
make secrets          # Generate secrets
make deploy           # Deploy infrastructure
make install-cli      # Install CLI
dart_cloud login      # Login
```

### Daily Development
```bash
make start-db         # Start database
make start-backend    # Start backend
# Make changes
podman restart containerpub-backend
```

### Rebuild After Changes
```bash
make deploy-backend   # Rebuild backend only
make deploy-clean     # Full clean rebuild
```

### Production Deployment
```bash
# 1. Generate production secrets
./scripts/generate-secrets.sh

# 2. Edit .env with production values
nano .env

# 3. Deploy
./scripts/deploy.sh

# 4. Verify
curl http://localhost:8080/api/health
```

## 💡 Tips

- Use `make full-setup` for complete first-time setup
- Always run `make secrets` before deploying
- Check logs with `podman logs -f <container>`
- Use `make deploy-clean` to start fresh
- Keep `.env` file permissions at 600
- Never commit `.env` or `*.tfvars` files
- Rotate secrets regularly (every 30-90 days)
- Use different secrets for dev/staging/prod

## 🆘 Emergency Commands

```bash
# Stop everything
podman stop $(podman ps -aq)

# Remove all containers
podman rm -f $(podman ps -aq)

# Remove all volumes (⚠️ DATA LOSS)
podman volume rm $(podman volume ls -q)

# Clean everything
make clean-all

# Start fresh
make secrets && make deploy
```

## 📞 Getting Help

```bash
# Script help
./scripts/deploy.sh --help
./scripts/install-cli.sh --help

# CLI help
dart_cloud --help

# Make help
make help

# Check status
make status
```

---

**Quick Links:**
- [Full Documentation](README.md)
- [Security Guide](SECURITY.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Scripts Documentation](scripts/README.md)
