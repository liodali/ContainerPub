# Local Deployment Guide

## Overview

This guide walks you through setting up ContainerPub locally for testing and development.

## Prerequisites

- Dart SDK 3.0.0 or higher
- PostgreSQL 12 or higher
- Git

## Quick Start

### 1. Database Setup

#### Option A: Using Docker (Recommended)

```bash
# Start PostgreSQL with Docker
docker run -d \
  --name containerpub-postgres \
  -e POSTGRES_USER=dart_cloud \
  -e POSTGRES_PASSWORD=dev_password \
  -e POSTGRES_DB=dart_cloud \
  -p 5432:5432 \
  postgres:15

# Verify it's running
docker ps | grep containerpub-postgres
```

#### Option B: Local PostgreSQL

```bash
# Create database and user
psql postgres
CREATE DATABASE dart_cloud;
CREATE USER dart_cloud WITH PASSWORD 'dev_password';
GRANT ALL PRIVILEGES ON DATABASE dart_cloud TO dart_cloud;
\q
```

#### Create Functions Database (Optional - for function database access)

```bash
# Using Docker
docker exec -it containerpub-postgres psql -U dart_cloud -d postgres -c "CREATE DATABASE functions_db;"

# Or local PostgreSQL
psql -U postgres
CREATE DATABASE functions_db;
GRANT ALL PRIVILEGES ON DATABASE functions_db TO dart_cloud;
\q
```

### 2. Backend Setup

```bash
cd dart_cloud_backend

# Create .env file
cat > .env << 'EOF'
# Server Configuration
PORT=8080
FUNCTIONS_DIR=./functions
DATABASE_URL=postgres://dart_cloud:dev_password@localhost:5432/dart_cloud
JWT_SECRET=local-dev-secret-change-in-production

# Function Execution Limits
FUNCTION_TIMEOUT_SECONDS=5
FUNCTION_MAX_MEMORY_MB=128
FUNCTION_MAX_CONCURRENT=10

# Database Access for Functions (Optional)
FUNCTION_DATABASE_URL=postgres://dart_cloud:dev_password@localhost:5432/functions_db
FUNCTION_DB_MAX_CONNECTIONS=5
FUNCTION_DB_TIMEOUT_MS=5000
EOF

# Get dependencies (per user rules, manual step)
# Note: Dependencies need to be installed but not via auto-install
echo "Dependencies listed in pubspec.yaml need to be available"

# Run the server
dart run bin/server.dart
```

Expected output:
```
✓ Database connected
✓ Database tables created/verified
✓ Function database pool initialized with 5 connections
✓ Server running on http://localhost:8080
```

### 3. CLI Setup

```bash
cd ../dart_cloud_cli

# Run CLI (no installation needed for local testing)
dart run bin/main.dart --help
```

## Testing the System

### 1. Register a User

```bash
cd dart_cloud_cli

# Register
dart run bin/main.dart register
# Enter email: test@example.com
# Enter password: testpass123
```

### 2. Login

```bash
dart run bin/main.dart login
# Enter email: test@example.com
# Enter password: testpass123
```

Config saved to: `~/.dart_cloud/config.json`

### 3. Deploy Example Function

#### Simple Function (No Database)

```bash
# Deploy simple function
dart run bin/main.dart deploy simple-test ../examples/simple-function

# Expected output:
# Creating archive...
# Archive created: X.XX KB
# Deploying function...
# Analyzing function code...
# ✓ Function deployed successfully!
# Function ID: <uuid>
# Name: simple-test
```

#### Database Function

```bash
# First, create test table in functions_db
docker exec -it containerpub-postgres psql -U dart_cloud -d functions_db << 'EOF'
CREATE TABLE IF NOT EXISTS items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO items (name) VALUES ('Test Item 1'), ('Test Item 2'), ('Test Item 3');
EOF

# Deploy database function
dart run bin/main.dart deploy db-test ../examples/database-function
```

