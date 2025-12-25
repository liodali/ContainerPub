#!/bin/bash

clear

# Quick start script for Dart Cloud Backend with Docker Compose

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

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

# Check if Docker is installed
if [ ! command -v docker &> /dev/null ] && [ ! command -v podman &> /dev/null ]; then
    print_error "you dont have any container runtime installed"
    echo "Install Docker: https://docs.docker.com/get-docker/ or Podman: https://podman.io/getting-started/installation"
    exit 1
fi

# Check if Docker Compose is available
if [ ! docker compose version &> /dev/null ] && [ ! podman-compose version &> /dev/null ]; then
    print_error "Docker Compose is not available"
    echo "Install Docker Compose: https://docs.docker.com/compose/install/ or Podman Compose: https://podman.io/getting-started/compose"
    exit 1
fi

CONTAINER_RUNTIME="sudo docker"
CONTAINER_COMPOSE_RUNTIME="sudo docker compose"
if ! command -v docker &> /dev/null; then
    CONTAINER_RUNTIME="podman"
    CONTAINER_COMPOSE_RUNTIME="podman-compose"
fi


print_header "Dart Cloud Backend - Quick Start"

# Function to cleanup on failure
cleanup_on_failure() {
    print_error "Deployment failed. Cleaning up..."
    
    print_info "Stopping containers..."
    $CONTAINER_COMPOSE_RUNTIME stop 2>/dev/null || true
    
    print_info "Removing containers..."
    $CONTAINER_COMPOSE_RUNTIME rm -f backend-cloud postgres 2>/dev/null || true
    
    print_info "Removing network..."
    $CONTAINER_COMPOSE_RUNTIME down 2>/dev/null || true
    
    # Clean up temporary .env files
    # rm -rf .env 2>/dev/null || true
    # rm -rf ../.env 2>/dev/null || true
    
    print_success "Cleanup completed"
    exit 1
}
print_failue(){
    echo ""
    echo -e "${RED}✗ Deployment failed!${NC}"
    echo ""
    exit 1
}
print_done(){
    echo ""
    echo -e "${GREEN}✓ All services are running successfully!${NC}"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Service Endpoints:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  Backend API:  ${GREEN}http://localhost:8080${NC}"
    echo -e "  Health Check: ${GREEN}http://localhost:8080/health${NC}"
    echo -e "  PostgreSQL:   ${GREEN}postgres:5432${NC} (internal network)"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Management Commands:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  View all logs:       ${YELLOW}$CONTAINER_COMPOSE_RUNTIME logs -f${NC}"
    echo -e "  View backend logs:   ${YELLOW}$CONTAINER_COMPOSE_RUNTIME logs -f backend-cloud${NC}"
    echo -e "  View postgres logs:  ${YELLOW}$CONTAINER_COMPOSE_RUNTIME logs -f postgres${NC}"
    echo -e "  Stop services:       ${YELLOW}$CONTAINER_COMPOSE_RUNTIME down${NC}"
    echo -e "  Restart backend:     ${YELLOW}$CONTAINER_COMPOSE_RUNTIME restart backend-cloud${NC}"
    echo -e "  Restart postgres:    ${YELLOW}$CONTAINER_COMPOSE_RUNTIME restart postgres${NC}"
    echo -e "  View status:         ${YELLOW}$CONTAINER_COMPOSE_RUNTIME ps${NC}"
    echo -e "  Rebuild & restart:   ${YELLOW}./start.sh${NC}"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Database Access:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  Connect to DB:       ${YELLOW}$CONTAINER_COMPOSE_RUNTIME exec postgres psql -U dart_cloud -d dart_cloud${NC}"
    echo -e "  Check DB status:     ${YELLOW}$CONTAINER_COMPOSE_RUNTIME exec postgres pg_isready -U dart_cloud${NC}"
    echo ""

}

# Set trap for cleanup on error
trap cleanup_on_failure ERR

# Check if services are already running
POSTGRES_RUNNING=false
BACKEND_RUNNING=false
POSTGRES_EXISTS=false
BACKEND_EXISTS=false
SKIP_BUILD=false

print_info "Checking if services are already running..."

if $CONTAINER_RUNTIME ps | grep -q "dart_cloud_postgres.*Up"; then
    POSTGRES_RUNNING=true
    POSTGRES_EXISTS=true
    print_info "PostgreSQL is already running"
fi

if $CONTAINER_RUNTIME ps | grep -q "dart_cloud_backend.*Up"; then
    BACKEND_RUNNING=true
    BACKEND_EXISTS=true
    print_info "Backend is already running"
fi

# Check if services exist but are stopped
if $CONTAINER_RUNTIME ps -a | grep -q "dart_cloud_postgres"; then
    POSTGRES_EXISTS=true
fi

if $CONTAINER_RUNTIME ps -a | grep -q "dart_cloud_backend"; then
    BACKEND_EXISTS=true
fi

