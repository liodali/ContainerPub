# Docker Compose Setup for Dart Cloud Backend

## Overview

Complete Docker Compose configuration for deploying the Dart Cloud Backend with PostgreSQL database, including secure environment variable management.

## Files Created

### 1. `docker-compose.yml`
Complete Docker Compose configuration with:
- **PostgreSQL 15** service with health checks
- **Backend** service with dependency management
- **Persistent volumes** for data and functions
- **Network isolation** for security
- **Environment variable** injection from `.env`
- **Health checks** for both services

### 2. `.env.example`
Environment variable template with:
- Database configuration (user, password, database names)
- Server configuration (port, functions directory)
- Security settings (JWT secret)
- Function execution limits
- Clear documentation and examples

### 3. `init-db.sql`
Database initialization script that:
- Creates `dart_cloud` and `functions_db` databases
- Creates tables: `users`, `functions`, `function_logs`, `function_data`
- Sets up indexes for performance
- Creates triggers for `updated_at` columns
- Grants necessary permissions

### 4. `start.sh`
Quick start script that:
- Checks Docker and Docker Compose installation
- Creates `.env` from template if missing
- Generates secure passwords automatically
- Starts all services
- Waits for health checks
- Shows status and useful commands

### 5. `.gitignore`
Ensures sensitive files are not committed:
- `.env` file
- Functions directory
- Build artifacts
- Logs

### 6. Updated `README.md`
Comprehensive documentation with:
- Quick start guide
- Docker Compose usage
- Management commands
- Troubleshooting
- Security best practices
- CI/CD integration examples

## Quick Start

### Method 1: Using start.sh (Easiest)

```bash
cd dart_cloud_backend
chmod +x start.sh
./start.sh
```

This automatically:
- Creates `.env` file
- Generates secure passwords
- Starts all services
- Verifies health

### Method 2: Manual Setup

```bash
# 1. Create environment file
cp .env.example .env

# 2. Generate secure passwords
openssl rand -base64 32  # For POSTGRES_PASSWORD
openssl rand -base64 64  # For JWT_SECRET

# 3. Edit .env
nano .env

# 4. Start services
docker compose up -d

# 5. Check status
docker compose ps
docker compose logs -f
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Docker Compose Environment                  │
│                                                          │
│  ┌──────────────────────┐    ┌──────────────────────┐  │
│  │   Backend Service    │    │  PostgreSQL Service  │  │
│  │                      │    │                      │  │
│  │  Port: 8080          │───▶│  Port: 5432          │  │
│  │  Image: Custom       │    │  Image: postgres:15  │  │
│  │  Health: /api/health │    │  Health: pg_isready  │  │
│  │                      │    │                      │  │
│  │  Environment:        │    │  Environment:        │  │
│  │  - DATABASE_URL      │    │  - POSTGRES_USER     │  │
│  │  - JWT_SECRET        │    │  - POSTGRES_PASSWORD │  │
│  │  - PORT              │    │  - POSTGRES_DB       │  │
│  │  - FUNCTIONS_DIR     │    │                      │  │
│  └──────────┬───────────┘    └──────────┬───────────┘  │
│             │                           │              │
│             │                           │              │
│        ┌────▼────┐                 ┌────▼────┐        │
│        │Functions│                 │Postgres │        │
│        │ Volume  │                 │  Data   │        │
│        │         │                 │ Volume  │        │
│        └─────────┘                 └─────────┘        │
│                                                         │
│                 dart_cloud_network                      │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
                  External Access
              http://localhost:8080
```

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | Database password | `secure_random_32_chars` |
| `JWT_SECRET` | JWT signing secret | `secure_random_64_chars` |

### Optional Variables (with defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `dart_cloud` | Database username |
| `POSTGRES_DB` | `dart_cloud` | Main database name |
| `POSTGRES_PORT` | `5432` | PostgreSQL port |
| `FUNCTION_DB` | `functions_db` | Functions database |
| `PORT` | `8080` | Backend API port |
| `FUNCTIONS_DIR` | `/app/functions` | Functions storage |
| `FUNCTION_TIMEOUT_SECONDS` | `5` | Function timeout |
| `FUNCTION_MAX_MEMORY_MB` | `128` | Memory limit |
| `FUNCTION_MAX_CONCURRENT` | `10` | Concurrent executions |

## Docker Compose Features

### Health Checks

**PostgreSQL:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U dart_cloud"]
  interval: 10s
  timeout: 5s
  retries: 5
```

**Backend:**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/api/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### Dependency Management

Backend waits for PostgreSQL to be healthy:
```yaml
depends_on:
  postgres:
    condition: service_healthy
```

### Persistent Volumes

- `postgres_data` - Database files
- `functions_data` - Deployed functions

### Network Isolation

All services communicate through `dart_cloud_network` bridge network.

## Common Commands

### Service Management

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Restart service
docker compose restart backend

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f backend
docker compose logs -f postgres

# Check status
docker compose ps

# View resource usage
docker stats
```

### Database Operations

```bash
# Connect to database
docker compose exec postgres psql -U dart_cloud -d dart_cloud

# Run SQL query
docker compose exec postgres psql -U dart_cloud -d dart_cloud -c "SELECT * FROM users;"

# Backup database
docker compose exec postgres pg_dump -U dart_cloud dart_cloud > backup.sql

# Restore database
cat backup.sql | docker compose exec -T postgres psql -U dart_cloud -d dart_cloud

# View database size
docker compose exec postgres psql -U dart_cloud -d dart_cloud -c "SELECT pg_size_pretty(pg_database_size('dart_cloud'));"
```

### Backend Operations

