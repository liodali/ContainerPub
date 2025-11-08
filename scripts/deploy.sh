#!/bin/bash

# Deployment script for ContainerPub infrastructure
# This script builds and deploys the backend and database containers

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRASTRUCTURE_DIR="$PROJECT_ROOT/infrastructure"
BACKEND_IMAGE="containerpub-backend:latest"
POSTGRES_IMAGE="containerpub-postgres:latest"
ENV_FILE="$PROJECT_ROOT/.env"

# Default values
BUILD_BACKEND=true
BUILD_POSTGRES=true
START_CONTAINERS=true
USE_TOFU=false

# Load environment variables from .env file if it exists
load_env() {
    if [ -f "$ENV_FILE" ]; then
        print_info "Loading environment variables from .env file..."
        set -a  # automatically export all variables
        source "$ENV_FILE"
        set +a
        print_success "Environment variables loaded"
    else
        print_warning ".env file not found at $ENV_FILE"
        print_warning "Using default values. For production, create .env from .env.example"
        # Set default values for development
        export POSTGRES_USER="${POSTGRES_USER:-dart_cloud}"
        export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-dev_password}"
        export POSTGRES_DB="${POSTGRES_DB:-dart_cloud}"
        export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
        export BACKEND_PORT="${BACKEND_PORT:-8080}"
        export JWT_SECRET="${JWT_SECRET:-local-dev-secret-change-in-production}"
    fi
}

# Functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy ContainerPub infrastructure using Podman

OPTIONS:
    -h, --help              Show this help message
    -b, --backend-only      Build and deploy backend only
    -p, --postgres-only     Build and deploy PostgreSQL only
    -n, --no-build          Skip building images
    -t, --tofu              Use OpenTofu to deploy (default: manual podman)
    --no-start              Build images but don't start containers
    --clean                 Remove existing containers and volumes before deploying

EXAMPLES:
    $0                      # Build and deploy everything
    $0 --backend-only       # Only build and deploy backend
    $0 --tofu               # Use OpenTofu for deployment
    $0 --clean              # Clean deploy (removes existing data)

EOF
}

check_dependencies() {
    print_header "Checking Dependencies"
    
    local missing_deps=()
    
    if ! command -v podman &> /dev/null; then
        missing_deps+=("podman")
    fi
    
    if [ "$USE_TOFU" = true ] && ! command -v tofu &> /dev/null; then
        missing_deps+=("tofu")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                podman)
                    echo "  brew install podman"
                    ;;
                tofu)
                    echo "  brew install opentofu"
                    ;;
            esac
        done
        exit 1
    fi
    
    print_success "All dependencies found"
    
    # Check if podman machine is running
    if ! podman machine list | grep -q "Currently running"; then
        print_warning "Podman machine is not running"
        print_info "Starting podman machine..."
        podman machine start
    fi
    
    print_success "Podman machine is running"
}

build_postgres() {
    print_header "Building PostgreSQL Image"
    
    print_info "Building $POSTGRES_IMAGE..."
    podman build \
        -t "$POSTGRES_IMAGE" \
        -f "$INFRASTRUCTURE_DIR/Dockerfile.postgres" \
        "$PROJECT_ROOT"
    
    print_success "PostgreSQL image built successfully"
}

build_backend() {
    print_header "Building Backend Image"
    
    print_info "Building $BACKEND_IMAGE..."
    podman build \
        -t "$BACKEND_IMAGE" \
        -f "$INFRASTRUCTURE_DIR/Dockerfile.backend" \
        "$PROJECT_ROOT"
    
    print_success "Backend image built successfully"
}

clean_deployment() {
    print_header "Cleaning Existing Deployment"
    
    print_info "Stopping and removing containers..."
    podman stop containerpub-backend containerpub-postgres 2>/dev/null || true
    podman rm containerpub-backend containerpub-postgres 2>/dev/null || true
    
    print_warning "Removing volumes (data will be lost)..."
    podman volume rm containerpub-postgres-data containerpub-functions-data 2>/dev/null || true
    
    print_info "Removing network..."
    podman network rm containerpub-network 2>/dev/null || true
    
    print_success "Cleanup completed"
}

