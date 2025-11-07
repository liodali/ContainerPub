# Local Deployment with Podman & OpenTofu

This guide covers local deployment using Podman containers managed by OpenTofu.

## Prerequisites

1. **Podman** - Container runtime
   ```bash
   # macOS
   brew install podman
   
   # Linux (Fedora/RHEL)
   sudo dnf install podman
   
   # Linux (Ubuntu/Debian)
   sudo apt install podman
   ```

2. **OpenTofu** - Infrastructure as Code
   ```bash
   # macOS
   brew install opentofu
   
   # Linux
   curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | bash
   ```

3. **Podman Compose** (optional, for compose method)
   ```bash
   pip3 install podman-compose
   ```

## Quick Start

### Method 1: Using Podman Compose (Recommended)

```bash
cd infrastructure

# Start all services
podman-compose -f podman-compose.yml up -d

# Check status
podman-compose -f podman-compose.yml ps

# View logs
podman-compose -f podman-compose.yml logs -f

# Stop services
podman-compose -f podman-compose.yml down
```

### Method 2: Using OpenTofu

```bash
cd infrastructure

# Initialize OpenTofu
tofu init

# Review the plan
tofu plan -var-file=variables.tfvars

# Apply configuration
tofu apply -var-file=variables.tfvars

# View outputs
tofu output
```

## Setup Steps

### 1. Initialize Podman

```bash
# Start Podman machine (macOS only)
podman machine init
podman machine start

# Verify Podman is running
podman info
```

### 2. Build Backend Image

```bash
cd infrastructure

# Build the backend image
podman build -t containerpub-backend:latest -f Dockerfile.backend ..

# Verify image
podman images | grep containerpub
```

### 3. Configure Variables (OpenTofu method)

```bash
# Copy example variables
cp variables.tfvars.example variables.tfvars

# Edit as needed
nano variables.tfvars
```

### 4. Deploy with OpenTofu

```bash
# Initialize
tofu init

# Plan
tofu plan -var-file=variables.tfvars

# Apply
tofu apply -var-file=variables.tfvars
```

## What Gets Created

### Containers

1. **containerpub-postgres**
   - PostgreSQL 15
   - Port: 5432
   - Databases: `dart_cloud`, `functions_db`
   - Volume: `containerpub-postgres-data`

2. **containerpub-backend**
   - Dart Cloud Backend
   - Port: 8080
   - Volume: `containerpub-functions-data`

### Network

- **containerpub-network**
  - Subnet: 10.89.0.0/24
  - Gateway: 10.89.0.1
  - Driver: bridge

### Volumes

- **containerpub-postgres-data** - PostgreSQL data
- **containerpub-functions-data** - Deployed functions

## Usage

### Access Backend API

```bash
# Health check
curl http://localhost:8080/api/health

# Register user
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "testpass123"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "testpass123"}'
```

### Access PostgreSQL

```bash
# Connect to database
podman exec -it containerpub-postgres psql -U dart_cloud -d dart_cloud

# Run queries
SELECT * FROM users;
SELECT * FROM functions;
```

### View Logs

```bash
# Backend logs
podman logs -f containerpub-backend

# PostgreSQL logs
podman logs -f containerpub-postgres

# All logs
podman logs -f $(podman ps -q)
```

### Manage Containers

```bash
# List containers
podman ps -a

# Stop containers
podman stop containerpub-backend containerpub-postgres

# Start containers
podman start containerpub-postgres containerpub-backend

# Restart containers
podman restart containerpub-backend

# Remove containers
podman rm -f containerpub-backend containerpub-postgres
```

## OpenTofu Commands

### View State

```bash
# Show all resources
tofu state list

# Show specific resource
tofu state show podman_container.backend

# View outputs
tofu output
tofu output backend_url
```

### Update Infrastructure

```bash
# Modify variables.tfvars or local-podman.tf

# Plan changes
tofu plan -var-file=variables.tfvars

# Apply changes
tofu apply -var-file=variables.tfvars
```

### Destroy Infrastructure

```bash
# Destroy all resources
tofu destroy -var-file=variables.tfvars

# This will:
# - Stop and remove containers
# - Remove network
# - Remove volumes (data will be lost!)
```

## Development Workflow

### 1. Make Code Changes

```bash
# Edit backend code
cd ../dart_cloud_backend
nano lib/handlers/function_handler.dart
```

### 2. Rebuild Image

```bash
cd ../infrastructure
podman build -t containerpub-backend:latest -f Dockerfile.backend ..
```

### 3. Recreate Container

#### Using Podman Compose:
```bash
podman-compose -f podman-compose.yml up -d --force-recreate backend
```

#### Using OpenTofu:
```bash
# Taint the backend container to force recreation
tofu taint podman_container.backend

# Apply changes
tofu apply -var-file=variables.tfvars
```

