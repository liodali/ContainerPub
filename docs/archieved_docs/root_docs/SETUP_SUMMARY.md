# ContainerPub Setup Summary

## What Was Created

This setup provides complete Docker/Podman infrastructure and CLI tooling for ContainerPub.

### 📦 Docker Images

1. **Backend Image** (`infrastructure/Dockerfile.backend`)
   - Multi-stage build with Dart 3.9.2
   - Compiled native executable
   - Debian slim runtime (~150MB)
   - Built-in health checks

2. **PostgreSQL Image** (`infrastructure/Dockerfile.postgres`)
   - PostgreSQL 15 Alpine base
   - Automatic database initialization
   - Pre-configured schemas and tables
   - Health monitoring

### 🗄️ Database Setup

**File:** `infrastructure/postgres/init/01-init-databases.sql`

**Creates:**
- `dart_cloud` database (main app)
- `functions_db` database (function storage)
- Complete schema with tables, indexes, triggers
- User permissions and security

**Tables:**
- `users` - Authentication and user management
- `functions` - Function metadata and code
- `function_logs` - Execution logs
- `function_data` - Key-value storage

### 🚀 Deployment Scripts

1. **`scripts/deploy.sh`** - Infrastructure deployment
   - Builds Docker images
   - Creates networks and volumes
   - Starts containers
   - Runs health checks
   - Supports OpenTofu integration

2. **`scripts/install-cli.sh`** - CLI installation
   - Compiles Dart CLI to native binary
   - Installs globally
   - Manages PATH configuration
   - Supports dev mode

### 🔧 CLI Enhancements

**New Command:** `dart_cloud logout`
- Clears authentication token
- Removes config file
- Secure token management

**Updated:** `dart_cloud_cli/bin/main.dart`
- Added logout command
- Updated help text
- Integrated with config system

### 📚 Documentation

1. **`DEPLOYMENT.md`** - Quick reference guide
2. **`scripts/README.md`** - Script documentation
3. **`infrastructure/DOCKER_SETUP.md`** - Architecture details
4. **`infrastructure/local/README.md`** - OpenTofu guide (existing)

### ⚙️ Configuration

**`.dockerignore`** - Optimizes Docker builds
- Excludes unnecessary files
- Reduces image size
- Improves security

## Quick Start

### 1. Deploy Infrastructure (One Command)

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy everything
./scripts/deploy.sh
```

**What happens:**
- ✓ Builds backend image (Dart compiled)
- ✓ Builds PostgreSQL image (with init scripts)
- ✓ Creates network (10.89.0.0/24)
- ✓ Creates volumes (postgres_data, functions_data)
- ✓ Starts PostgreSQL container
- ✓ Waits for database to be ready
- ✓ Starts backend container
- ✓ Verifies health checks
- ✓ Shows access information

**Access:**
- Backend API: http://localhost:8080
- PostgreSQL: localhost:5432
- Database: dart_cloud / dart_cloud / dev_password

### 2. Install CLI

```bash
# Install globally
./scripts/install-cli.sh

# Add to PATH if needed
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
dart_cloud --version
```

### 3. Use the CLI

```bash
# Login
dart_cloud login
# Enter: email and password

# Deploy a function
cd examples/hello-world
dart_cloud deploy .

# List functions
dart_cloud list

# Invoke function
dart_cloud invoke <function-id>

# View logs
dart_cloud logs <function-id>

# Logout
dart_cloud logout
```

## Architecture

```
┌─────────────────────────────────────────┐
│         Host Machine (macOS)            │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  containerpub-network             │ │
│  │  (10.89.0.0/24)                   │ │
│  │                                   │ │
│  │  ┌─────────┐      ┌───────────┐  │ │
│  │  │ Backend │─────▶│PostgreSQL │  │ │
│  │  │  :8080  │      │   :5432   │  │ │
│  │  └─────────┘      └───────────┘  │ │
│  │      │                  │         │ │
│  │  ┌───▼───┐         ┌───▼────┐    │ │
│  │  │funcs  │         │postgres│    │ │
│  │  │volume │         │ volume │    │ │
│  │  └───────┘         └────────┘    │ │
│  └───────────────────────────────────┘ │
│         │                  │            │
└─────────┼──────────────────┼────────────┘
          │                  │
     localhost:8080    localhost:5432
          │
          │
     ┌────▼─────┐
     │   CLI    │
     │ (Native) │
     │  Binary  │
     └──────────┘
```

## Key Features

### 🔒 Security
- Token-based authentication (JWT)
- Secure password storage (bcrypt)
- Isolated container network
- Config stored in user home directory
- Sensitive values marked in OpenTofu

### 📊 Monitoring
- Built-in health checks
- Container status monitoring
- Log aggregation
- Resource usage tracking

### 💾 Data Persistence
- PostgreSQL volume (survives restarts)
- Functions volume (code storage)
- Automatic backups supported

### 🔄 Development Workflow
- Hot reload support
- Easy rebuild scripts
- Dev mode for CLI
- Local testing environment

## Common Commands

### Infrastructure

```bash
# View status
podman ps

# View logs
podman logs -f containerpub-backend
podman logs -f containerpub-postgres

# Restart services
podman restart containerpub-backend

# Stop all
podman stop containerpub-backend containerpub-postgres

# Start all
podman start containerpub-postgres containerpub-backend

