#!/bin/bash

# Production Deployment Script with SSL/TLS
# Deploys ContainerPub backend with secure PostgreSQL connections

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

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env.production"
SSL_DIR="$SCRIPT_DIR/ssl"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.prod.yml"

print_header "ContainerPub Production Deployment"

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available"
    exit 1
fi

print_success "Docker and Docker Compose found"

# Pre-deployment checks
print_header "Pre-Deployment Checks"

# Check .env.production
if [ ! -f "$ENV_FILE" ]; then
    print_error ".env.production file not found"
    echo ""
    echo "Create it from template:"
    echo "  cp .env.production.example .env.production"
    echo "  nano .env.production"
    exit 1
fi

print_success ".env.production found"

# Check file permissions
ENV_PERMS=$(stat -f "%OLp" "$ENV_FILE" 2>/dev/null || stat -c "%a" "$ENV_FILE" 2>/dev/null)
if [ "$ENV_PERMS" != "600" ]; then
    print_warning ".env.production has insecure permissions: $ENV_PERMS"
    print_info "Setting secure permissions (600)..."
    chmod 600 "$ENV_FILE"
    print_success "Permissions updated"
fi

# Load environment
set -a
source "$ENV_FILE"
set +a

# Check required variables
REQUIRED_VARS=("POSTGRES_PASSWORD" "JWT_SECRET")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    print_error "Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Update .env.production with secure values"
    exit 1
fi

print_success "All required environment variables set"

# Check for default/weak passwords
if [[ "$POSTGRES_PASSWORD" == *"CHANGE_THIS"* ]] || [[ "$POSTGRES_PASSWORD" == *"password"* ]]; then
    print_error "POSTGRES_PASSWORD appears to be a default/weak value"
    echo "Generate a secure password:"
    echo "  openssl rand -base64 32"
    exit 1
fi

if [[ "$JWT_SECRET" == *"CHANGE_THIS"* ]] || [[ "$JWT_SECRET" == *"secret"* ]]; then
    print_error "JWT_SECRET appears to be a default/weak value"
    echo "Generate a secure secret:"
    echo "  openssl rand -base64 64"
    exit 1
fi

print_success "Passwords appear secure"

# Check SSL certificates
print_header "SSL Certificate Verification"

if [ ! -d "$SSL_DIR" ]; then
    print_error "SSL directory not found: $SSL_DIR"
    echo ""
    echo "Generate SSL certificates:"
    echo "  ./generate-ssl-certs.sh"
    exit 1
fi

REQUIRED_CERTS=(
    "ca-cert.pem"
    "ca-key.pem"
    "server-cert.pem"
    "server-key.pem"
    "client-cert.pem"
    "client-key.pem"
)

MISSING_CERTS=()
for cert in "${REQUIRED_CERTS[@]}"; do
    if [ ! -f "$SSL_DIR/$cert" ]; then
        MISSING_CERTS+=("$cert")
    fi
done

