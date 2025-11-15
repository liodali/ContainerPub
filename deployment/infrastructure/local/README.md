# Local Podman Infrastructure Documentation

## What is OpenTofu/Terraform?

**OpenTofu** is an open-source infrastructure-as-code (IaC) tool that lets you define and manage infrastructure using configuration files instead of manual commands. It's a fork of Terraform and uses the same syntax.

Think of it like this: Instead of running multiple `podman run` commands manually, you write a configuration file that describes what you want, and OpenTofu creates everything for you automatically.

## What Does This File Do?

The `local-podman.tf` file defines your local development environment for ContainerPub. It creates:

1. **A Podman network** - so containers can talk to each other
2. **A PostgreSQL database container** - for storing data
3. **A backend API container** - your application server
4. **Persistent volumes** - so data survives container restarts

## File Structure Breakdown

### 1. Terraform Block (Lines 1-10)

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    podman = {
      source  = "hashicorp/podman"
      version = "~> 0.1"
    }
  }
}
```

**What it does:** Specifies requirements for running this configuration.
- Requires OpenTofu/Terraform version 1.0 or higher
- Uses the Podman provider to manage Podman containers
- `~> 0.1` means "use version 0.1.x" (any patch version)

### 2. Provider Configuration (Lines 12-18)

```hcl
provider "podman" {
  host = var.podman_socket_path
}
```

**What it does:** Configures how OpenTofu connects to Podman.
- Uses a Unix socket to communicate with Podman
- The socket path varies by OS (macOS vs Linux)

### 3. Variables (Lines 20-63)

Variables are like function parameters - they let you customize the configuration without editing the main code.

| Variable | Default Value | Purpose |
|----------|--------------|---------|
| `podman_socket_path` | `unix:///var/run/podman/podman.sock` | Where Podman listens for commands |
| `postgres_password` | `dev_password` | Database password (marked sensitive) |
| `postgres_user` | `dart_cloud` | Database username |
| `postgres_db` | `dart_cloud` | Database name |
| `backend_port` | `8080` | Port for your API |
| `postgres_port` | `5432` | Port for PostgreSQL |
| `jwt_secret` | `local-dev-secret-change-in-production` | Secret for JWT tokens |

**Note:** Variables marked `sensitive = true` won't be displayed in logs.

### 4. Podman Network (Lines 65-78)

```hcl
resource "podman_network" "containerpub_network" {
  name = "containerpub-network"
  subnet = "10.89.0.0/24"
  gateway = "10.89.0.1"
  driver = "bridge"
}
```

**What it does:** Creates a virtual network for your containers.
- **Subnet:** Defines the IP range (10.89.0.0 to 10.89.0.255)
- **Gateway:** The network's router IP
- **Driver:** Bridge mode allows containers to communicate
- **Labels:** Tags for organization

### 5. PostgreSQL Container (Lines 80-121)

```hcl
resource "podman_container" "postgres" {
  name  = "containerpub-postgres"
  image = "docker.io/library/postgres:15"
  ...
}
```

**What it does:** Creates a PostgreSQL database container.

**Key features:**
- **Environment variables:** Configure the database user, password, and database name
- **Ports:** Maps internal port 5432 to external port (default 5432)
- **Network:** Connects to `containerpub-network` with alias "postgres"
- **Volume:** Mounts persistent storage at `/var/lib/postgresql/data`
- **Healthcheck:** Runs `pg_isready` every 10 seconds to verify the database is running
- **Restart policy:** `unless-stopped` means it auto-restarts unless you manually stop it

### 6. PostgreSQL Volume (Lines 123-131)

```hcl
resource "podman_volume" "postgres_data" {
  name = "containerpub-postgres-data"
}
```

**What it does:** Creates persistent storage for database data.
- Data survives even if you delete the container
- Named volume managed by Podman

### 7. Backend Container (Lines 133-189)

```hcl
resource "podman_container" "backend" {
  name  = "containerpub-backend"
  image = "containerpub-backend:latest"
  ...
}
```

**What it does:** Creates your backend API container.

