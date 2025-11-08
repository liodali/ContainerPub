#!/bin/bash

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
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    echo "Install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available"
    echo "Install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

print_header "Dart Cloud Backend - Quick Start"

# Check if .env exists
if [ ! -f .env ]; then
    print_warning ".env file not found"
    
    if [ -f .env.example ]; then
        print_info "Creating .env from .env.example..."
        cp .env.example .env
        
        # Generate secure passwords
        if command -v openssl &> /dev/null; then
            print_info "Generating secure passwords..."
            POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
            JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
            
            # Update .env file
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS
                sed -i '' "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" .env
                sed -i '' "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
            else
                # Linux
                sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" .env
                sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
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

# Start services
print_header "Starting Services"

print_info "Building and starting containers..."
docker compose up -d --build

# Wait for services to be healthy
print_info "Waiting for services to be ready..."
sleep 5

# Check PostgreSQL
print_info "Checking PostgreSQL..."
for i in {1..30}; do
    if docker compose exec -T postgres pg_isready -U dart_cloud &>/dev/null; then
        print_success "PostgreSQL is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "PostgreSQL failed to start"
        docker compose logs postgres
        exit 1
    fi
    sleep 1
done

# Check Backend
print_info "Checking Backend..."
for i in {1..30}; do
    if curl -sf http://localhost:8080/api/health &>/dev/null; then
        print_success "Backend is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "Backend failed to start"
        docker compose logs backend
        exit 1
    fi
    sleep 1
done

print_header "Deployment Complete!"

echo -e "${GREEN}Services are running:${NC}"
echo -e "  Backend API:  ${BLUE}http://localhost:8080${NC}"
echo -e "  Health Check: ${BLUE}http://localhost:8080/api/health${NC}"
echo -e "  PostgreSQL:   ${BLUE}localhost:5432${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  View logs:        ${YELLOW}docker compose logs -f${NC}"
echo -e "  Stop services:    ${YELLOW}docker compose down${NC}"
echo -e "  Restart backend:  ${YELLOW}docker compose restart backend${NC}"
echo -e "  View status:      ${YELLOW}docker compose ps${NC}"
echo ""
echo -e "${BLUE}Database access:${NC}"
echo -e "  ${YELLOW}docker compose exec postgres psql -U dart_cloud -d dart_cloud${NC}"
echo ""