### 4. Invoke Functions

#### Simple Function

```bash
# Invoke with body
dart run bin/main.dart invoke <function-id> \
  --body '{"name": "Alice"}'

# Expected response:
# {
#   "success": true,
#   "message": "Hello, Alice!",
#   "timestamp": "2024-11-07T...",
#   "method": "POST",
#   "receivedBody": {"name": "Alice"},
#   "receivedQuery": {}
# }
```

#### Database Function

```bash
# List items
dart run bin/main.dart invoke <function-id> \
  --body '{"action": "list"}'

# Get specific item
dart run bin/main.dart invoke <function-id> \
  --body '{"action": "get", "id": "<item-id>"}'

# Create item
dart run bin/main.dart invoke <function-id> \
  --body '{"action": "create", "name": "New Item"}'
```

### 5. View Logs

```bash
dart run bin/main.dart logs <function-id>
```

### 6. List Functions

```bash
dart run bin/main.dart list
```

### 7. Delete Function

```bash
dart run bin/main.dart delete <function-id>
```

## Testing Security Features

### Test 1: Missing @function Annotation

Create a function without `@function`:

```dart
// bad_function/main.dart
import 'dart:convert';
import 'dart:io';

void main() async {
  print(jsonEncode({'message': 'Hello'}));
}
```

```bash
dart run bin/main.dart deploy bad-func ./bad_function

# Expected: Deployment rejected
# Error: Missing @function annotation
```

### Test 2: Dangerous Code Detection

Create a function with Process.run:

```dart
// dangerous_function/main.dart
import 'dart:convert';
import 'dart:io';

const function = 'function';

@function
void main() async {
  // This will be detected and rejected
  final result = await Process.run('ls', ['-la']);
  print(jsonEncode({'output': result.stdout}));
}
```

```bash
dart run bin/main.dart deploy dangerous ./dangerous_function

# Expected: Deployment rejected
# Error: Detected Process execution - command execution is not allowed
```

### Test 3: Timeout Testing

Create a function that takes too long:

```dart
// slow_function/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const function = 'function';

@function
void main() async {
  // Sleep for 10 seconds (exceeds 5s timeout)
  await Future.delayed(Duration(seconds: 10));
  print(jsonEncode({'message': 'Done'}));
}
```

```bash
dart run bin/main.dart deploy slow ./slow_function
dart run bin/main.dart invoke <function-id> --body '{}'

# Expected: Timeout error
# Error: Function execution timed out (5s)
```

### Test 4: Concurrent Execution Limit

```bash
# Run 15 concurrent invocations (exceeds limit of 10)
for i in {1..15}; do
  dart run bin/main.dart invoke <function-id> --body '{}' &
done
wait

# Expected: Some requests will fail with:
# Error: Function execution limit reached. Try again later.
```

## API Testing with curl

### Register User

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpass123"
  }'
```

### Login

```bash
TOKEN=$(curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpass123"
  }' | jq -r '.token')

echo $TOKEN
```

### List Functions

```bash
curl http://localhost:8080/api/functions \
  -H "Authorization: Bearer $TOKEN"
```

### Invoke Function

```bash
curl -X POST http://localhost:8080/api/functions/<function-id>/invoke \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "body": {"name": "Test"},
    "query": {}
  }'
```

## Monitoring

### Check Active Executions

```bash
# In backend code, add endpoint or check logs
# Active executions are tracked in FunctionExecutor.activeExecutions
```

### Check Database Pool

```bash
# Query function_invocations table
docker exec -it containerpub-postgres psql -U dart_cloud -d dart_cloud -c \
  "SELECT 
    status, 
    COUNT(*) as count,
    AVG(duration_ms) as avg_duration
   FROM function_invocations 
   GROUP BY status;"
