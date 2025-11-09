# Production Deployment Guide

This guide provides a checklist and best practices for deploying ContainerPub to a production environment.

## Prerequisites

- A server or virtual machine with Docker/Podman installed
- A registered domain name
- SSL/TLS certificates (e.g., from Let's Encrypt)
- A dedicated PostgreSQL database (e.g., RDS, Cloud SQL, or a managed service)
- A secrets management solution (e.g., HashiCorp Vault, AWS Secrets Manager)

## Security Checklist

**⚠️ Do not use default configuration in production!**

- [ ] Change default passwords for all services.
- [ ] Use a strong, randomly generated JWT secret (32+ characters).
- [ ] Enable SSL/TLS for all public-facing endpoints.
- [ ] Configure firewall rules to restrict access to necessary ports.
- [ ] Use a secrets management tool to handle all sensitive data.
- [ ] Enable audit logging for all services.
- [ ] Set up monitoring and alerting for critical metrics.
- [ ] Configure regular backups for your database and function storage.
- [ ] Run containers as non-root users.
- [ ] Regularly scan container images for vulnerabilities.

## Production Environment Variables

Create a `.env.production` file with secure, production-ready values:

```bash
# Use strong, random values
POSTGRES_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)

# Use your production database URL
DATABASE_URL=postgres://user:pass@prod-db.example.com:5432/containerpub?sslmode=require
FUNCTION_DATABASE_URL=postgres://user:pass@prod-db.example.com:5432/functions_db?sslmode=require

# Restrict resources for production
FUNCTION_TIMEOUT_SECONDS=3
FUNCTION_MAX_MEMORY_MB=64
FUNCTION_MAX_CONCURRENT=50

# Server port
PORT=8080
```

## Deployment Options

### Option 1: Docker Compose with Reverse Proxy

This is a common setup for single-server deployments.

1.  **Set up a reverse proxy** (e.g., Nginx, Caddy, or Traefik) to handle SSL termination and route traffic to the backend container.

2.  **Create a `docker-compose.prod.yml` file:**

    ```yaml
    version: '3.8'
    services:
      backend-cloud:
        image: your-repo/containerpub-backend:latest
        restart: unless-stopped
        env_file:
          - .env.production
        networks:
          - web

    networks:
      web:
        external: true
    ```

3.  **Deploy:**

    ```bash
    docker-compose -f docker-compose.prod.yml up -d
    ```

### Option 2: Kubernetes (K8s)

For scalable, resilient deployments, Kubernetes is the recommended choice.

1.  **Create Kubernetes manifests** for the backend deployment, service, ingress, and secrets.

2.  **Store secrets in K8s secrets:**

    ```bash
    kubectl create secret generic containerpub-secrets \
      --from-literal=POSTGRES_PASSWORD='...' \
      --from-literal=JWT_SECRET='...'
    ```

3.  **Deploy to your cluster:**

    ```bash
    kubectl apply -f deployment.yaml
    kubectl apply -f service.yaml
    kubectl apply -f ingress.yaml
    ```

### Option 3: OpenTofu/Terraform

Use the provided Terraform configurations to provision your infrastructure as code.

```bash
# Deploy with OpenTofu
./scripts/deploy.sh --tofu --env=production
```

This is best for:
- Reproducible deployments
- Version-controlled infrastructure
- Team environments

## Monitoring

### Health Checks

Set up a monitoring service to periodically check the health of your deployment:

```bash
# Backend health endpoint
curl https://your-domain.com/api/health

# Database health
# This should be done from within your VPC/private network
# podman exec containerpub-postgres pg_isready -U dart_cloud
```

### Metrics

Integrate with a monitoring solution like Prometheus and Grafana to track key metrics:

-   Container stats (CPU, memory, network)
-   Request latency and error rates
-   Function execution times
-   Database connection pool usage

### Logging

Configure your container runtime to forward logs to a centralized logging service (e.g., ELK stack, Loki, or a cloud provider's logging service).

```bash
# Example of viewing logs
docker logs -f containerpub-backend
```

## Backup and Restore

### Database Backup

Schedule regular backups of your PostgreSQL database.

```bash
# Create a compressed backup
podman exec containerpub-postgres pg_dump -U dart_cloud dart_cloud | gzip > backup-$(date +%Y%m%d).sql.gz
```

### Database Restore

```bash
# Restore from a compressed backup
gunzip -c backup.sql.gz | podman exec -i containerpub-postgres psql -U dart_cloud -d dart_cloud
```

### Volume Backup

If you are storing function code or other data in volumes, back them up as well.

```bash
# Backup a volume to a tarball
podman volume export containerpub-functions-data > functions-data-backup.tar

# Restore a volume from a tarball
podman volume import containerpub-functions-data < functions-data-backup.tar
```