# If services exist but are stopped (not running), ask what to do
if ([ "$POSTGRES_EXISTS" = true ] || [ "$BACKEND_EXISTS" = true ]) && [ "$POSTGRES_RUNNING" = false ] && [ "$BACKEND_RUNNING" = false ]; then
    print_header "Services Exist But Are Stopped"
    
    echo -e "${BLUE}Current status:${NC}"
    echo -e "  PostgreSQL: $([ "$POSTGRES_EXISTS" = true ] && echo "${YELLOW}Stopped${NC}" || echo "${RED}Not Found${NC}")"
    echo -e "  Backend:    $([ "$BACKEND_EXISTS" = true ] && echo "${YELLOW}Stopped${NC}" || echo "${RED}Not Found${NC}")"
    echo ""
    
    echo -e "${BLUE}What would you like to do?${NC}"
    echo "  1) Start stopped services (without rebuilding)"
    echo "  2) Rebuild backend only (keep PostgreSQL and data)"
    echo "  3) Cancel and exit"
    echo ""
    
    read -p "Enter your choice (1-3): " -n 1 -r
    echo ""
    
    case $REPLY in
        1)
            print_info "Starting stopped services..."
            if [ "$POSTGRES_EXISTS" = true ]; then
                print_info "Starting PostgreSQL..."
                $CONTAINER_COMPOSE_RUNTIME start postgres 2>/dev/null || true
            fi
            if [ "$BACKEND_EXISTS" = true ]; then
                print_info "Starting Backend..."
                $CONTAINER_COMPOSE_RUNTIME start backend-cloud 2>/dev/null || true
            fi
            print_success "Services started"
            SKIP_BUILD=true
            ;;
        2)
            print_info "Rebuilding backend only..."
            $CONTAINER_RUNTIME stop dart_cloud_backend 2>/dev/null || true
            $CONTAINER_RUNTIME rm -f dart_cloud_backend 2>/dev/null || true
            $CONTAINER_RUNTIME rmi $($CONTAINER_RUNTIME images -f "label=stage=builder-intermediate" -q) 2>/dev/null || true
            print_info "Removing backend image..."
            $CONTAINER_RUNTIME rmi dart_cloud_backend 2>/dev/null || true
            ;;
        3)
            print_info "Cancelled"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

# If services are running, ask what to do
elif [ "$POSTGRES_RUNNING" = true ] || [ "$BACKEND_RUNNING" = true ]; then
    print_header "Services Already Running"
    
    echo -e "${BLUE}Current status:${NC}"
    echo -e "  PostgreSQL: $([ "$POSTGRES_RUNNING" = true ] && echo "${GREEN}Running${NC}" || echo "${YELLOW}Stopped${NC}")"
    echo -e "  Backend:    $([ "$BACKEND_RUNNING" = true ] && echo "${GREEN}Running${NC}" || echo "${YELLOW}Stopped${NC}")"
    echo ""
    
    echo -e "${BLUE}What would you like to do?${NC}"
    echo "  1) Start stopped services (without rebuilding)"
    echo "  2) Rebuild backend only (keep PostgreSQL and data)"
    echo "  3) Rebuild backend and remove its volume"
    echo "  4) Remove everything (PostgreSQL + Backend + all volumes)"
    echo "  5) Cancel and exit"
    echo ""
    
    read -p "Enter your choice (1-5): " -n 1 -r
    echo ""
    
    case $REPLY in
        1)
            print_info "Starting stopped services..."
            if [ "$POSTGRES_RUNNING" = false ]; then
                print_info "Starting PostgreSQL..."
                $CONTAINER_COMPOSE_RUNTIME start postgres 2>/dev/null || true
            fi
            if [ "$BACKEND_RUNNING" = false ]; then
                print_info "Starting Backend..."
                $CONTAINER_COMPOSE_RUNTIME start backend-cloud 2>/dev/null || true
            fi
            print_success "Services started"
            SKIP_BUILD=true
            ;;
        2)
            print_info "Rebuilding backend only..."
            $CONTAINER_COMPOSE_RUNTIME -p dart_cloud up  -d --force-recreate --build backend-cloud
            SKIP_BUILD=true
            ;;
        3)
            print_info "Rebuilding backend and removing its volume..."
            $CONTAINER_RUNTIME stop dart_cloud_backend 2>/dev/null || true
            $CONTAINER_RUNTIME rm -f dart_cloud_backend 2>/dev/null || true
            print_info "dart_cloud_backend container removed..."
            $CONTAINER_RUNTIME volume rm dart_cloud_backend_functions_data 2>/dev/null || true
            print_success "Backend volume removed"
            print_info "Removing backend image..."
            $CONTAINER_RUNTIME rmi dart_cloud_backend 2>/dev/null || true
            $CONTAINER_COMPOSE_RUNTIME -p dart_cloud up  -d --force-recreate --build backend-cloud
            SKIP_BUILD=true
            ;;
        4)
            print_warning "This will remove all data!"
            read -p "Are you sure? (y/N): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_info "Removing everything..."
                $CONTAINER_COMPOSE_RUNTIME down -v
                $CONTAINER_RUNTIME rmi $($CONTAINER_RUNTIME images -f "label=stage=builder-intermediate" -q)
                print_success "All services and volumes removed"
            else
                print_info "Cancelled"
                exit 0
            fi
            ;;
        5)
            print_info "Cancelled"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
