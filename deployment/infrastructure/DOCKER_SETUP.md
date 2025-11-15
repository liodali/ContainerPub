# Docker/Podman Setup for ContainerPub

This document explains the Docker/Podman infrastructure setup for ContainerPub.

## Files Created

### 1. Dockerfiles

#### `infrastructure/Dockerfile.backend`
Multi-stage Dockerfile for the Dart backend:
- **Build stage:** Compiles Dart code to native executable
- **Runtime stage:** Minimal Debian slim image
- **Size optimized:** Only includes compiled binary and runtime dependencies
- **Health check:** Built-in endpoint monitoring

**Features:**
- Native compilation for better performance
- Minimal attack surface
- Fast startup time
- Automatic health checks

#### `infrastructure/Dockerfile.postgres`
Custom PostgreSQL image with initialization:
- **Base:** PostgreSQL 15 Alpine (minimal size)
- **Initialization:** Automatic database setup on first run
- **Health check:** pg_isready monitoring
- **Persistent storage:** Volume mount support

**Features:**
- Pre-configured databases (dart_cloud, functions_db)
- Automatic schema creation
- User and permissions setup
- Health monitoring

### 2. Database Initialization

#### `infrastructure/postgres/init/01-init-databases.sql`
SQL initialization script that runs on first container start:

**Creates:**
- `dart_cloud` database - Main application database
- `functions_db` database - Function-specific data storage

**Tables:**
- `users` - User accounts with authentication
- `functions` - Deployed function metadata
- `function_logs` - Function execution logs
- `function_data` - Key-value storage for functions

**Features:**
- Automatic UUID generation
- Timestamps with auto-update triggers
- Proper indexes for performance
- Foreign key constraints
- JSONB support for flexible data

### 3. Deployment Scripts

#### `scripts/deploy.sh`
Comprehensive deployment automation:

**Capabilities:**
- Build Docker images
- Create networks and volumes
- Start containers with proper configuration
- Health check verification
- Clean deployment option
- OpenTofu integration

**Options:**
```bash
--backend-only    # Deploy only backend
--postgres-only   # Deploy only database
--clean          # Remove existing data
--tofu           # Use OpenTofu
--no-build       # Skip image building
--no-start       # Build but don't start
```

**What it does:**
1. Checks dependencies (Podman, OpenTofu)
2. Builds optimized container images
3. Creates isolated network (10.89.0.0/24)
4. Creates persistent volumes
5. Starts containers in correct order
6. Waits for services to be healthy
7. Displays access information

#### `scripts/install-cli.sh`
CLI installation automation:

**Capabilities:**
- Compile Dart CLI to native binary
- Install globally on system
- Development mode support
- Uninstall support
- PATH configuration help

**Options:**
```bash
--dev            # Development mode (dart pub global)
--uninstall      # Remove CLI
--path <dir>     # Custom install directory
```

**What it does:**
1. Checks Dart SDK installation
2. Downloads dependencies
3. Compiles to native executable
4. Installs to ~/.local/bin
5. Verifies installation
6. Shows usage examples

### 4. CLI Enhancements

#### `dart_cloud_cli/lib/commands/logout_command.dart`
New logout command for CLI:

**Features:**
- Clears authentication token
- Removes config file
- Confirms logout success
- Handles errors gracefully

**Usage:**
```bash
dart_cloud logout
```

**Updated main.dart:**
- Added logout command handler
- Updated help text
- Integrated with config management

### 5. Configuration Files

#### `.dockerignore`
Optimizes Docker builds by excluding:
- Git files
- Documentation
- IDE files
- Test files
- Build artifacts
- Other Dart projects
- Environment files

**Benefits:**
- Faster builds
- Smaller images
- Better security
- Cleaner context

### 6. Documentation

#### `scripts/README.md`
Comprehensive script documentation:
- Usage examples
- Option descriptions
- Troubleshooting guide
- Architecture diagrams
- Security notes
- Development workflow

#### `DEPLOYMENT.md`
Quick reference guide:
- Quick start instructions
- Common commands
- Authentication flow
- Troubleshooting
- Production checklist
- Backup procedures

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Host Machine                         │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │      containerpub-network (10.89.0.0/24)       │    │
│  │                                                 │    │
│  │  ┌──────────────────┐    ┌──────────────────┐ │    │
│  │  │  Backend         │    │  PostgreSQL      │ │    │
│  │  │  (Dart)          │───▶│  (15-alpine)     │ │    │
│  │  │  Port: 8080      │    │  Port: 5432      │ │    │
│  │  │                  │    │                  │ │    │
│  │  │  Health: /health │    │  Health: ready   │ │    │
│  │  └──────────────────┘    └──────────────────┘ │    │
│  │         │                         │            │    │
│  │         │                         │            │    │
│  │    ┌────▼────┐              ┌────▼─────┐      │    │
│  │    │functions│              │ postgres │      │    │
│  │    │  volume │              │  volume  │      │    │
│  │    └─────────┘              └──────────┘      │    │
│  └────────────────────────────────────────────────┘    │
│         │                         │                     │
│         │                         │                     │
│    localhost:8080            localhost:5432             │
└─────────────────────────────────────────────────────────┘
         │
         │
    ┌────▼─────┐
    │   CLI    │
    │ (Native) │
    └──────────┘