deploy_manual() {
    print_header "Deploying with Podman"
    
    # Create network
    print_info "Creating network..."
    if ! podman network exists containerpub-network 2>/dev/null; then
        podman network create \
            --subnet 10.89.0.0/24 \
            --gateway 10.89.0.1 \
            containerpub-network
        print_success "Network created"
    else
        print_info "Network already exists"
    fi
    
    # Create volumes
    print_info "Creating volumes..."
    podman volume create containerpub-postgres-data 2>/dev/null || true
    podman volume create containerpub-functions-data 2>/dev/null || true
    print_success "Volumes created"
    
    # Start PostgreSQL
    print_info "Starting PostgreSQL container..."
    podman run -d \
        --name containerpub-postgres \
        --network containerpub-network \
        --network-alias postgres \
        -p "${POSTGRES_PORT}:5432" \
        -v containerpub-postgres-data:/var/lib/postgresql/data \
        -e POSTGRES_USER="${POSTGRES_USER}" \
        -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
        -e POSTGRES_DB="${POSTGRES_DB}" \
        --restart unless-stopped \
        "$POSTGRES_IMAGE"
    
    print_success "PostgreSQL container started"
    
    # Wait for PostgreSQL to be ready
    print_info "Waiting for PostgreSQL to be ready..."
    sleep 5
    for i in {1..30}; do
        if podman exec containerpub-postgres pg_isready -U "${POSTGRES_USER}" &>/dev/null; then
            print_success "PostgreSQL is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "PostgreSQL failed to start"
            exit 1
        fi
        sleep 1
    done
    
    # Start Backend
    print_info "Starting Backend container..."
    podman run -d \
        --name containerpub-backend \
        --network containerpub-network \
        --network-alias backend \
        -p "${BACKEND_PORT}:${BACKEND_PORT}" \
        -v containerpub-functions-data:/app/functions \
        -e PORT="${BACKEND_PORT}" \
        -e DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}" \
        -e FUNCTION_DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/functions_db" \
        -e JWT_SECRET="${JWT_SECRET}" \
        -e FUNCTIONS_DIR="/app/functions" \
        -e FUNCTION_TIMEOUT_SECONDS="${FUNCTION_TIMEOUT_SECONDS:-5}" \
        -e FUNCTION_MAX_MEMORY_MB="${FUNCTION_MAX_MEMORY_MB:-128}" \
        -e FUNCTION_MAX_CONCURRENT="${FUNCTION_MAX_CONCURRENT:-10}" \
        -e FUNCTION_DB_MAX_CONNECTIONS="${FUNCTION_DB_MAX_CONNECTIONS:-5}" \
        -e FUNCTION_DB_TIMEOUT_MS="${FUNCTION_DB_TIMEOUT_MS:-5000}" \
        --restart unless-stopped \
        "$BACKEND_IMAGE"
    
    print_success "Backend container started"
    
    # Wait for backend to be ready
    print_info "Waiting for backend to be ready..."
    sleep 3
    for i in {1..30}; do
        if curl -sf "http://localhost:${BACKEND_PORT}/api/health" &>/dev/null; then
            print_success "Backend is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            print_warning "Backend health check timeout (may still be starting)"
        fi
        sleep 1
    done
}

deploy_tofu() {
    print_header "Deploying with OpenTofu"
    
    cd "$INFRASTRUCTURE_DIR/local"
    
    print_info "Initializing OpenTofu..."
    tofu init
    
    # Export variables for OpenTofu
    export TF_VAR_postgres_password="${POSTGRES_PASSWORD}"
    export TF_VAR_postgres_user="${POSTGRES_USER}"
    export TF_VAR_postgres_db="${POSTGRES_DB}"
    export TF_VAR_postgres_port="${POSTGRES_PORT}"
    export TF_VAR_backend_port="${BACKEND_PORT}"
    export TF_VAR_jwt_secret="${JWT_SECRET}"
    
    print_info "Planning deployment..."
    tofu plan
    
    print_info "Applying configuration..."
    tofu apply -auto-approve
    
    print_success "Deployment completed with OpenTofu"
}

show_status() {
    print_header "Deployment Status"
    
    echo -e "${BLUE}Containers:${NC}"
    podman ps --filter "label=app=containerpub" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n${BLUE}Volumes:${NC}"
    podman volume ls --filter "label=app=containerpub" --format "table {{.Name}}\t{{.Driver}}"
    
    echo -e "\n${BLUE}Network:${NC}"
    podman network ls --filter "label=app=containerpub" --format "table {{.Name}}\t{{.Driver}}"
    
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Deployment Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${BLUE}Access your services:${NC}"
    echo -e "  Backend API:  ${GREEN}http://localhost:${BACKEND_PORT}${NC}"
    echo -e "  PostgreSQL:   ${GREEN}localhost:${POSTGRES_PORT}${NC}"
    echo -e "  Database:     ${GREEN}${POSTGRES_DB}${NC}"
    echo -e "  User:         ${GREEN}${POSTGRES_USER}${NC}"
    echo ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo -e "  View logs:    ${YELLOW}podman logs -f containerpub-backend${NC}"
    echo -e "  Stop all:     ${YELLOW}podman stop containerpub-backend containerpub-postgres${NC}"
    echo -e "  Start all:    ${YELLOW}podman start containerpub-postgres containerpub-backend${NC}"
    echo ""
}

# Parse arguments
CLEAN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -b|--backend-only)
            BUILD_POSTGRES=false
            ;;
        -p|--postgres-only)
            BUILD_BACKEND=false
            ;;
        -n|--no-build)
            BUILD_BACKEND=false
            BUILD_POSTGRES=false
            ;;
        -t|--tofu)
            USE_TOFU=true
            ;;
        --no-start)
            START_CONTAINERS=false
            ;;
        --clean)
            CLEAN=true
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    shift
done

# Main execution
main() {
    print_header "ContainerPub Deployment"
    
    # Load environment variables first
    load_env
    
    check_dependencies
    
    if [ "$CLEAN" = true ]; then
        clean_deployment
    fi
    
    if [ "$BUILD_POSTGRES" = true ]; then
        build_postgres
    fi
    
    if [ "$BUILD_BACKEND" = true ]; then
        build_backend
    fi
    
    if [ "$START_CONTAINERS" = true ]; then
        if [ "$USE_TOFU" = true ]; then
            deploy_tofu
        else
            deploy_manual
        fi
        
        show_status
    else
        print_success "Images built successfully (containers not started)"
    fi
}

# Run main function
main