```bash
# Execute shell in backend container
docker compose exec backend sh

# Check backend health
curl http://localhost:8080/api/health

# Test API endpoint
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect dart_cloud_backend_postgres_data

# Backup volume
docker run --rm \
  -v dart_cloud_backend_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres_backup.tar.gz -C /data .

# Restore volume
docker run --rm \
  -v dart_cloud_backend_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/postgres_backup.tar.gz -C /data
```

## Security Best Practices

### 1. Environment Variables

✅ **Do:**
- Use `.env` file for local development
- Generate strong random passwords
- Set file permissions: `chmod 600 .env`
- Use secrets management in production

❌ **Don't:**
- Commit `.env` to version control
- Use default passwords in production
- Share `.env` via insecure channels
- Hardcode secrets in docker-compose.yml

### 2. Network Security

✅ **Do:**
- Use internal network for service communication
- Only expose necessary ports
- Use reverse proxy for HTTPS
- Implement rate limiting

❌ **Don't:**
- Expose PostgreSQL port publicly
- Use default ports in production
- Skip SSL/TLS configuration

### 3. Production Deployment

Use Docker Secrets:
```yaml
version: '3.8'

services:
  backend:
    secrets:
      - postgres_password
      - jwt_secret
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
      JWT_SECRET_FILE: /run/secrets/jwt_secret

secrets:
  postgres_password:
    external: true
  jwt_secret:
    external: true
```

Create secrets:
```bash
echo "secure_password" | docker secret create postgres_password -
echo "secure_jwt_secret" | docker secret create jwt_secret -
```

## Troubleshooting

### Services won't start

```bash
# Check logs
docker compose logs

# Verify .env file
cat .env

# Check Docker Compose config
docker compose config

# Remove and recreate
docker compose down -v
docker compose up -d
```

### Database connection failed

```bash
# Check PostgreSQL is running
docker compose ps postgres

# Check PostgreSQL logs
docker compose logs postgres

# Test connection
docker compose exec postgres pg_isready -U dart_cloud

# Verify environment variables
docker compose exec backend env | grep DATABASE
```

### Port already in use

```bash
# Find process using port
lsof -i :8080
lsof -i :5432

# Change port in .env
PORT=8081
POSTGRES_PORT=5433

# Restart services
docker compose down
docker compose up -d
```

### Permission denied

```bash
# Fix .env permissions
chmod 600 .env

# Fix script permissions
chmod +x start.sh

# Check volume permissions
docker compose exec backend ls -la /app/functions
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Deploy Backend

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Create .env
        run: |
          cd dart_cloud_backend
          echo "POSTGRES_PASSWORD=${{ secrets.POSTGRES_PASSWORD }}" >> .env
          echo "JWT_SECRET=${{ secrets.JWT_SECRET }}" >> .env
          echo "POSTGRES_USER=dart_cloud" >> .env
          echo "POSTGRES_DB=dart_cloud" >> .env
          echo "PORT=8080" >> .env
      
      - name: Deploy
        run: |
          cd dart_cloud_backend
          docker compose up -d --build
      
      - name: Health Check
        run: |
          sleep 10
          curl -f http://localhost:8080/api/health
```

### GitLab CI

```yaml
deploy:
  stage: deploy
  script:
    - cd dart_cloud_backend
    - echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> .env
    - echo "JWT_SECRET=$JWT_SECRET" >> .env
    - docker compose up -d --build
    - sleep 10
    - curl -f http://localhost:8080/api/health
  only:
    - main
```

## Monitoring

### Health Checks

```bash
# Backend health
curl http://localhost:8080/api/health

# PostgreSQL health
docker compose exec postgres pg_isready -U dart_cloud

# All services
docker compose ps
```

### Logs

```bash
# All logs
docker compose logs -f

# Last 100 lines
docker compose logs --tail=100

# Since timestamp
docker compose logs --since 2024-01-01T00:00:00

# Follow specific service
docker compose logs -f backend
```

### Metrics

```bash
# Container stats
docker stats

# Disk usage
docker system df

# Network inspect
docker network inspect dart_cloud_backend_dart_cloud_network
```

## Backup and Restore

### Full Backup

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup database
docker compose exec postgres pg_dump -U dart_cloud dart_cloud > "$BACKUP_DIR/database.sql"

# Backup functions volume
docker run --rm \
  -v dart_cloud_backend_functions_data:/data \
  -v $(pwd)/$BACKUP_DIR:/backup \
  alpine tar czf /backup/functions.tar.gz -C /data .

# Backup .env (encrypted)
openssl enc -aes-256-cbc -salt -in .env -out "$BACKUP_DIR/env.enc"

echo "Backup completed: $BACKUP_DIR"
```

### Full Restore

```bash
#!/bin/bash
# restore.sh

BACKUP_DIR=$1

# Restore database
cat "$BACKUP_DIR/database.sql" | docker compose exec -T postgres psql -U dart_cloud -d dart_cloud

# Restore functions volume
docker run --rm \
  -v dart_cloud_backend_functions_data:/data \
  -v $(pwd)/$BACKUP_DIR:/backup \
  alpine tar xzf /backup/functions.tar.gz -C /data

# Restore .env (decrypt)
openssl enc -aes-256-cbc -d -in "$BACKUP_DIR/env.enc" -out .env

echo "Restore completed from: $BACKUP_DIR"
```

## Additional Resources

- [Main Project README](../README.md)
- [Deployment Guide](../DEPLOYMENT.md)
- [Security Guide](../SECURITY.md)
- [Docker Setup](../infrastructure/DOCKER_SETUP.md)
- [Backend README](README.md)

---

**Summary:** Complete Docker Compose setup with secure environment management, automatic database initialization, health checks, and comprehensive documentation! 🚀