```

## Container Details

### Backend Container

**Image:** `containerpub-backend:latest`
**Base:** debian:bookworm-slim
**Size:** ~150MB (optimized)

**Exposed Ports:**
- 8080 - HTTP API

**Volumes:**
- `/app/functions` - Function storage

**Environment Variables:**
- `PORT` - Server port
- `DATABASE_URL` - Main database connection
- `FUNCTION_DATABASE_URL` - Functions database
- `JWT_SECRET` - Authentication secret
- `FUNCTIONS_DIR` - Function storage path
- Function execution limits

**Health Check:**
- Endpoint: `/api/health`
- Interval: 30s
- Timeout: 10s
- Retries: 3

### PostgreSQL Container

**Image:** `containerpub-postgres:latest`
**Base:** postgres:15-alpine
**Size:** ~240MB

**Exposed Ports:**
- 5432 - PostgreSQL

**Volumes:**
- `/var/lib/postgresql/data` - Database files

**Environment Variables:**
- `POSTGRES_USER` - Database user
- `POSTGRES_PASSWORD` - Database password
- `POSTGRES_DB` - Main database name

**Health Check:**
- Command: `pg_isready`
- Interval: 10s
- Timeout: 5s
- Retries: 5

**Databases:**
- `dart_cloud` - Main application data
- `functions_db` - Function-specific data

## Network Configuration

**Network Name:** `containerpub-network`
**Driver:** bridge
**Subnet:** 10.89.0.0/24
**Gateway:** 10.89.0.1

**DNS Resolution:**
- `postgres` → PostgreSQL container
- `backend` → Backend container

## Volume Configuration

### postgres_data
- **Purpose:** PostgreSQL database files
- **Persistence:** Survives container restarts
- **Backup:** Use pg_dump or volume export

### functions_data
- **Purpose:** Deployed function code
- **Persistence:** Survives container restarts
- **Backup:** Use volume export

## CLI Configuration

**Binary Name:** `dart_cloud`
**Install Location:** `~/.local/bin/dart_cloud`
**Config Location:** `~/.dart_cloud/config.json`

**Config Format:**
```json
{
  "authToken": "jwt-token-here",
  "serverUrl": "http://localhost:8080"
}
```

**Commands:**
- `login` - Authenticate with server
- `logout` - Clear authentication token
- `deploy` - Deploy a function
- `list` - List functions
- `logs` - View function logs
- `invoke` - Execute a function
- `delete` - Remove a function

## Security Considerations

### Development (Current Setup)

✓ Isolated network
✓ Health checks
✓ Non-root execution (backend)
✓ Minimal base images
✓ Token-based authentication

⚠️ Default passwords
⚠️ No SSL/TLS
⚠️ Permissive CORS
⚠️ Local-only secrets

### Production Requirements

Must implement:
- [ ] Strong, random passwords
- [ ] SSL/TLS encryption
- [ ] Secrets management
- [ ] Network policies
- [ ] Resource limits
- [ ] Audit logging
- [ ] Vulnerability scanning
- [ ] Backup automation
- [ ] Monitoring and alerts
- [ ] Access controls

## Performance Optimization

### Backend
- Native compilation (vs JIT)
- Minimal dependencies
- Connection pooling
- Efficient routing

### PostgreSQL
- Proper indexes
- Connection limits
- Shared buffers tuning
- WAL configuration

### Network
- Bridge driver (low overhead)
- DNS caching
- Keep-alive connections

## Maintenance

### Regular Tasks

**Daily:**
- Check container health
- Monitor disk usage
- Review logs

**Weekly:**
- Backup databases
- Update images
- Clean unused resources

**Monthly:**
- Security updates
- Performance review
- Capacity planning

### Commands

```bash
# Health checks
curl http://localhost:8080/api/health
podman exec containerpub-postgres pg_isready

# Resource usage
podman stats
podman system df

# Logs
podman logs --tail 100 containerpub-backend

# Cleanup
podman image prune
podman volume prune
```

## Troubleshooting

### Common Issues

**Build fails:**
- Check Dart SDK version
- Verify dependencies in pubspec.yaml
- Check disk space

**Container won't start:**
- Check port conflicts
- Review container logs
- Verify environment variables

**Database connection fails:**
- Ensure PostgreSQL is running
- Check network connectivity
- Verify credentials

**CLI not working:**
- Check PATH configuration
- Verify binary permissions
- Ensure backend is accessible

### Debug Commands

```bash
# Inspect container
podman inspect containerpub-backend

# Check network
podman network inspect containerpub-network

# Test connectivity
podman exec containerpub-backend curl postgres:5432

# Database logs
podman logs containerpub-postgres | grep ERROR
```

## Next Steps

1. **Deploy infrastructure:**
   ```bash
   ./scripts/deploy.sh
   ```

2. **Install CLI:**
   ```bash
   ./scripts/install-cli.sh
   ```

3. **Test deployment:**
   ```bash
   curl http://localhost:8080/api/health
   dart_cloud --version
   ```

4. **Deploy a function:**
   ```bash
   dart_cloud login
   dart_cloud deploy ./examples/hello-world
   ```

5. **Monitor and maintain:**
   - Check logs regularly
   - Set up backups
   - Monitor resources
   - Plan for scaling

## References

- [Deployment Guide](../DEPLOYMENT.md)
- [Scripts Documentation](../scripts/README.md)
- [OpenTofu Configuration](local/README.md)
- [Podman Documentation](https://docs.podman.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
