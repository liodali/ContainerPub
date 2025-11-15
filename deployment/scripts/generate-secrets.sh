#!/bin/bash

# Script to generate secure secrets for ContainerPub
# This creates a .env file with randomly generated passwords

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ContainerPub Secrets Generator${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠ .env file already exists!${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Existing .env file preserved."
        exit 0
    fi
    # Backup existing file
    cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓ Backed up existing .env file${NC}"
fi

# Check if openssl is available
if ! command -v openssl &> /dev/null; then
    echo -e "${YELLOW}⚠ openssl not found. Using fallback method.${NC}"
    POSTGRES_PASSWORD=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 32 | head -n 1)
    JWT_SECRET=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 64 | head -n 1)
else
    # Generate secure random passwords
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
    JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
fi

# Create .env file
cat > "$ENV_FILE" << EOF
# ContainerPub Environment Variables
# Generated on: $(date)
# DO NOT commit this file to version control!

# PostgreSQL Configuration
POSTGRES_USER=dart_cloud
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=dart_cloud
POSTGRES_PORT=5432

# Backend Configuration
BACKEND_PORT=8080
JWT_SECRET=$JWT_SECRET

# Function Runtime Configuration
FUNCTION_TIMEOUT_SECONDS=5
FUNCTION_MAX_MEMORY_MB=128
FUNCTION_MAX_CONCURRENT=10
FUNCTION_DB_MAX_CONNECTIONS=5
FUNCTION_DB_TIMEOUT_MS=5000

# Podman Socket Path (OS-specific)
# macOS: unix:///var/run/podman/podman.sock
# Linux: unix:///run/podman/podman.sock
PODMAN_SOCKET_PATH=unix:///var/run/podman/podman.sock
EOF

# Secure the file
chmod 600 "$ENV_FILE"

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Secrets generated successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}Configuration saved to:${NC} $ENV_FILE"
echo -e "${BLUE}File permissions:${NC} $(ls -la "$ENV_FILE" | awk '{print $1}')"
echo ""
echo -e "${BLUE}Generated credentials:${NC}"
echo -e "  PostgreSQL User:     ${GREEN}dart_cloud${NC}"
echo -e "  PostgreSQL Password: ${GREEN}[32 characters]${NC}"
echo -e "  JWT Secret:          ${GREEN}[64 characters]${NC}"
echo ""
echo -e "${YELLOW}⚠ IMPORTANT:${NC}"
echo -e "  • Never commit .env to version control"
echo -e "  • Keep this file secure (chmod 600)"
echo -e "  • Rotate secrets regularly"
echo -e "  • Use different secrets for each environment"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Review the generated .env file"
echo -e "  2. Deploy infrastructure: ${GREEN}./scripts/deploy.sh${NC}"
echo -e "  3. Install CLI: ${GREEN}./scripts/install-cli.sh${NC}"
echo ""
