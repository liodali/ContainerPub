# ContainerPub Scripts

This directory contains deployment and installation scripts for ContainerPub.

## Available Scripts

### 1. `deploy.sh` - Infrastructure Deployment

Builds and deploys the ContainerPub infrastructure using Podman or OpenTofu.

#### Usage

```bash
# Basic deployment (builds and starts everything)
./scripts/deploy.sh

# Build and deploy backend only
./scripts/deploy.sh --backend-only

# Build and deploy PostgreSQL only
./scripts/deploy.sh --postgres-only

# Use OpenTofu for deployment
./scripts/deploy.sh --tofu

# Clean deployment (removes existing data)
./scripts/deploy.sh --clean

# Build images without starting containers
./scripts/deploy.sh --no-start

# Skip building, just start containers
./scripts/deploy.sh --no-build
```

#### Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-b, --backend-only` | Build and deploy backend only |
| `-p, --postgres-only` | Build and deploy PostgreSQL only |
| `-n, --no-build` | Skip building images |
| `-t, --tofu` | Use OpenTofu to deploy |
| `--no-start` | Build images but don't start containers |
| `--clean` | Remove existing containers and volumes |

#### What It Does

1. **Checks dependencies** - Verifies Podman and OpenTofu (if needed) are installed
2. **Builds Docker images** - Creates optimized container images
3. **Creates network** - Sets up isolated container network
4. **Creates volumes** - Sets up persistent storage
5. **Starts containers** - Launches PostgreSQL and backend services
6. **Verifies deployment** - Checks health of running services

#### Requirements

- **Podman** - Container runtime
- **OpenTofu** (optional) - Infrastructure as code tool
- **curl** - For health checks

Install on macOS:
```bash
brew install podman
brew install opentofu  # Optional
```

#### After Deployment

Access your services:
- **Backend API:** http://localhost:8080
- **PostgreSQL:** localhost:5432
- **Database:** dart_cloud
- **User:** dart_cloud
- **Password:** dev_password (default)

View logs:
```bash
podman logs -f containerpub-backend
podman logs -f containerpub-postgres
```

Stop services:
```bash
podman stop containerpub-backend containerpub-postgres
```

Start services:
```bash
podman start containerpub-postgres containerpub-backend
```

---

### 2. `install-cli.sh` - CLI Installation

Compiles and installs the Dart Cloud CLI tool globally on your system.

#### Usage

```bash
# Install CLI globally
./scripts/install-cli.sh

# Install in development mode (uses dart run)
./scripts/install-cli.sh --dev

# Install to custom directory
./scripts/install-cli.sh --path /usr/local/bin

# Uninstall CLI
./scripts/install-cli.sh --uninstall
```

#### Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-u, --uninstall` | Uninstall the CLI |
| `--dev` | Install in development mode |
| `--path <path>` | Custom installation directory |

#### What It Does

1. **Checks dependencies** - Verifies Dart SDK is installed
2. **Gets dependencies** - Downloads required Dart packages
3. **Compiles CLI** - Creates native executable
4. **Installs globally** - Copies binary to installation directory
5. **Verifies installation** - Tests the CLI works correctly

#### Requirements

- **Dart SDK** (>= 3.0.0)

Install on macOS:
```bash
brew install dart-sdk
```

#### After Installation

The CLI will be available as `dart_cloud`:

```bash
# Login to your account
dart_cloud login

# Deploy a function
dart_cloud deploy ./my_function

# List functions
dart_cloud list

# View logs
dart_cloud logs <function-id>

# Invoke a function
dart_cloud invoke <function-id> --data '{"key": "value"}'

# Logout
dart_cloud logout

# Get help
dart_cloud --help
```

#### Configuration

The CLI stores configuration in `~/.dart_cloud/config.json`:

```json
{
  "authToken": "your-jwt-token",
  "serverUrl": "http://localhost:8080"
}
```

#### Authentication Management

**Login:**
```bash
dart_cloud login
# Enter email and password when prompted
```

**Logout:**
```bash
dart_cloud logout
# Clears authentication token from config
```

**Check authentication status:**
```bash
# If not logged in, commands will fail with authentication error
dart_cloud list
```

The authentication token is stored securely in your home directory and is automatically included in all API requests.

---

## Quick Start Guide

### 1. Deploy Infrastructure

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy backend and database
./scripts/deploy.sh
```

Wait for deployment to complete. You should see:
```
✓ PostgreSQL container started
✓ Backend container started
✓ Deployment Complete!
```

### 2. Install CLI

```bash
# Install CLI globally
./scripts/install-cli.sh
```

Add to PATH if needed:
```bash
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc
source ~/.zshrc
```

### 3. Use the CLI

```bash
# Login (create account first via API or register endpoint)
dart_cloud login

