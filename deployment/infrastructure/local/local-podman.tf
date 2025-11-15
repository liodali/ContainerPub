terraform {
  required_version = ">= 1.0"
  
  required_providers {
    podman = {
      source  = "hashicorp/podman"
      version = "~> 0.1"
    }
  }
}

# Provider configuration for Podman
provider "podman" {
  # Podman socket path (default for macOS/Linux)
  # For macOS: unix:///var/run/podman/podman.sock
  # For Linux: unix:///run/podman/podman.sock
  host = var.podman_socket_path
}

# Variables
variable "podman_socket_path" {
  description = "Podman socket path"
  type        = string
  default     = "unix:///var/run/podman/podman.sock"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  default     = "dev_password"
  sensitive   = true
}

variable "postgres_user" {
  description = "PostgreSQL user"
  type        = string
  default     = "dart_cloud"
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "dart_cloud"
}

variable "backend_port" {
  description = "Backend API port"
  type        = number
  default     = 8080
}

variable "postgres_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "jwt_secret" {
  description = "JWT secret for authentication"
  type        = string
  default     = "local-dev-secret-change-in-production"
  sensitive   = true
}

# Podman network for ContainerPub
resource "podman_network" "containerpub_network" {
  name = "containerpub-network"
  
  subnet = "10.89.0.0/24"
  gateway = "10.89.0.1"
  
  driver = "bridge"
  
  labels = {
    app = "containerpub"
    environment = "local"
  }
}

# PostgreSQL container
resource "podman_container" "postgres" {
  name  = "containerpub-postgres"
  image = "docker.io/library/postgres:15"
  
  env = [
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_DB=${var.postgres_db}",
  ]
  
  ports {
    internal = 5432
    external = var.postgres_port
    protocol = "tcp"
  }
  
  networks_advanced {
    name = podman_network.containerpub_network.name
    aliases = ["postgres"]
  }
  
  volumes {
    volume_name   = podman_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }
  
  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.postgres_user}"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
  
  labels = {
    app = "containerpub"
    component = "database"
    environment = "local"
  }
  
  restart = "unless-stopped"
}

# PostgreSQL data volume
resource "podman_volume" "postgres_data" {
  name = "containerpub-postgres-data"
  
  labels = {
    app = "containerpub"
    component = "database"
  }
}

# Backend container
resource "podman_container" "backend" {
  name  = "containerpub-backend"
  image = "containerpub-backend:latest"
  
  # Build from Dockerfile if image doesn't exist
  # Note: You'll need to build the image first with:
  # podman build -t containerpub-backend:latest -f infrastructure/Dockerfile.backend .
  
  env = [
    "PORT=${var.backend_port}",
    "DATABASE_URL=postgres://${var.postgres_user}:${var.postgres_password}@postgres:5432/${var.postgres_db}",
    "FUNCTION_DATABASE_URL=postgres://${var.postgres_user}:${var.postgres_password}@postgres:5432/functions_db",
    "JWT_SECRET=${var.jwt_secret}",
    "FUNCTIONS_DIR=/app/functions",
    "FUNCTION_TIMEOUT_SECONDS=5",
    "FUNCTION_MAX_MEMORY_MB=128",
    "FUNCTION_MAX_CONCURRENT=10",
    "FUNCTION_DB_MAX_CONNECTIONS=5",
    "FUNCTION_DB_TIMEOUT_MS=5000",
  ]
  
  ports {
    internal = var.backend_port
    external = var.backend_port
    protocol = "tcp"
  }
  
  networks_advanced {
    name = podman_network.containerpub_network.name
    aliases = ["backend"]
  }
  
  volumes {
    volume_name   = podman_volume.functions_data.name
    container_path = "/app/functions"
  }
  
  healthcheck {
    test     = ["CMD", "curl", "-f", "http://localhost:${var.backend_port}/api/health"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
  }
  
  labels = {
    app = "containerpub"
    component = "backend"
    environment = "local"
  }
  
  depends_on = [
    podman_container.postgres
  ]
  
  restart = "unless-stopped"
}

# Functions data volume
resource "podman_volume" "functions_data" {
  name = "containerpub-functions-data"
  
  labels = {
    app = "containerpub"
    component = "functions"
  }
}

# Outputs
output "postgres_connection_string" {
  value       = "postgres://${var.postgres_user}:${var.postgres_password}@localhost:${var.postgres_port}/${var.postgres_db}"
  description = "PostgreSQL connection string"
  sensitive   = true
}

output "backend_url" {
  value       = "http://localhost:${var.backend_port}"
  description = "Backend API URL"
}

output "postgres_container_id" {
  value       = podman_container.postgres.id
  description = "PostgreSQL container ID"
}

output "backend_container_id" {
  value       = podman_container.backend.id
  description = "Backend container ID"
}

output "network_name" {
  value       = podman_network.containerpub_network.name
  description = "Podman network name"
}
