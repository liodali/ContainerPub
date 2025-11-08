#!/bin/bash

# SSL Certificate Generation Script for PostgreSQL
# Generates self-signed certificates for secure PostgreSQL connections

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
CERT_DIR="./ssl"
VALIDITY_DAYS=3650  # 10 years
COUNTRY="US"
STATE="State"
CITY="City"
ORGANIZATION="ContainerPub"
ORGANIZATIONAL_UNIT="IT"
COMMON_NAME="postgres"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --days)
            VALIDITY_DAYS="$2"
            shift 2
            ;;
        --country)
            COUNTRY="$2"
            shift 2
            ;;
        --state)
            STATE="$2"
            shift 2
            ;;
        --city)
            CITY="$2"
            shift 2
            ;;
        --org)
            ORGANIZATION="$2"
            shift 2
            ;;
        --cn)
            COMMON_NAME="$2"
            shift 2
            ;;
        --help)
            cat << EOF
Usage: $0 [OPTIONS]

Generate SSL certificates for PostgreSQL secure connections

OPTIONS:
    --days <days>       Certificate validity in days (default: 3650)
    --country <code>    Country code (default: US)
    --state <state>     State/Province (default: State)
    --city <city>       City (default: City)
    --org <name>        Organization name (default: ContainerPub)
    --cn <name>         Common Name (default: postgres)
    --help              Show this help message

EXAMPLES:
    $0
    $0 --days 365 --country US --state CA --city SF
    $0 --org "My Company" --cn "postgres.example.com"

EOF
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_header "PostgreSQL SSL Certificate Generation"

# Check if openssl is installed
if ! command -v openssl &> /dev/null; then
    print_error "openssl is not installed"
    echo "Install openssl:"
    echo "  macOS:   brew install openssl"
    echo "  Ubuntu:  sudo apt-get install openssl"
    echo "  CentOS:  sudo yum install openssl"
    exit 1
fi

print_success "openssl found"

# Create certificate directory
if [ -d "$CERT_DIR" ]; then
    print_warning "Certificate directory already exists: $CERT_DIR"
    read -p "Do you want to overwrite existing certificates? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Aborted. Existing certificates preserved."
        exit 0
    fi
    # Backup existing certificates
    BACKUP_DIR="${CERT_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    mv "$CERT_DIR" "$BACKUP_DIR"
    print_success "Existing certificates backed up to: $BACKUP_DIR"
fi

mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

print_info "Certificate directory: $(pwd)"
print_info "Validity: $VALIDITY_DAYS days"
print_info "Common Name: $COMMON_NAME"

# Generate Certificate Authority (CA)
print_header "Step 1: Generating Certificate Authority (CA)"

print_info "Creating CA private key..."
openssl genrsa -out ca-key.pem 4096

print_info "Creating CA certificate..."
openssl req -new -x509 -days "$VALIDITY_DAYS" -key ca-key.pem -out ca-cert.pem \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$ORGANIZATION-CA"

print_success "CA certificate created"

# Generate Server Certificate
print_header "Step 2: Generating Server Certificate"

print_info "Creating server private key..."
openssl genrsa -out server-key.pem 4096

print_info "Creating server certificate signing request..."
openssl req -new -key server-key.pem -out server-req.pem \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$COMMON_NAME"

print_info "Signing server certificate with CA..."
openssl x509 -req -in server-req.pem -days "$VALIDITY_DAYS" \
    -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial \
    -out server-cert.pem

# Set proper permissions for server key
chmod 600 server-key.pem

print_success "Server certificate created"

# Generate Client Certificate
print_header "Step 3: Generating Client Certificate"

print_info "Creating client private key..."
openssl genrsa -out client-key.pem 4096

print_info "Creating client certificate signing request..."
openssl req -new -key client-key.pem -out client-req.pem \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=dart_cloud"

print_info "Signing client certificate with CA..."
openssl x509 -req -in client-req.pem -days "$VALIDITY_DAYS" \
    -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial \
    -out client-cert.pem

# Set proper permissions for client key
chmod 600 client-key.pem

print_success "Client certificate created"

# Clean up CSR files
print_info "Cleaning up temporary files..."
rm -f server-req.pem client-req.pem ca-cert.srl

# Set proper permissions
print_header "Step 4: Setting Permissions"

chmod 600 ca-key.pem
chmod 644 ca-cert.pem
chmod 644 server-cert.pem
chmod 644 client-cert.pem

print_success "Permissions set"

# Create README
cat > README.md << 'EOF'
# SSL Certificates for PostgreSQL

This directory contains SSL certificates for secure PostgreSQL connections.

## Files

### Certificate Authority (CA)
- `ca-key.pem` - CA private key (keep secure!)
- `ca-cert.pem` - CA certificate (public)

