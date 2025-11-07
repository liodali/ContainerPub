.PHONY: help setup start-backend start-db stop-db test clean podman-up podman-down podman-build tofu-init tofu-apply tofu-destroy

# Default target
help:
	@echo "ContainerPub - Local Development Commands"
	@echo "=========================================="
	@echo ""
	@echo "Setup:"
	@echo "  make setup        - Setup local environment (PostgreSQL + config)"
	@echo "  make start-db     - Start PostgreSQL container"
	@echo "  make stop-db      - Stop PostgreSQL container"
	@echo ""
	@echo "Development:"
	@echo "  make start-backend - Start backend server"
	@echo "  make test         - Run integration tests"
	@echo ""
	@echo "Podman (Container Deployment):"
	@echo "  make podman-build - Build backend container image"
	@echo "  make podman-up    - Start all containers with podman-compose"
	@echo "  make podman-down  - Stop all containers"
	@echo "  make podman-logs  - View container logs"
	@echo ""
	@echo "OpenTofu (Infrastructure as Code):"
	@echo "  make tofu-init    - Initialize OpenTofu"
	@echo "  make tofu-plan    - Preview infrastructure changes"
	@echo "  make tofu-apply   - Apply infrastructure"
	@echo "  make tofu-destroy - Destroy infrastructure"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean        - Clean up test data and containers"
	@echo "  make clean-all    - Clean everything including functions"
	@echo ""

# Setup local environment
setup:
	@echo "🚀 Setting up local environment..."
	@chmod +x setup-local.sh
	@./setup-local.sh

# Start PostgreSQL
start-db:
	@echo "🐘 Starting PostgreSQL..."
	@docker start containerpub-postgres 2>/dev/null || \
		docker run -d \
			--name containerpub-postgres \
			-e POSTGRES_USER=dart_cloud \
			-e POSTGRES_PASSWORD=dev_password \
			-e POSTGRES_DB=dart_cloud \
			-p 5432:5432 \
			postgres:15
	@echo "✓ PostgreSQL started"

# Stop PostgreSQL
stop-db:
	@echo "🛑 Stopping PostgreSQL..."
	@docker stop containerpub-postgres 2>/dev/null || echo "Container not running"
	@echo "✓ PostgreSQL stopped"

# Start backend server
start-backend:
	@echo "⚙️  Starting backend server..."
	@cd dart_cloud_backend && dart run bin/server.dart

# Run tests
test:
	@echo "🧪 Running integration tests..."
	@chmod +x test-local.sh
	@./test-local.sh

# Clean test data
clean:
	@echo "🧹 Cleaning test data..."
	@docker exec containerpub-postgres psql -U dart_cloud -d dart_cloud -c \
		"TRUNCATE function_invocations, function_logs, functions, users CASCADE;" 2>/dev/null || true
	@echo "✓ Test data cleaned"

# Clean everything
clean-all: stop-db
	@echo "🧹 Cleaning everything..."
	@docker rm containerpub-postgres 2>/dev/null || true
	@rm -rf dart_cloud_backend/functions/*
	@rm -f dart_cloud_backend/.env
	@echo "✓ Everything cleaned"

# Quick start (setup + start backend)
quick-start: setup
	@echo ""
	@echo "✅ Setup complete! Starting backend..."
	@echo ""
	@$(MAKE) start-backend

# Development workflow
dev: start-db
	@echo "Starting development environment..."
	@$(MAKE) start-backend

# Check status
status:
	@echo "📊 System Status"
	@echo "================"
	@echo ""
	@echo -n "PostgreSQL: "
	@docker ps | grep -q containerpub-postgres && echo "✓ Running" || echo "✗ Not running"
	@echo -n "Backend: "
	@curl -s http://localhost:8080/api/health > /dev/null 2>&1 && echo "✓ Running" || echo "✗ Not running"
	@echo ""
	@echo "Database Stats:"
	@docker exec containerpub-postgres psql -U dart_cloud -d dart_cloud -c \
		"SELECT 'Users: ' || COUNT(*) FROM users UNION ALL \
		 SELECT 'Functions: ' || COUNT(*) FROM functions UNION ALL \
		 SELECT 'Invocations: ' || COUNT(*) FROM function_invocations;" 2>/dev/null || echo "Database not accessible"

# Deploy example functions
deploy-examples:
	@echo "📦 Deploying example functions..."
	@cd dart_cloud_cli && \
		dart run bin/main.dart deploy simple-example ../examples/simple-function && \
		dart run bin/main.dart deploy http-example ../examples/http-function && \
		dart run bin/main.dart deploy db-example ../examples/database-function
	@echo "✓ Examples deployed"

# Show logs
logs:
	@echo "📋 Recent Logs"
	@echo "=============="
	@docker exec containerpub-postgres psql -U dart_cloud -d dart_cloud -c \
		"SELECT level, message, timestamp FROM function_logs ORDER BY timestamp DESC LIMIT 20;"

# Database shell
db-shell:
	@docker exec -it containerpub-postgres psql -U dart_cloud -d dart_cloud

# Functions database shell
db-shell-functions:
	@docker exec -it containerpub-postgres psql -U dart_cloud -d functions_db

# Podman commands
podman-build:
	@echo "🔨 Building backend container image..."
	@cd infrastructure && podman build -t containerpub-backend:latest -f Dockerfile.backend ..
	@echo "✓ Image built successfully"

podman-up:
	@echo "🚀 Starting containers with podman-compose..."
	@cd infrastructure && podman-compose -f podman-compose.yml up -d
	@echo "✓ Containers started"
	@echo ""
	@echo "Backend: http://localhost:8080"
	@echo "PostgreSQL: localhost:5432"

podman-down:
	@echo "🛑 Stopping containers..."
	@cd infrastructure && podman-compose -f podman-compose.yml down
	@echo "✓ Containers stopped"

podman-logs:
	@cd infrastructure && podman-compose -f podman-compose.yml logs -f

podman-restart:
	@echo "🔄 Restarting containers..."
	@cd infrastructure && podman-compose -f podman-compose.yml restart
	@echo "✓ Containers restarted"

podman-status:
	@echo "📊 Podman Container Status"
	@echo "=========================="
	@podman ps -a --filter "label=app=containerpub"

# OpenTofu commands
tofu-init:
	@echo "🔧 Initializing OpenTofu..."
	@cd infrastructure && tofu init
	@echo "✓ OpenTofu initialized"

tofu-plan:
	@echo "📋 Planning infrastructure changes..."
	@cd infrastructure && tofu plan -var-file=variables.tfvars

tofu-apply:
	@echo "🚀 Applying infrastructure..."
	@cd infrastructure && tofu apply -var-file=variables.tfvars

tofu-destroy:
	@echo "💥 Destroying infrastructure..."
	@cd infrastructure && tofu destroy -var-file=variables.tfvars

tofu-output:
	@cd infrastructure && tofu output

# Combined workflow
podman-full: podman-build podman-up
	@echo "✅ Full Podman deployment complete!"