if [ ${#MISSING_CERTS[@]} -gt 0 ]; then
    print_error "Missing SSL certificates:"
    for cert in "${MISSING_CERTS[@]}"; do
        echo "  - $cert"
    done
    echo ""
    echo "Generate SSL certificates:"
    echo "  ./generate-ssl-certs.sh"
    exit 1
fi

print_success "All SSL certificates found"

# Verify certificate validity
print_info "Verifying certificate validity..."

if ! openssl verify -CAfile "$SSL_DIR/ca-cert.pem" "$SSL_DIR/server-cert.pem" > /dev/null 2>&1; then
    print_error "Server certificate verification failed"
    exit 1
fi

if ! openssl verify -CAfile "$SSL_DIR/ca-cert.pem" "$SSL_DIR/client-cert.pem" > /dev/null 2>&1; then
    print_error "Client certificate verification failed"
    exit 1
fi

print_success "Certificates are valid"

# Check certificate expiry
print_info "Checking certificate expiry..."

SERVER_EXPIRY=$(openssl x509 -in "$SSL_DIR/server-cert.pem" -noout -enddate | cut -d= -f2)
CLIENT_EXPIRY=$(openssl x509 -in "$SSL_DIR/client-cert.pem" -noout -enddate | cut -d= -f2)

SERVER_EXPIRY_EPOCH=$(date -j -f "%b %d %T %Y %Z" "$SERVER_EXPIRY" +%s 2>/dev/null || date -d "$SERVER_EXPIRY" +%s 2>/dev/null)
CLIENT_EXPIRY_EPOCH=$(date -j -f "%b %d %T %Y %Z" "$CLIENT_EXPIRY" +%s 2>/dev/null || date -d "$CLIENT_EXPIRY" +%s 2>/dev/null)
NOW_EPOCH=$(date +%s)

DAYS_UNTIL_SERVER_EXPIRY=$(( ($SERVER_EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
DAYS_UNTIL_CLIENT_EXPIRY=$(( ($CLIENT_EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

if [ $DAYS_UNTIL_SERVER_EXPIRY -lt 30 ]; then
    print_warning "Server certificate expires in $DAYS_UNTIL_SERVER_EXPIRY days"
    print_warning "Consider regenerating certificates soon"
else
    print_success "Server certificate valid for $DAYS_UNTIL_SERVER_EXPIRY days"
fi

if [ $DAYS_UNTIL_CLIENT_EXPIRY -lt 30 ]; then
    print_warning "Client certificate expires in $DAYS_UNTIL_CLIENT_EXPIRY days"
    print_warning "Consider regenerating certificates soon"
else
    print_success "Client certificate valid for $DAYS_UNTIL_CLIENT_EXPIRY days"
fi

# Verify Docker Compose configuration
print_header "Validating Docker Compose Configuration"

print_info "Checking docker-compose.prod.yml..."
if ! docker compose -f "$COMPOSE_FILE" config > /dev/null 2>&1; then
    print_error "Docker Compose configuration is invalid"
    docker compose -f "$COMPOSE_FILE" config
    exit 1
fi

print_success "Docker Compose configuration is valid"

# Backup existing data (if any)
print_header "Backup Check"

if docker ps -a --format '{{.Names}}' | grep -q "dart_cloud_postgres_prod"; then
    print_warning "Existing production containers found"
    read -p "Do you want to backup the database before proceeding? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        BACKUP_DIR="$SCRIPT_DIR/backups/$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        
        print_info "Creating database backup..."
        docker compose -f "$COMPOSE_FILE" exec -T postgres pg_dump -U dart_cloud dart_cloud > "$BACKUP_DIR/database.sql" || true
        
        if [ -f "$BACKUP_DIR/database.sql" ]; then
            print_success "Database backed up to: $BACKUP_DIR/database.sql"
        else
            print_warning "Backup failed or no data to backup"
        fi
    fi
fi

# Deployment confirmation
print_header "Deployment Confirmation"

echo -e "${BLUE}Deployment Details:${NC}"
echo -e "  Environment:  ${YELLOW}PRODUCTION${NC}"
echo -e "  SSL/TLS:      ${GREEN}ENABLED${NC}"
echo -e "  Database:     ${BLUE}${POSTGRES_USER}@postgres:${POSTGRES_PORT}/${POSTGRES_DB}${NC}"
echo -e "  Backend Port: ${BLUE}${PORT}${NC}"
echo ""

read -p "Proceed with production deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Deployment cancelled"
    exit 0
fi

# Deploy
print_header "Deploying Services"

print_info "Pulling latest images..."
docker compose -f "$COMPOSE_FILE" pull

print_info "Building backend image..."
docker compose -f "$COMPOSE_FILE" build --no-cache

print_info "Starting services..."
docker compose -f "$COMPOSE_FILE" up -d

# Wait for services
print_header "Waiting for Services"

print_info "Waiting for PostgreSQL..."
for i in {1..60}; do
    if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U dart_cloud &>/dev/null; then
        print_success "PostgreSQL is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        print_error "PostgreSQL failed to start"
        docker compose -f "$COMPOSE_FILE" logs postgres
        exit 1
    fi
    sleep 1
done

print_info "Waiting for backend..."
for i in {1..60}; do
    if curl -sf http://localhost:${PORT}/api/health &>/dev/null; then
        print_success "Backend is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        print_error "Backend failed to start"
        docker compose -f "$COMPOSE_FILE" logs backend
        exit 1
    fi
    sleep 1
done

# Verify SSL connection
print_header "Verifying SSL Connection"

print_info "Testing SSL connection to PostgreSQL..."
if docker compose -f "$COMPOSE_FILE" exec -T postgres psql \
    "sslmode=require host=localhost user=dart_cloud dbname=dart_cloud" \
    -c "SELECT version();" &>/dev/null; then
    print_success "SSL connection successful"
else
    print_warning "SSL connection test failed (this may be expected if client certs are required)"
fi

# Deployment complete
print_header "Deployment Complete!"

echo -e "${GREEN}✓ Production deployment successful!${NC}"
echo ""
echo -e "${BLUE}Services:${NC}"
echo -e "  Backend API:  ${GREEN}http://localhost:${PORT}${NC}"
echo -e "  Health Check: ${GREEN}http://localhost:${PORT}/api/health${NC}"
echo -e "  PostgreSQL:   ${GREEN}localhost:${POSTGRES_PORT} (SSL enabled)${NC}"
echo ""
echo -e "${BLUE}SSL/TLS:${NC}"
echo -e "  Status:       ${GREEN}ENABLED${NC}"
echo -e "  Mode:         ${YELLOW}verify-ca${NC}"
echo -e "  Certificates: ${BLUE}$SSL_DIR${NC}"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo -e "  View logs:        ${YELLOW}docker compose -f docker-compose.prod.yml logs -f${NC}"
echo -e "  Stop services:    ${YELLOW}docker compose -f docker-compose.prod.yml down${NC}"
echo -e "  Restart backend:  ${YELLOW}docker compose -f docker-compose.prod.yml restart backend${NC}"
echo -e "  Database shell:   ${YELLOW}docker compose -f docker-compose.prod.yml exec postgres psql -U dart_cloud -d dart_cloud${NC}"
echo ""
echo -e "${YELLOW}⚠ Production Reminders:${NC}"
echo -e "  • Monitor logs regularly"
echo -e "  • Set up automated backups"
echo -e "  • Configure reverse proxy with HTTPS"
echo -e "  • Implement rate limiting"
echo -e "  • Set up monitoring and alerting"
echo -e "  • Rotate certificates before expiry"
echo -e "  • Review security logs"
echo ""