# Clean rebuild
./scripts/deploy.sh --clean
```

### CLI

```bash
# Login/Logout
dart_cloud login
dart_cloud logout

# Function management
dart_cloud deploy ./my_function
dart_cloud list
dart_cloud logs <id>
dart_cloud invoke <id> --data '{"key": "value"}'
dart_cloud delete <id>

# Help
dart_cloud --help
dart_cloud --version
```

### Database

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

## Deployment Options

### Option 1: Manual Podman (Default)

```bash
./scripts/deploy.sh
```

**Best for:**
- Quick local development
- Testing changes
- Simple setups

### Option 2: OpenTofu/Terraform

```bash
./scripts/deploy.sh --tofu
```

**Best for:**
- Reproducible deployments
- Version-controlled infrastructure
- Team environments
- Production-like setups

## File Structure

```
ContainerPub/
├── infrastructure/
│   ├── Dockerfile.backend          # Backend container image
│   ├── Dockerfile.postgres         # PostgreSQL container image
│   ├── DOCKER_SETUP.md            # Architecture documentation
│   ├── postgres/
│   │   └── init/
│   │       └── 01-init-databases.sql  # Database initialization
│   └── local/
│       ├── local-podman.tf        # OpenTofu configuration
│       └── README.md              # OpenTofu guide
├── scripts/
│   ├── deploy.sh                  # Deployment automation
│   ├── install-cli.sh             # CLI installation
│   └── README.md                  # Scripts documentation
├── dart_cloud_cli/
│   ├── bin/main.dart              # CLI entry point (updated)
│   └── lib/commands/
│       └── logout_command.dart    # New logout command
├── .dockerignore                  # Docker build optimization
├── DEPLOYMENT.md                  # Quick reference guide
└── SETUP_SUMMARY.md              # This file
```

## Configuration Files

### CLI Config (`~/.dart_cloud/config.json`)

```json
{
  "authToken": "eyJhbGc...",
  "serverUrl": "http://localhost:8080"
}
```

### Environment Variables

**Backend:**
- `PORT=8080`
- `DATABASE_URL=postgres://...`
- `JWT_SECRET=...`
- Function execution limits

**PostgreSQL:**
- `POSTGRES_USER=dart_cloud`
- `POSTGRES_PASSWORD=dev_password`
- `POSTGRES_DB=dart_cloud`

## Troubleshooting

### "Cannot connect to Podman socket"
```bash
podman machine start
```

### "Port already in use"
```bash
# Find what's using the port
lsof -i :8080

# Stop conflicting service
podman stop <container-name>
```

### "CLI command not found"
```bash
# Add to PATH
export PATH="$PATH:$HOME/.local/bin"

# Or reinstall
./scripts/install-cli.sh
```

### "Authentication failed"
```bash
# Clear token and login again
dart_cloud logout
dart_cloud login
```

### "Database connection failed"
```bash
# Check PostgreSQL is running
podman ps | grep postgres

# Check logs
podman logs containerpub-postgres

# Restart
podman restart containerpub-postgres
```

## Next Steps

### 1. Test the Setup

```bash
# Deploy infrastructure
./scripts/deploy.sh

# Install CLI
./scripts/install-cli.sh

# Test health
curl http://localhost:8080/api/health

# Test CLI
dart_cloud --version
```

### 2. Create First User

```bash
# You'll need to implement user registration
# Or manually insert into database:
podman exec -it containerpub-postgres psql -U dart_cloud -d dart_cloud
```

### 3. Deploy Example Function

```bash
dart_cloud login
cd examples/hello-world
dart_cloud deploy .
dart_cloud list
```

### 4. Monitor and Maintain

```bash
# Check logs regularly
podman logs -f containerpub-backend

# Monitor resources
podman stats

# Backup database
podman exec containerpub-postgres pg_dump -U dart_cloud dart_cloud > backup.sql
```

## Production Checklist

Before deploying to production:

- [ ] Change default passwords
- [ ] Use strong JWT secret (32+ chars)
- [ ] Enable SSL/TLS
- [ ] Set up secrets management
- [ ] Configure firewall rules
- [ ] Enable audit logging
- [ ] Set up monitoring and alerts
- [ ] Configure automated backups
- [ ] Scan images for vulnerabilities
- [ ] Set resource limits
- [ ] Use non-root users
- [ ] Enable CORS restrictions
- [ ] Set up rate limiting
- [ ] Configure log rotation
- [ ] Plan disaster recovery

## Resources

### Documentation
- [Deployment Guide](DEPLOYMENT.md)
- [Scripts Documentation](scripts/README.md)
- [Docker Setup](infrastructure/DOCKER_SETUP.md)
- [OpenTofu Guide](infrastructure/local/README.md)

### External Links
- [Podman Documentation](https://docs.podman.io/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Dart SDK](https://dart.dev/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## Support

For issues:
1. Check container logs: `podman logs <container-name>`
2. Review documentation in `docs/` directory
3. Check health endpoints
4. Review this setup guide
5. Check GitHub issues

## Summary

You now have:
- ✅ Complete Docker/Podman infrastructure
- ✅ Automated deployment scripts
- ✅ CLI with authentication management
- ✅ Database with automatic initialization
- ✅ Comprehensive documentation
- ✅ Development and production workflows
- ✅ Monitoring and maintenance tools

**Start developing:**
```bash
./scripts/deploy.sh && ./scripts/install-cli.sh
```

Happy coding! 🚀
