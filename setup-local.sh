#!/bin/bash

# ContainerPub Local Setup Script
# This script sets up a local development environment

set -e

echo "🚀 ContainerPub Local Setup"
echo "============================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check Dart
if ! command -v dart &> /dev/null; then
    echo -e "${RED}❌ Dart SDK not found${NC}"
    echo "Please install Dart SDK: https://dart.dev/get-dart"
    exit 1
fi
echo -e "${GREEN}✓ Dart SDK found: $(dart --version 2>&1 | head -n1)${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker not found (optional, but recommended for PostgreSQL)${NC}"
    DOCKER_AVAILABLE=false
else
    echo -e "${GREEN}✓ Docker found${NC}"
    DOCKER_AVAILABLE=true
fi

# Check PostgreSQL
if ! command -v psql &> /dev/null; then
    if [ "$DOCKER_AVAILABLE" = false ]; then
        echo -e "${RED}❌ PostgreSQL not found and Docker not available${NC}"
        echo "Please install PostgreSQL or Docker"
        exit 1
    fi
    echo -e "${YELLOW}⚠️  PostgreSQL client not found (will use Docker)${NC}"
    PSQL_AVAILABLE=false
else
    echo -e "${GREEN}✓ PostgreSQL client found${NC}"
    PSQL_AVAILABLE=true
fi

echo ""

# Setup PostgreSQL
echo "🐘 Setting up PostgreSQL..."

if [ "$DOCKER_AVAILABLE" = true ]; then
    # Check if container already exists
    if docker ps -a | grep -q containerpub-postgres; then
        echo -e "${YELLOW}⚠️  Container 'containerpub-postgres' already exists${NC}"
        read -p "Remove and recreate? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker stop containerpub-postgres 2>/dev/null || true
            docker rm containerpub-postgres 2>/dev/null || true
        else
            echo "Using existing container"
        fi
    fi
    
    # Start PostgreSQL container if not running
    if ! docker ps | grep -q containerpub-postgres; then
        echo "Starting PostgreSQL container..."
        docker run -d \
            --name containerpub-postgres \
            -e POSTGRES_USER=dart_cloud \
            -e POSTGRES_PASSWORD=dev_password \
            -e POSTGRES_DB=dart_cloud \
            -p 5432:5432 \
            postgres:15
        
        echo "Waiting for PostgreSQL to start..."
        sleep 5
    fi
    
    # Create functions database
    echo "Creating functions_db..."
    docker exec containerpub-postgres psql -U dart_cloud -d postgres -c "CREATE DATABASE functions_db;" 2>/dev/null || echo "Database functions_db already exists"
    
    # Create test table
    echo "Creating test table in functions_db..."
    docker exec containerpub-postgres psql -U dart_cloud -d functions_db << 'EOF'
CREATE TABLE IF NOT EXISTS items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO items (name) 
VALUES ('Test Item 1'), ('Test Item 2'), ('Test Item 3')
ON CONFLICT DO NOTHING;
EOF
    
    echo -e "${GREEN}✓ PostgreSQL setup complete${NC}"
    DB_URL="postgres://dart_cloud:dev_password@localhost:5432/dart_cloud"
    FUNC_DB_URL="postgres://dart_cloud:dev_password@localhost:5432/functions_db"
else
    echo -e "${YELLOW}Please ensure PostgreSQL is running locally${NC}"
    echo "Default connection: postgres://dart_cloud:dev_password@localhost:5432/dart_cloud"
    DB_URL="postgres://dart_cloud:dev_password@localhost:5432/dart_cloud"
    FUNC_DB_URL="postgres://dart_cloud:dev_password@localhost:5432/functions_db"
fi

echo ""

# Setup Backend
echo "⚙️  Setting up backend..."

cd dart_cloud_backend

# Create .env file
if [ -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file already exists${NC}"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing .env"
    else
        rm .env
    fi
fi

if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << EOF
# Server Configuration
PORT=8080
FUNCTIONS_DIR=./functions
DATABASE_URL=$DB_URL
JWT_SECRET=local-dev-secret-change-in-production

# Function Execution Limits
FUNCTION_TIMEOUT_SECONDS=5
FUNCTION_MAX_MEMORY_MB=128
FUNCTION_MAX_CONCURRENT=10

# Database Access for Functions
FUNCTION_DATABASE_URL=$FUNC_DB_URL
FUNCTION_DB_MAX_CONNECTIONS=5
FUNCTION_DB_TIMEOUT_MS=5000
EOF
    echo -e "${GREEN}✓ .env file created${NC}"
fi

# Create functions directory
mkdir -p functions

echo -e "${GREEN}✓ Backend setup complete${NC}"

cd ..

echo ""

# Summary
echo "✅ Setup Complete!"
echo "=================="
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Start the backend:"
echo "   cd dart_cloud_backend"
echo "   dart run bin/server.dart"
echo ""
echo "2. In another terminal, use the CLI:"
echo "   cd dart_cloud_cli"
echo "   dart run bin/main.dart register"
echo "   dart run bin/main.dart login"
echo ""
echo "3. Deploy an example function:"
echo "   dart run bin/main.dart deploy simple-test ../examples/simple-function"
echo ""
echo "4. Invoke the function:"
echo "   dart run bin/main.dart invoke <function-id> --body '{\"name\": \"Test\"}'"
echo ""
echo "📚 Documentation:"
echo "   - LOCAL_DEPLOYMENT.md - Complete deployment guide"
echo "   - QUICK_REFERENCE.md - Quick reference"
echo "   - examples/ - Example functions"
echo ""
echo "🔗 Backend will run at: http://localhost:8080"
echo "🗄️  Database: $DB_URL"
echo "🗄️  Functions DB: $FUNC_DB_URL"
echo ""
echo -e "${GREEN}Happy coding! 🎉${NC}"
