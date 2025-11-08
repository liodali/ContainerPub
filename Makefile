.PHONY: help setup start-backend start-db stop-db test clean podman-up podman-down podman-build tofu-init tofu-apply tofu-destroy deploy install-cli

# Default target
help:
	@echo "ContainerPub - Local Development Commands"
	@echo "=========================================="
	@echo ""
	@echo "Quick Start:"
	@echo "  make secrets      - Generate secure secrets (.env file)"
	@echo "  make deploy       - Deploy full infrastructure (recommended)"
	@echo "  make install-cli  - Install CLI globally"
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
	@echo "Deployment Scripts:"
	@echo "  make deploy       - Deploy with deploy.sh script"
	@echo "  make deploy-clean - Clean deploy (removes existing data)"
	@echo "  make deploy-tofu  - Deploy with OpenTofu"
	@echo ""
	@echo "CLI Management:"
	@echo "  make install-cli  - Install CLI globally"
	@echo "  make uninstall-cli - Uninstall CLI"
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
	@if [ -f .env ]; then \
		export $$(cat .env | grep -v '^#' | xargs); \
	fi; \
	docker start containerpub-postgres 2>/dev/null || \
		docker run -d \
			--name containerpub-postgres \
			-e POSTGRES_USER=$${POSTGRES_USER:-dart_cloud} \
			-e POSTGRES_PASSWORD=$${POSTGRES_PASSWORD:-dev_password} \
			-e POSTGRES_DB=$${POSTGRES_DB:-dart_cloud} \
			-p $${POSTGRES_PORT:-5432}:5432 \
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

# New deployment script commands
deploy:
	@echo "🚀 Deploying ContainerPub infrastructure..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh

deploy-clean:
	@echo "🧹 Clean deployment (removes existing data)..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --clean

deploy-backend:
	@echo "🔨 Deploying backend only..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --backend-only

deploy-postgres:
	@echo "🐘 Deploying PostgreSQL only..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --postgres-only

deploy-tofu:
	@echo "🔧 Deploying with OpenTofu..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --tofu

# CLI installation commands
install-cli:
	@echo "📦 Installing Dart Cloud CLI..."
	@chmod +x scripts/install-cli.sh
	@./scripts/install-cli.sh

install-cli-dev:
	@echo "🔧 Installing CLI in development mode..."
	@chmod +x scripts/install-cli.sh
	@./scripts/install-cli.sh --dev

uninstall-cli:
	@echo "🗑️  Uninstalling Dart Cloud CLI..."
	@chmod +x scripts/install-cli.sh
	@./scripts/install-cli.sh --uninstall

# Generate secure secrets
secrets:
	@echo "🔐 Generating secure secrets..."
	@chmod +x scripts/generate-secrets.sh
	@./scripts/generate-secrets.sh

# Full setup workflow
full-setup: secrets deploy install-cli
	@echo ""
	@echo "✅ Full setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. dart_cloud login"
	@echo "  2. dart_cloud deploy ./examples/hello-world"
	@echo "  3. dart_cloud list"
	@echo ""