# Deploy a function
cd examples/hello-world
dart_cloud deploy .

# Test the function
dart_cloud invoke <function-id>

# View logs
dart_cloud logs <function-id>

# Logout when done
dart_cloud logout
```

---

## Troubleshooting

### Deployment Issues

**"Cannot connect to Podman socket"**
```bash
podman machine start
```

**"Port already in use"**
```bash
# Stop conflicting services or change ports in local-podman.tf
podman ps
podman stop <container-name>
```

**"Image not found"**
```bash
# Build images manually
./scripts/deploy.sh --no-start
```

### CLI Installation Issues

**"Dart SDK not found"**
```bash
brew install dart-sdk
```

**"Command not found: dart_cloud"**
```bash
# Add to PATH
export PATH="$PATH:$HOME/.local/bin"
```

**"Permission denied"**
```bash
chmod +x ~/.local/bin/dart_cloud
```

### CLI Usage Issues

**"Authentication required"**
```bash
# Login first
dart_cloud login
```

**"Connection refused"**
```bash
# Check if backend is running
curl http://localhost:8080/api/health

# Start backend if needed
./scripts/deploy.sh --no-build
```

---

## Development Workflow

### Local Development

1. **Start infrastructure:**
   ```bash
   ./scripts/deploy.sh
   ```

2. **Install CLI in dev mode:**
   ```bash
   ./scripts/install-cli.sh --dev
   ```

3. **Make changes to CLI code**

4. **Test changes:**
   ```bash
   cd dart_cloud_cli
   dart run bin/main.dart login
   ```

### Rebuilding After Changes

**Backend changes:**
```bash
./scripts/deploy.sh --backend-only --clean
```

**Database schema changes:**
```bash
./scripts/deploy.sh --postgres-only --clean
```

**CLI changes:**
```bash
./scripts/install-cli.sh
```

---

## Architecture

### Container Images

**Backend Image** (`containerpub-backend:latest`)
- Multi-stage build for minimal size
- Compiled Dart executable
- Debian slim base image
- Health check endpoint

**PostgreSQL Image** (`containerpub-postgres:latest`)
- Based on PostgreSQL 15 Alpine
- Custom initialization scripts
- Pre-configured databases
- Health check with pg_isready

### Network Architecture

```
┌─────────────────────────────────────────┐
│         containerpub-network            │
│              (10.89.0.0/24)             │
│                                         │
│  ┌──────────────┐    ┌──────────────┐  │
│  │   Backend    │───▶│  PostgreSQL  │  │
│  │   :8080      │    │   :5432      │  │
│  └──────────────┘    └──────────────┘  │
│         │                    │          │
└─────────┼────────────────────┼──────────┘
          │                    │
          ▼                    ▼
    Host :8080           Host :5432
```

### Data Persistence

- **postgres_data** - PostgreSQL database files
- **functions_data** - Deployed function code and metadata

---

## Environment Variables

### Backend Container

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | API server port |
| `DATABASE_URL` | - | Main database connection string |
| `FUNCTION_DATABASE_URL` | - | Functions database connection string |
| `JWT_SECRET` | - | Secret for JWT token signing |
| `FUNCTIONS_DIR` | `/app/functions` | Function storage directory |
| `FUNCTION_TIMEOUT_SECONDS` | `5` | Function execution timeout |
| `FUNCTION_MAX_MEMORY_MB` | `128` | Max memory per function |
| `FUNCTION_MAX_CONCURRENT` | `10` | Max concurrent executions |

### PostgreSQL Container

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `dart_cloud` | Database user |
| `POSTGRES_PASSWORD` | `dev_password` | Database password |
| `POSTGRES_DB` | `dart_cloud` | Main database name |

---

## Security Notes

⚠️ **Important:** The default configuration is for local development only.

For production:
1. Change default passwords
2. Use strong JWT secrets
3. Enable SSL/TLS
4. Use secrets management
5. Restrict network access
6. Enable authentication
7. Set up proper backups

---

## Additional Resources

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Podman Documentation](https://docs.podman.io/)
- [Dart SDK Documentation](https://dart.dev/guides)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## Contributing

When adding new scripts:
1. Make them executable: `chmod +x scripts/new-script.sh`
2. Add error handling: `set -e`
3. Add usage documentation
4. Test on clean system
5. Update this README