### Server Certificates (PostgreSQL)
- `server-key.pem` - Server private key (keep secure!)
- `server-cert.pem` - Server certificate (public)

### Client Certificates (Backend)
- `client-key.pem` - Client private key (keep secure!)
- `client-cert.pem` - Client certificate (public)

## Usage

### PostgreSQL Configuration

Mount certificates in docker-compose.yml:
```yaml
postgres:
  volumes:
    - ./ssl/server-cert.pem:/var/lib/postgresql/server.crt:ro
    - ./ssl/server-key.pem:/var/lib/postgresql/server.key:ro
    - ./ssl/ca-cert.pem:/var/lib/postgresql/root.crt:ro
  command: >
    postgres
    -c ssl=on
    -c ssl_cert_file=/var/lib/postgresql/server.crt
    -c ssl_key_file=/var/lib/postgresql/server.key
    -c ssl_ca_file=/var/lib/postgresql/root.crt
```

### Backend Configuration

Mount certificates and update DATABASE_URL:
```yaml
backend:
  volumes:
    - ./ssl/client-cert.pem:/app/ssl/client.crt:ro
    - ./ssl/client-key.pem:/app/ssl/client.key:ro
    - ./ssl/ca-cert.pem:/app/ssl/root.crt:ro
  environment:
    DATABASE_URL: "postgres://user:pass@postgres:5432/db?sslmode=verify-ca&sslcert=/app/ssl/client.crt&sslkey=/app/ssl/client.key&sslrootcert=/app/ssl/root.crt"
```

## Security

- **Keep private keys secure** (ca-key.pem, server-key.pem, client-key.pem)
- **Never commit to version control**
- **Use proper file permissions** (600 for keys, 644 for certificates)
- **Rotate certificates before expiry**
- **Use strong passphrases in production**

## Verification

Verify certificates:
```bash
# Verify server certificate
openssl verify -CAfile ca-cert.pem server-cert.pem

# Verify client certificate
openssl verify -CAfile ca-cert.pem client-cert.pem

# Check certificate details
openssl x509 -in server-cert.pem -text -noout
```

## Expiry

Check certificate expiry:
```bash
openssl x509 -in server-cert.pem -noout -enddate
openssl x509 -in client-cert.pem -noout -enddate
```

## Regeneration

To regenerate certificates, run:
```bash
../generate-ssl-certs.sh
```
EOF

print_success "README.md created"

# Verify certificates
print_header "Step 5: Verifying Certificates"

print_info "Verifying server certificate..."
if openssl verify -CAfile ca-cert.pem server-cert.pem > /dev/null 2>&1; then
    print_success "Server certificate is valid"
else
    print_error "Server certificate verification failed"
fi

print_info "Verifying client certificate..."
if openssl verify -CAfile ca-cert.pem client-cert.pem > /dev/null 2>&1; then
    print_success "Client certificate is valid"
else
    print_error "Client certificate verification failed"
fi

# Display certificate information
print_header "Certificate Information"

echo -e "${BLUE}CA Certificate:${NC}"
openssl x509 -in ca-cert.pem -noout -subject -issuer -dates

echo -e "\n${BLUE}Server Certificate:${NC}"
openssl x509 -in server-cert.pem -noout -subject -issuer -dates

echo -e "\n${BLUE}Client Certificate:${NC}"
openssl x509 -in client-cert.pem -noout -subject -issuer -dates

# Summary
print_header "Certificate Generation Complete!"

cat << EOF
${GREEN}✓ All certificates generated successfully!${NC}

${BLUE}Generated files:${NC}
  CA:     ca-key.pem, ca-cert.pem
  Server: server-key.pem, server-cert.pem
  Client: client-key.pem, client-cert.pem

${BLUE}Location:${NC} $(pwd)

${YELLOW}⚠ IMPORTANT SECURITY NOTES:${NC}
  1. Keep private keys secure (*.pem files with 600 permissions)
  2. Never commit certificates to version control
  3. Add ssl/ directory to .gitignore
  4. Use these certificates only for production
  5. Rotate certificates before expiry ($VALIDITY_DAYS days)

${BLUE}Next steps:${NC}
  1. Review docker-compose.prod.yml for SSL configuration
  2. Update .env.production with SSL parameters
  3. Test SSL connection before deploying to production

${BLUE}Verify setup:${NC}
  ${YELLOW}docker-compose -f docker-compose.prod.yml up -d${NC}
  ${YELLOW}docker-compose exec postgres psql "sslmode=require host=postgres user=dart_cloud"${NC}

${BLUE}Documentation:${NC}
  See ssl/README.md for detailed usage instructions

EOF

cd - > /dev/null