### 4. Test Changes

```bash
# Check logs
podman logs -f containerpub-backend

# Test API
curl http://localhost:8080/api/health
```

## Troubleshooting

### Podman Machine Not Running (macOS)

```bash
# Check status
podman machine list

# Start machine
podman machine start

# If issues persist, recreate
podman machine stop
podman machine rm
podman machine init
podman machine start
```

### Container Won't Start

```bash
# Check logs
podman logs containerpub-backend

# Check if port is in use
lsof -i :8080

# Inspect container
podman inspect containerpub-backend
```

### Database Connection Failed

```bash
# Check PostgreSQL is running
podman ps | grep postgres

# Check network
podman network inspect containerpub-network

# Test connection
podman exec containerpub-postgres pg_isready -U dart_cloud
```

### Build Fails

```bash
# Clean build cache
podman system prune -a

# Rebuild with no cache
podman build --no-cache -t containerpub-backend:latest -f Dockerfile.backend ..
```

### OpenTofu State Issues

```bash
# Refresh state
tofu refresh -var-file=variables.tfvars

# Import existing resources
tofu import podman_container.postgres containerpub-postgres

# Reset state (use with caution!)
rm -rf .terraform terraform.tfstate*
tofu init
```

## Configuration

### Environment Variables

Edit `podman-compose.yml` or `variables.tfvars`:

```yaml
# Backend configuration
PORT: 8080
FUNCTION_TIMEOUT_SECONDS: 5
FUNCTION_MAX_MEMORY_MB: 128
FUNCTION_MAX_CONCURRENT: 10

# Database configuration
FUNCTION_DB_MAX_CONNECTIONS: 5
FUNCTION_DB_TIMEOUT_MS: 5000
```

### Resource Limits

Add to `podman-compose.yml`:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '1'
          memory: 512M
```

## Monitoring

### Container Stats

```bash
# Real-time stats
podman stats

# Specific container
podman stats containerpub-backend
```

### Health Checks

```bash
# Check health status
podman inspect --format='{{.State.Health.Status}}' containerpub-backend

# View health check logs
podman inspect --format='{{json .State.Health}}' containerpub-backend | jq
```

### Disk Usage

```bash
# Check volumes
podman volume ls

# Volume size
podman system df -v

# Clean up unused resources
podman system prune -a --volumes
```

## Backup & Restore

### Backup Database

```bash
# Backup
podman exec containerpub-postgres pg_dump -U dart_cloud dart_cloud > backup.sql

# Restore
podman exec -i containerpub-postgres psql -U dart_cloud dart_cloud < backup.sql
```

### Backup Volumes

```bash
# Backup functions volume
podman volume export containerpub-functions-data > functions-backup.tar

# Restore
podman volume import containerpub-functions-data < functions-backup.tar
```

## Production Considerations

### Security

1. **Change default passwords**
   ```bash
   # Edit variables.tfvars
   postgres_password = "strong-random-password"
   jwt_secret = "secure-jwt-secret"
   ```

2. **Use secrets management**
   ```bash
   # Use Podman secrets
   echo "my-secret" | podman secret create db_password -
   ```

3. **Network isolation**
   ```bash
   # Don't expose PostgreSQL port externally
   # Only expose backend port
   ```

### Performance

1. **Resource limits**
   - Set appropriate CPU and memory limits
   - Monitor resource usage

2. **Volume optimization**
   - Use named volumes for better performance
   - Regular cleanup of unused data

3. **Connection pooling**
   - Already configured in backend
   - Adjust pool size based on load

## Next Steps

1. **Deploy Example Functions**
   ```bash
   cd ../dart_cloud_cli
   dart run bin/main.dart deploy test ../examples/simple-function
   ```

2. **Set Up Monitoring**
   - Add Prometheus/Grafana
   - Configure alerting

3. **CI/CD Integration**
   - Automate image builds
   - Deploy on code changes

4. **Scale Up**
   - Add load balancer
   - Multiple backend instances
   - Database replication

## Resources

- [Podman Documentation](https://docs.podman.io/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Podman Compose](https://github.com/containers/podman-compose)
- [ContainerPub Documentation](../docs/)

## Quick Reference

```bash
# Start everything
podman-compose -f podman-compose.yml up -d

# Stop everything
podman-compose -f podman-compose.yml down

# Rebuild and restart
podman build -t containerpub-backend:latest -f Dockerfile.backend ..
podman-compose -f podman-compose.yml up -d --force-recreate backend

# View logs
podman-compose -f podman-compose.yml logs -f

# Database shell
podman exec -it containerpub-postgres psql -U dart_cloud -d dart_cloud

# Clean up everything
podman-compose -f podman-compose.yml down -v
podman system prune -a --volumes
```
