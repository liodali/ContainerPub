# Installation Guide

Complete installation instructions for ContainerPub on different platforms and environments.

## System Requirements

### Minimum Requirements
- **OS**: macOS 10.15+, Ubuntu 18.04+, or Windows 10+ with WSL2
- **RAM**: 4GB (8GB recommended)
- **Storage**: 2GB free space
- **Network**: Internet connection for dependencies

### Software Requirements
- **Dart SDK**: 3.0.0 or higher
- **Docker**: 20.10+ or **Podman**: 3.0+
- **Git**: 2.0+

## Platform-Specific Installation

### macOS

#### Option 1: Homebrew (Recommended)
```bash
# Install required tools
brew install dart-sdk docker

# Start Docker Desktop
open /Applications/Docker.app

# Verify installation
dart --version
docker --version
```

#### Option 2: Manual Installation
```bash
# Install Dart SDK
curl -O https://storage.googleapis.com/dart-archive/channels/stable/release/latest/macos/dartsdk-macos-x64-release.zip
unzip dartsdk-macos-x64-release.zip
export PATH="$PWD/dart-sdk/bin:$PATH"
echo 'export PATH="$PATH:/path/to/dart-sdk/bin"' >> ~/.zshrc

# Install Docker Desktop
# Download from https://www.docker.com/products/docker-desktop
```

### Linux (Ubuntu/Debian)

#### Option 1: Apt Packages
```bash
# Update package list
sudo apt update

# Install Dart SDK
sudo apt install software-properties-common
sudo apt-add-repository ppa:dart/ppa
sudo apt update
sudo apt install dart

# Install Docker
sudo apt install docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
dart --version
docker --version
```

#### Option 2: Snap Packages
```bash
# Install Dart
sudo snap install dart-sdk

# Install Docker
sudo snap install docker

# Connect docker to system
sudo snap connect docker:home

# Verify installation
dart --version
docker --version
```

### Windows

#### Option 1: WSL2 + Ubuntu (Recommended)
```bash
# Enable WSL2 in PowerShell (as Administrator)
wsl --install

# Install Ubuntu from Microsoft Store
# Restart computer

# In WSL2 Ubuntu terminal:
sudo apt update
sudo apt install dart-sdk docker.io

# Add user to docker group
sudo usermod -aG docker $USER

# Verify installation
dart --version
docker --version
```

#### Option 2: Native Windows
```powershell
# Install Dart SDK
# Download from https://dart.dev/get-dart
# Add to PATH: C:\dart\bin

# Install Docker Desktop
# Download from https://www.docker.com/products/docker-desktop

# Verify in PowerShell
dart --version
docker --version
```

## Container Runtime Setup

### Docker Setup
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Test Docker
docker run hello-world

# Verify Docker Compose
docker-compose --version
```

### Podman Setup (Alternative)
```bash
# Install Podman (macOS)
brew install podman

# Install Podman (Linux)
sudo apt install podman podman-compose

# Initialize Podman machine
podman machine init
podman machine start

# Test Podman
podman run hello-world
```

## ContainerPub Installation

### Method 1: Automated Installation (Recommended)
```bash
# Clone repository
git clone https://github.com/liodali/ContainerPub.git
cd ContainerPub