**Key features:**
- **Image:** Uses `containerpub-backend:latest` (you need to build this first)
- **Environment variables:** Configures database connection, JWT secret, function settings
- **Database URL:** Uses the "postgres" alias to connect (not localhost!)
- **Ports:** Maps port 8080 (or your custom port)
- **Volume:** Mounts functions storage
- **Healthcheck:** Checks `/api/health` endpoint every 30 seconds
- **Depends on:** Won't start until PostgreSQL is running

### 8. Functions Volume (Lines 191-199)

```hcl
resource "podman_volume" "functions_data" {
  name = "containerpub-functions-data"
}
```

**What it does:** Creates persistent storage for serverless functions.

### 9. Outputs (Lines 201-226)

```hcl
output "backend_url" {
  value = "http://localhost:${var.backend_port}"
}
```

**What it does:** Displays useful information after deployment.

Outputs include:
- **postgres_connection_string:** How to connect to the database from your host
- **backend_url:** Where to access your API
- **Container IDs:** For debugging
- **Network name:** For reference

## How to Use This Configuration

### Prerequisites

1. Install OpenTofu: `brew install opentofu` (macOS)
2. Install Podman: `brew install podman` (macOS)
3. Start Podman machine: `podman machine start`

### Basic Commands

```bash
# Navigate to the infrastructure directory
cd /Users/dalihamza/Desktop/DevOps/ContainerPub/infrastructure/local

# Initialize OpenTofu (downloads providers)
tofu init

# Preview what will be created
tofu plan

# Create the infrastructure
tofu apply

# View outputs
tofu output

# Destroy everything
tofu destroy
```

### Before Running `tofu apply`

You need to build the backend image first:

```bash
cd /Users/dalihamza/Desktop/DevOps/ContainerPub
podman build -t containerpub-backend:latest -f infrastructure/Dockerfile.backend .
```

### Customizing Variables

Create a `terraform.tfvars` file in the same directory:

```hcl
postgres_password = "my_secure_password"
backend_port = 9000
jwt_secret = "my-super-secret-key"
```

Or pass variables via command line:

```bash
tofu apply -var="backend_port=9000"
```

## Key Concepts

### Resources

Resources are the building blocks (containers, networks, volumes). Format:

```hcl
resource "TYPE" "NAME" {
  # configuration
}
```

You reference them elsewhere as: `TYPE.NAME` (e.g., `podman_container.postgres`)

### Dependencies

OpenTofu automatically figures out dependencies:
- Backend depends on PostgreSQL (explicit: `depends_on`)
- Containers depend on network (implicit: references the network)
- Containers depend on volumes (implicit: references the volumes)

### State

OpenTofu tracks what it created in a `terraform.tfstate` file. Don't edit this manually!

## Common Operations

### Check Container Status

```bash
podman ps
```

### View Logs

```bash
podman logs containerpub-postgres
podman logs containerpub-backend
```

### Connect to Database

```bash
podman exec -it containerpub-postgres psql -U dart_cloud -d dart_cloud
```

### Restart a Container

```bash
tofu apply -replace=podman_container.backend
```

## Troubleshooting

### "Error: Cannot connect to Podman socket"

Check if Podman machine is running:
```bash
podman machine list
podman machine start
```

### "Error: Image not found"

Build the backend image first:
```bash
podman build -t containerpub-backend:latest -f infrastructure/Dockerfile.backend .
```

### "Port already in use"

Change the port in `terraform.tfvars`:
```hcl
backend_port = 8081
postgres_port = 5433
```

### View Current State

```bash
tofu show
```

## Benefits of Using OpenTofu

1. **Reproducible:** Same configuration = same result every time
2. **Version controlled:** Track changes in Git
3. **Declarative:** Describe what you want, not how to create it
4. **Idempotent:** Running `tofu apply` multiple times is safe
5. **Easy cleanup:** One command (`tofu destroy`) removes everything

## Next Steps

- Modify variables in `terraform.tfvars` for your needs
- Add more containers by creating new `resource "podman_container"` blocks
- Use `tofu plan` to preview changes before applying
- Check the [OpenTofu documentation](https://opentofu.org/docs/) for advanced features