```

### View Logs

```bash
# Function logs
docker exec -it containerpub-postgres psql -U dart_cloud -d dart_cloud -c \
  "SELECT level, message, timestamp 
   FROM function_logs 
   ORDER BY timestamp DESC 
   LIMIT 20;"
```

## Troubleshooting

### Backend Won't Start

**Problem:** Database connection failed

**Solution:**
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Check connection
psql -U dart_cloud -h localhost -d dart_cloud

# Check .env file has correct DATABASE_URL
cat .env | grep DATABASE_URL
```

### Function Deployment Fails

**Problem:** Analysis errors

**Solution:**
```bash
# Check function has @function annotation
grep -r "@function" your_function/

# Check for dangerous patterns
grep -r "Process.run" your_function/
grep -r "Process.start" your_function/
```

### Function Timeout

**Problem:** Function execution timed out

**Solution:**
```bash
# Increase timeout in .env
FUNCTION_TIMEOUT_SECONDS=10

# Restart backend
# Re-invoke function
```

### Database Connection Issues

**Problem:** Functions can't connect to database

**Solution:**
```bash
# Verify FUNCTION_DATABASE_URL is set
cat .env | grep FUNCTION_DATABASE_URL

# Test connection
psql -U dart_cloud -h localhost -d functions_db

# Check pool initialization in backend logs
```

## Development Workflow

### 1. Make Changes to Backend

```bash
cd dart_cloud_backend

# Edit code
nano lib/handlers/function_handler.dart

# Restart server
# Ctrl+C to stop
dart run bin/server.dart
```

### 2. Test Changes

```bash
cd dart_cloud_cli

# Test deployment
dart run bin/main.dart deploy test-func ../examples/simple-function

# Test invocation
dart run bin/main.dart invoke <function-id> --body '{}'
```

### 3. Check Logs

```bash
# Backend logs (stdout)
# CLI logs (stdout)

# Database logs
docker exec -it containerpub-postgres psql -U dart_cloud -d dart_cloud -c \
  "SELECT * FROM function_logs ORDER BY timestamp DESC LIMIT 10;"
```

## Clean Up

### Stop Backend

```bash
# Ctrl+C in backend terminal
```

### Remove Test Data

```bash
# Clear functions
rm -rf dart_cloud_backend/functions/*

# Reset database
docker exec -it containerpub-postgres psql -U dart_cloud -d dart_cloud << 'EOF'
TRUNCATE function_invocations, function_logs, functions, users CASCADE;
EOF
```

### Stop PostgreSQL

```bash
# Stop container
docker stop containerpub-postgres

# Remove container
docker rm containerpub-postgres
```

## Environment Variables Reference

```bash
# Backend (.env)
PORT=8080                                    # Server port
FUNCTIONS_DIR=./functions                    # Function storage
DATABASE_URL=postgres://...                  # Main database
JWT_SECRET=secret                            # JWT signing key

# Execution limits
FUNCTION_TIMEOUT_SECONDS=5                   # Max execution time
FUNCTION_MAX_MEMORY_MB=128                   # Memory limit
FUNCTION_MAX_CONCURRENT=10                   # Concurrent limit

# Function database access
FUNCTION_DATABASE_URL=postgres://...         # Functions database
FUNCTION_DB_MAX_CONNECTIONS=5                # Pool size
FUNCTION_DB_TIMEOUT_MS=5000                  # Query timeout
```

## Next Steps

1. **Test all examples** - Deploy and test all example functions
2. **Test security** - Try deploying functions with dangerous code
3. **Test limits** - Test timeout and concurrent execution limits
4. **Monitor performance** - Check execution times and resource usage
5. **Integrate Cloudflare** - Test subdomain creation for functions

## Additional Resources

- **SECURITY.md** - Security architecture
- **FUNCTION_TEMPLATE.md** - Function templates
- **DATABASE_ACCESS.md** - Database access guide
- **QUICK_REFERENCE.md** - Quick reference
- **examples/** - Example functions