fi

# Check if .env exists
if [ ! -f .env ]; then
    print_warning ".env file not found"
    
    if [ -f .env.example ]; then
        print_info "Creating .env from .env.example..."
        cp .env.example .env
        cp .env ../.env
        
        # Generate secure passwords
        if command -v openssl &> /dev/null; then
            print_info "Generating secure passwords..."
            POSTGRES_PASSWORD=$(openssl rand -base64 256 | tr -dc 'a-zA-Z0-9' | head -c 32)  #$(openssl rand -base64 32 | tr -d '\n')
            JWT_SECRET=$(openssl rand -base64 256 | tr -dc 'a-zA-Z0-9' | head -c 128) #$(openssl rand -base64 128 | tr -d '\n')
            
            # Update .env file
            if [[ "$OSTYPE" == "darwin"* ]]; then
                echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD:0:10}******"
                echo "JWT_SECRET=${JWT_SECRET:0:10}******"
                # macOS
                sed -i '' "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=\"${POSTGRES_PASSWORD}\"/" .env
                sed -i '' "s/JWT_SECRET=.*/JWT_SECRET=\"${JWT_SECRET}\"/" .env
            else
                # Linux
                sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=\"${POSTGRES_PASSWORD}\"/" .env
                sed -i "s/JWT_SECRET=.*/JWT_SECRET=\"${JWT_SECRET}\"/" .env
            fi
            
            print_success "Secure passwords generated"
        else
            print_warning "openssl not found, using example values"
            print_warning "Please update POSTGRES_PASSWORD and JWT_SECRET in .env file"
        fi
        
        chmod 600 .env
        print_success ".env file created"
    else
        print_error ".env.example not found"
        exit 1
    fi
else
    print_success ".env file found"
fi


# if [ ! -f ../s3_client_dart.so ]; then
#     print_info "Downloading s3_client_dart library..."
#     if ! dart run ../bin/download_library.dart; then
#         print_error "Failed to download s3_client_dart library"
#         cleanup_on_failure
#     fi
# fi

if [ "$SKIP_BUILD" = false ]; then
    # Start services
    print_header "Starting Services"

    print_info "Building and starting containers..."
    if ! $CONTAINER_COMPOSE_RUNTIME -p dart_cloud up  -d --force-recreate --build ; then
        print_error "Failed to start services"
        cleanup_on_failure
    else
        $CONTAINER_RUNTIME rmi $($CONTAINER_RUNTIME images -f "label=stage=builder-intermediate" -q) 2>/dev/null || true
        print_success "Services started"
    fi
fi
# Wait for services to be healthy
print_info "Waiting for services to be ready..."
sleep 5

# Check PostgreSQL
print_info "Checking PostgreSQL..."
POSTGRES_READY=false
for i in {1..30}; do
    if $CONTAINER_COMPOSE_RUNTIME exec -T postgres pg_isready -U dart_cloud &>/dev/null; then
        print_success "PostgreSQL is ready"
        POSTGRES_READY=true
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "PostgreSQL failed to start"
        echo ""
        print_info "PostgreSQL logs:"
        $CONTAINER_COMPOSE_RUNTIME logs postgres
        cleanup_on_failure
    fi
    sleep 1
done

# Check Backend
print_info "Checking Backend..."
BACKEND_READY=false
for i in {1..10}; do
    if curl -sf http://localhost:8080/health &>/dev/null; then
        print_success "Backend is ready"
        BACKEND_READY=true
        break
    fi
    if [ $i -eq 10 ]; then
        print_error "Backend failed to start"
        echo ""
        print_info "Backend logs:"
        $CONTAINER_COMPOSE_RUNTIME logs backend-cloud
        cleanup_on_failure
    fi
    sleep 1
done

# Verify both services are ready
if [ "$POSTGRES_READY" = false ] || [ "$BACKEND_READY" = false ]; then
    print_error "One or more services failed to start"
    echo ""
    echo "PostgreSQL logs:"
    $CONTAINER_COMPOSE_RUNTIME logs postgres
    echo ""
    echo "Backend logs:"
    $CONTAINER_COMPOSE_RUNTIME logs backend-cloud
    echo ""
        
    print_header "Backend Service Check Failed"
    echo -e "${BLUE}What would you like to do?${NC}"
    echo "  1) Remove everything (PostgreSQL + Backend + all volumes)"
    echo "  2) Skip this action and exit"
    echo ""
        
    read -p "Enter your choice (1-2): " -n 1 -r
    echo ""
        
    case $REPLY in
        1)
            print_warning "This will remove all data!"
            read -p "Are you sure? (y/N): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cleanup_on_failure
                print_failue
            else
                print_info "Cancelled removal, exiting..."
                print_failue
            fi
            ;;
        2)
            print_info "Skipping cleanup, exiting..."
            print_failue
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

else
    print_header "Deployment Complete!"
fi
# # Clean up temporary .env files
# rm -rf .env 2>/dev/null || true
# rm -rf ../.env 2>/dev/null || true
# print_success "Temporary .env files cleaned up"

print_done