# Make scripts executable
chmod +x scripts/*.sh

# Deploy everything
./scripts/deploy.sh

# Install CLI
./scripts/install-cli.sh
```

### Method 2: Step-by-Step Installation
```bash
# 1. Clone repository
git clone https://github.com/liodali/ContainerPub.git
cd ContainerPub

# 2. Setup environment
cp .env.example .env
# Edit .env with your configuration

# 3. Build and start services
cd infrastructure/local
docker-compose up -d

# 4. Initialize database
cd ../..
docker exec -i containerpub-postgres psql -U dart_cloud -d dart_cloud < deploy/init-db.sql

# 5. Install CLI
cd dart_cloud_cli
dart pub get
dart compile exe bin/main.dart -o ../dart_cloud
sudo mv ../dart_cloud /usr/local/bin/
```

### Method 3: Development Installation
```bash
# Clone repository
git clone https://github.com/liodali/ContainerPub.git
cd ContainerPub

# Install backend dependencies
cd dart_cloud_backend
dart pub get

# Install CLI dependencies
cd ../dart_cloud_cli
dart pub get

# Setup development environment
cd ..
./setup-local.sh

# Start development servers
./test-local.sh
```

## Environment Configuration

### Create Environment File
```bash
# Copy template
cp .env.example .env

# Edit with your values
nano .env
```

### Required Environment Variables
```bash
# Database Configuration
POSTGRES_USER=dart_cloud
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=dart_cloud
POSTGRES_PORT=5432
POSTGRES_HOST=localhost

# Backend Configuration
PORT=8080
JWT_SECRET=your_long_random_jwt_secret_at_least_32_characters
FUNCTIONS_DIR=/app/functions

# Function Execution Limits
FUNCTION_TIMEOUT_SECONDS=5
FUNCTION_MAX_MEMORY_MB=128
FUNCTION_MAX_CONCURRENT=10
```

### Generate Secure Secrets
```bash
# Generate PostgreSQL password
openssl rand -base64 32

# Generate JWT secret
openssl rand -base64 64

# Full setup script
cat > .env << EOF
POSTGRES_USER=dart_cloud
POSTGRES_PASSWORD=$(openssl rand -base64 32)
POSTGRES_DB=dart_cloud
POSTGRES_PORT=5432
POSTGRES_HOST=localhost

PORT=8080
JWT_SECRET=$(openssl rand -base64 64)
FUNCTIONS_DIR=/app/functions

FUNCTION_TIMEOUT_SECONDS=5
FUNCTION_MAX_MEMORY_MB=128
FUNCTION_MAX_CONCURRENT=10
EOF

chmod 600 .env
```

## Verification

### System Health Check
```bash
# Check all services are running
docker ps

# Test backend health
curl http://localhost:8080/api/health

# Test database connection
docker exec -it containerpub-postgres pg_isready -U dart_cloud

# Test CLI installation
dart_cloud --version
dart_cloud login
```

### Function Deployment Test
```bash
# Deploy example function
dart_cloud deploy ./examples/hello-world

# List functions
dart_cloud list

# Invoke function
dart_cloud invoke <function-id>

# View logs
dart_cloud logs <function-id>
```

## Troubleshooting

### Common Issues

#### Permission Denied
```bash
# Fix Docker permissions
sudo usermod -aG docker $USER
newgrp docker

# Fix script permissions
chmod +x scripts/*.sh
```

#### Port Already in Use
```bash
# Check what's using port 8080
lsof -i :8080

# Kill process
sudo kill -9 <PID>

# Or use different port
export PORT=8081
./scripts/deploy.sh
```

#### Out of Memory
```bash
# Increase Docker memory limit
# In Docker Desktop: Settings > Resources > Memory
# Set to at least 4GB

# Or use Podman with more memory
podman machine set --memory 4096
```

#### Network Issues
```bash
# Reset Docker network
docker network prune

# Recreate ContainerPub network
./scripts/deploy.sh --clean
```

### Log Locations
```bash
# Backend logs
docker logs containerpub-backend

# Database logs
docker logs containerpub-postgres

# CLI logs
~/.dart_cloud/logs/

# System logs
journalctl -u docker
```

## Advanced Configuration

### Custom Ports
```bash
# Edit .env file
PORT=9000
POSTGRES_PORT=5433

# Redeploy
./scripts/deploy.sh --clean
```

### External Database
```bash
# Edit .env file
DATABASE_URL=postgres://user:pass@external-db:5432/containerpub
FUNCTION_DATABASE_URL=postgres://user:pass@external-db:5432/functions_db

# Deploy without local database
./scripts/deploy.sh --external-db
```

### Production Settings
```bash
# Use production-ready values
FUNCTION_TIMEOUT_SECONDS=3
FUNCTION_MAX_MEMORY_MB=64
FUNCTION_MAX_CONCURRENT=5

# Enable SSL
DATABASE_URL=postgres://user:pass@db:5432/containerpub?sslmode=require
```

## Next Steps

After successful installation:

1. **[Quick Start Guide](quick-start.md)** - Deploy your first function
2. **[First Function](first-function.md)** - Create custom functions
3. **[User Guide](../user-guide/)** - Explore all features
4. **[Configuration](../deployment/configuration.md)** - Customize your setup

## Support

- **Documentation**: [Complete guides](../README.md)
- **Issues**: [GitHub Issues](https://github.com/liodali/ContainerPub/issues)
- **Community**: [Discussions](https://github.com/liodali/ContainerPub/discussions)

---

**Ready to start?** Check out our [Quick Start Guide](quick-start.md) to deploy your first function!
