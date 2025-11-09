# Configuration Guide

This guide covers the configuration options for ContainerPub, from environment variables to custom port settings.

## Environment Variables

The primary method for configuring the ContainerPub backend is through environment variables. You can set these in a `.env` file in the project root.

### Main Configuration

```bash
# .env file

# --- Database Configuration ---
# The full URL for connecting to your main PostgreSQL database.
DATABASE_URL=postgres://dart_cloud:your_secure_password@localhost:5432/dart_cloud

# --- Server Configuration ---
# The port the backend server will listen on.
PORT=8080

# The secret key used for signing JWTs. Must be long and random.
JWT_SECRET=your-super-long-and-random-secret-key-here

# The directory where deployed functions are stored.
FUNCTIONS_DIR=./functions
```

### Function Execution Limits

These variables control the resource limits for function execution.

```bash
# --- Function Execution Limits ---
# The maximum time a function can run before being terminated.
FUNCTION_TIMEOUT_SECONDS=5

# The maximum amount of memory a function can use (in MB).
FUNCTION_MAX_MEMORY_MB=128

# The maximum number of functions that can run concurrently.
FUNCTION_MAX_CONCURRENT=10
```

### Database Access for Functions

These variables configure a separate, dedicated database connection pool for functions.

```bash
# --- Database Access for Functions (Optional) ---
# The URL for the functions' database. Use a separate, more restricted user if possible.
FUNCTION_DATABASE_URL=postgres://function_user:function_password@localhost:5432/functions_db

# The maximum number of connections in the function database pool.
FUNCTION_DB_MAX_CONNECTIONS=5

# The timeout for acquiring a connection from the pool (in milliseconds).
FUNCTION_DB_TIMEOUT_MS=5000
```

## Deployment Options

### Manual Podman/Docker (Default)

This method uses the `scripts/deploy.sh` script, which reads the `.env` file directly.

```bash
./scripts/deploy.sh
```

This is best for:
- Quick local development
- Testing changes
- Simple single-server setups

### OpenTofu/Terraform

For infrastructure-as-code deployments, you can use the provided OpenTofu configurations.

```bash
# Install OpenTofu
brew install opentofu

# Deploy with OpenTofu
./scripts/deploy.sh --tofu
```

This is best for:
- Reproducible deployments
- Version-controlled infrastructure
- Team environments

## Custom Ports

To change the default ports for the backend or PostgreSQL, you can edit the Terraform variables in `infrastructure/local/local-podman.tf`:

```hcl
variable "backend_port" {
  description = "The external port for the backend service."
  type        = number
  default     = 9000  # Change from 8080
}

variable "postgres_port" {
  description = "The external port for the PostgreSQL database."
  type        = number
  default     = 5433  # Change from 5432
}
```

Then, redeploy using OpenTofu:

```bash
./scripts/deploy.sh --tofu
```

## CLI Configuration

The CLI tool stores its configuration in `~/.dart_cloud/config.json`. This file is automatically created and managed when you use the `dart_cloud login` and `dart_cloud logout` commands.

### Manual Configuration

You can manually edit this file to change the server URL or auth token.

```bash
# View current config
cat ~/.dart_cloud/config.json

# Manually clear token
rm ~/.dart_cloud/config.json

# Set a custom server URL
echo '{"serverUrl": "http://localhost:9000"}' > ~/.dart_cloud/config.json
```
