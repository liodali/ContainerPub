# Quick Start Guide

Get ContainerPub running locally in 3 simple steps. This guide will have you deploying your first Dart function in minutes.

## Prerequisites

- **Dart SDK** 3.0.0 or higher
- **Docker** or **Podman** for containerization
- **Git** for version control

### Installation Commands

```bash
# macOS
brew install dart-sdk docker

# Linux (Ubuntu/Debian)
sudo apt update
sudo apt install dart docker.io

# Start Docker service
sudo systemctl start docker
sudo usermod -aG docker $USER
```

## Step 1: Clone and Setup

```bash
# Clone the repository
git clone https://github.com/liodali/ContainerPub.git
cd ContainerPub

# Make scripts executable
chmod +x scripts/*.sh

# Copy environment configuration
cp .env.example .env
```

## Step 2: Deploy Infrastructure

```bash
# Deploy everything with one command
./scripts/deploy.sh
```

This automatically:
- ✅ Builds PostgreSQL and backend containers
- ✅ Creates secure network and volumes
- ✅ Initializes database with required tables
- ✅ Starts all services with health checks
- ✅ Verifies the deployment is working

**Expected Output:**
```
✓ Environment variables loaded
✓ Building PostgreSQL image...
✓ Building backend image...
✓ Creating network and volumes...
✓ Starting containers...
✓ Running health checks...
✓ Deployment complete!

Backend: http://localhost:8080
PostgreSQL: localhost:5432
```

## Step 3: Install CLI and Deploy Function

```bash
# Install the CLI tool
./scripts/install-cli.sh

# Deploy an example function
dart_cloud deploy ./examples/hello-world

# Test your function
dart_cloud invoke <function-id>
```

**Expected Output:**
```
✓ CLI installed successfully
✓ Function deployed: hello-world
✓ Function ID: abc123-def456
✓ Invocation result: Hello, World!
```

## Verify Everything Works

Run these quick health checks:

```bash
# Check backend is running
curl http://localhost:8080/api/health

# Check database connection
docker exec -it containerpub-postgres pg_isready -U dart_cloud

# List deployed functions
dart_cloud list
```

## What You Just Accomplished

🎉 **Congratulations!** You now have:
- A fully functional ContainerPub backend running
- PostgreSQL database with proper schema
- CLI tool installed and configured
- Your first Dart function deployed and working

## Next Steps

1. **[Create Your Own Function](first-function.md)** - Write custom functions
2. **[User Guide](../user-guide/)** - Learn advanced features
3. **[Configuration](../deployment/configuration.md)** - Customize your setup
4. **[Security Guidelines](../user-guide/security-guidelines.md)** - Understand security model

## Troubleshooting

### Port Already in Use
```bash
# Check what's using port 8080
lsof -i :8080

# Use different port
export PORT=8081
./scripts/deploy.sh
```

### Docker Permission Issues
```bash
# Fix Docker permissions
sudo usermod -aG docker $USER
newgrp docker
./scripts/deploy.sh
```

### Database Connection Failed
```bash
# Restart services
./scripts/deploy.sh --clean

# Check logs
docker logs containerpub-backend
docker logs containerpub-postgres
```

### CLI Not Found
```bash
# Reinstall CLI
./scripts/install-cli.sh

# Check installation
which dart_cloud
dart_cloud --version
```

## Need Help?

- **Documentation**: [Complete guides](../README.md)
- **Examples**: [Function templates](../user-guide/function-templates.md)
- **Issues**: [GitHub Issues](https://github.com/liodali/ContainerPub/issues)
- **Community**: Join our discussions

---

**Ready for more?** Check out our [User Guide](../user-guide/) to explore all ContainerPub features!
