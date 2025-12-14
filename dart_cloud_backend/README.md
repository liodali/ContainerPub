# Dart Cloud Backend

Backend server for hosting and executing Dart functions.

## Quick Start with Docker Compose

### 1. Setup Environment

```bash
# Copy environment template
cp .env.example .env

# Generate secure passwords
openssl rand -base64 32  # For POSTGRES_PASSWORD
openssl rand -base64 64  # For JWT_SECRET

# Edit .env with your secure values
nano .env
```

### 2. Deploy with Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 3. Access Services

- **Backend API**: http://localhost:8080
- **Health Check**: http://localhost:8080/api/health
- **PostgreSQL**: localhost:5432

### 4. Stop Services

```bash
# Stop containers
docker-compose down

# Stop and remove volumes (⚠️ DATA LOSS)
docker-compose down -v
```

## Docker Compose Configuration

The `docker-compose.yml` includes:

- **PostgreSQL 15** - Database with automatic initialization
- **Backend Service** - Dart backend server
- **Health Checks** - Automatic service monitoring
- **Persistent Volumes** - Data persistence
- **Network Isolation** - Secure internal network

### Environment Variables

All sensitive data is loaded from `.env` file:

| Variable                   | Required | Default          | Description             |
| -------------------------- | -------- | ---------------- | ----------------------- |
| `POSTGRES_USER`            | No       | `dart_cloud`     | Database username       |
| `POSTGRES_PASSWORD`        | **Yes**  | -                | Database password       |
| `POSTGRES_DB`              | No       | `dart_cloud`     | Main database name      |
| `POSTGRES_PORT`            | No       | `5432`           | PostgreSQL port         |
| `FUNCTION_DB`              | No       | `functions_db`   | Functions database name |
| `PORT`                     | No       | `8080`           | Backend API port        |
| `JWT_SECRET`               | **Yes**  | -                | JWT signing secret      |
| `FUNCTIONS_DIR`            | No       | `/app/functions` | Functions storage path  |
| `FUNCTION_TIMEOUT_SECONDS` | No       | `5`              | Function timeout        |
| `FUNCTION_MAX_MEMORY_MB`   | No       | `128`            | Memory limit            |
| `FUNCTION_MAX_CONCURRENT`  | No       | `10`             | Concurrent executions   |

### Database Initialization

The PostgreSQL container automatically runs `init-db.sql` on first start:

- Creates `dart_cloud` database
- Creates `functions_db` database
- Creates tables: `users`, `functions`, `function_logs`, `function_data`
- Creates indexes for performance
- Sets up triggers for `updated_at` columns

## Development

### Local Development (without Docker)

```bash
# Install dependencies
dart pub get

# Setup local PostgreSQL
# (see main project README for setup scripts)

# Create .env file
cp .env.example .env

# Run server
dart run bin/server.dart
```

### Development with Docker Compose

```bash
# Build and start with live logs
docker-compose up --build

# Rebuild after code changes
docker-compose up --build -d

# View backend logs only
docker-compose logs -f backend
```

## Management Commands

### Database Management

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U dart_cloud -d dart_cloud

# Backup database
docker-compose exec postgres pg_dump -U dart_cloud dart_cloud > backup.sql

# Restore database
cat backup.sql | docker-compose exec -T postgres psql -U dart_cloud -d dart_cloud

# View database logs
docker-compose logs postgres
```

### Backend Management

```bash
# Restart backend only
docker-compose restart backend

# View backend logs
docker-compose logs -f backend

# Execute command in backend container
docker-compose exec backend sh

# Check backend health
curl http://localhost:8080/api/health
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect dart_cloud_backend_postgres_data

# Backup volume
docker run --rm -v dart_cloud_backend_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz -C /data .

# Restore volume
docker run --rm -v dart_cloud_backend_postgres_data:/data -v $(pwd):/backup alpine tar xzf /backup/postgres_backup.tar.gz -C /data
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs

# Check specific service
docker-compose logs backend
docker-compose logs postgres

# Verify environment variables
docker-compose config
```

### Database connection failed

```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres

# Test connection
docker-compose exec postgres pg_isready -U dart_cloud

# Verify credentials in .env
cat .env | grep POSTGRES
```

### Port already in use

```bash
# Check what's using the port
lsof -i :8080
lsof -i :5432

# Change port in .env
PORT=8081
POSTGRES_PORT=5433
```

### Reset everything

```bash
# Stop and remove everything
docker-compose down -v

# Remove images
docker-compose down --rmi all -v

# Start fresh
docker-compose up -d
```

## Security

### Production Deployment

**⚠️ IMPORTANT for production:**

1. **Generate strong secrets**:

   ```bash
   openssl rand -base64 32  # POSTGRES_PASSWORD
   openssl rand -base64 64  # JWT_SECRET
   ```

2. **Secure .env file**:

   ```bash
   chmod 600 .env
   ```

3. **Never commit .env**:

   - Already in `.gitignore`
   - Verify: `git check-ignore .env`

4. **Use secrets management**:

   - Docker Secrets
   - HashiCorp Vault
   - AWS Secrets Manager
   - Azure Key Vault

5. **Enable SSL/TLS**:

   - Use reverse proxy (nginx, traefik)
   - Configure SSL certificates
   - Force HTTPS

6. **Network security**:
   - Don't expose PostgreSQL port publicly
   - Use firewall rules
   - Implement rate limiting

### Docker Secrets (Production)

```yaml
# docker-compose.prod.yml
version: "3.8"

services:
  backend:
    secrets:
      - postgres_password
      - jwt_secret
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
      JWT_SECRET_FILE: /run/secrets/jwt_secret

secrets:
  postgres_password:
    external: true
  jwt_secret:
    external: true
```

## Monitoring

### Health Checks

```bash
# Backend health
curl http://localhost:8080/api/health

# PostgreSQL health
docker-compose exec postgres pg_isready -U dart_cloud

# All services status
docker-compose ps
```

### Logs

```bash
# All logs
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100

# Since timestamp
docker-compose logs --since 2024-01-01T00:00:00

# Specific service
docker-compose logs -f backend
```

### Resource Usage

```bash
# Container stats
docker stats

# Disk usage
docker system df

# Volume sizes
docker system df -v
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy Backend

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Create .env
        run: |
          echo "POSTGRES_PASSWORD=${{ secrets.POSTGRES_PASSWORD }}" >> .env
          echo "JWT_SECRET=${{ secrets.JWT_SECRET }}" >> .env

      - name: Deploy
        run: |
          cd dart_cloud_backend
          docker-compose up -d
```

## Architecture

```
┌─────────────────────────────────────────┐
│         Docker Compose Network          │
│                                         │
│  ┌──────────────┐    ┌──────────────┐  │
│  │   Backend    │    │  PostgreSQL  │  │
│  │   :8080      │───▶│   :5432      │  │
│  │              │    │              │  │
│  │ - API Server │    │ - dart_cloud │  │
│  │ - Functions  │    │ - functions_ │  │
│  │   Runtime    │    │   db         │  │
│  └──────────────┘    └──────────────┘  │
│         │                    │          │
│         │                    │          │
│    ┌────▼────┐         ┌────▼────┐     │
│    │Functions│         │Postgres │     │
│    │ Volume  │         │  Data   │     │
│    └─────────┘         └─────────┘     │
└─────────────────────────────────────────┘
           │
           ▼
    External Access
    http://localhost:8080
```

## Additional Resources

- [Main Project README](../README.md)
- [Deployment Documentation](../docs/deployment/)
- [Development Guide](../docs/development/)

## Features

- 🚀 Deploy Dart functions via REST API
- 🔐 JWT-based authentication
- 📊 Function execution monitoring
- 📝 Logging and metrics
- 🗄️ PostgreSQL database for metadata
- ⚡ Isolated function execution

## Setup

### Prerequisites

- Dart SDK 3.0+
- PostgreSQL database

### Installation

1. Copy environment configuration:

```bash
cp .env.example .env
```

2. Update `.env` with your configuration:

   - `PORT`: Server port (default: 8080)
   - `FUNCTIONS_DIR`: Directory to store deployed functions
   - `DATABASE_URL`: PostgreSQL connection string
   - `JWT_SECRET`: Secret key for JWT tokens

3. Install dependencies:

```bash
dart pub get
```

4. Run the server:

```bash
dart run bin/server.dart
```

## API Endpoints

### Authentication

#### Register

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword"
}
```

#### Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword"
}
```

### Functions (Requires Authentication)

All function endpoints require the `Authorization: Bearer <token>` header.

#### Deploy Function

```http
POST /api/functions/deploy
Authorization: Bearer <token>
Content-Type: multipart/form-data

name: my-function
archive: <function.tar.gz>
```

#### List Functions

```http
GET /api/functions
Authorization: Bearer <token>
```

#### Get Function Details

```http
GET /api/functions/{id}
Authorization: Bearer <token>
```

#### Get Function Logs

```http
GET /api/functions/{id}/logs
Authorization: Bearer <token>
```

#### Invoke Function

```http
POST /api/functions/{id}/invoke
Authorization: Bearer <token>
Content-Type: application/json

{
  "body": {},
  "query": {},
  "headers": {},
  "method": "POST",
  "path": "/"
}
```

**Response (Success):**

```json
{
  "success": true,
  "result": {
    "body": { ... }
  }
}
```

**Response (Error):**

```json
{
  "success": false,
  "error": "Error message"
}
```

#### Delete Function

```http
DELETE /api/functions/{id}
Authorization: Bearer <token>
```

## Function Structure

Deployed functions should have the following structure:

```
my-function/
├── pubspec.yaml
├── main.dart (or bin/main.dart)
└── ... other files
```

## Function Invocation System

### Overview

The function invocation system handles execution of deployed Dart functions in isolated Docker containers with comprehensive logging and result tracking.

### Execution Flow

1. **Request Reception** → `ExecutionHandler.invoke()`
2. **Function Lookup** → Retrieve active deployment from database
3. **Container Execution** → `DockerService.runContainer()`
4. **Result Collection** → Read `result.json` from mounted volume
5. **Log Aggregation** → Capture container output and execution metadata
6. **Database Storage** → Store invocation record with encoded sensitive data
7. **Response Return** → Return clean response (result + success status)

### Result Handling

#### result.json File System

Functions write their output to `/result.json` (mounted volume):

```

Functions Directory Structure:
FUNCTIONS_DIR/
├── {functionUUID}/
│ ├── v1/
│ │ ├── result.json ← Latest invocation result
│ │ └── ... (deployment files)
│ ├── v2/
│ │ ├── result.json
│ │ └── ...

```

**Key Points:**

- Result file location: `{FUNCTIONS_DIR}/{functionUUID}/v{version}/result.json`
- File is created empty before container execution
- Function writes JSON result during execution
- File is read after container completes
- File is deleted after processing (not persisted)

#### Result Format

Functions must write a JSON object with a `body` field:

```json
{
  "body": {
    "message": "Hello, World!",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

The `body` field is extracted and returned to the client.

### Invocation Logging System

#### InvocationLogs Model

Structured logging captures execution details in three categories:

```dart
class InvocationLogs {
  // Container output
  final String? stdout;           // Function output
  final String? stderr;           // Function errors
  final int? exitCode;            // Container exit code (-1 = timeout)
  final String? containerTimestamp;

  // Execution errors
  final List<ExecutionError> executionErrors;  // Pipeline errors

  // Metadata
  final ExecutionMetadata? metadata;  // Timing, memory, limits
}
```

#### Log Storage

Logs are stored in database as structured JSON:

```json
{
  "container": {
    "stdout": "function output",
    "stderr": "error messages",
    "exit_code": 0,
    "timestamp": "2024-01-15T10:30:00Z"
  },
  "errors": [
    {
      "phase": "execution",
      "message": "Error description",
      "code": "0"
    }
  ],
  "metadata": {
    "function_uuid": "...",
    "start_time": "2024-01-15T10:30:00Z",
    "end_time": "2024-01-15T10:30:01Z",
    "timeout_ms": 5000,
    "memory_limit_mb": 128
  }
}
```

#### Log Retrieval

```http
GET /api/functions/{id}/logs
Authorization: Bearer <token>
```

Returns invocation logs with execution details and error information.

### Invocation Record Storage

#### FunctionInvocationEntity

Each invocation is stored with:

```dart
class FunctionInvocationEntity {
  final String? functionId;
  final String status;            // 'success' or 'error'
  final int durationMs;           // Execution time
  final String? error;            // Base64 encoded error (if failed)
  final Map<String, dynamic> logs;  // Structured logs
  final Map<String, dynamic> requestInfo;  // Request metadata
  final String? result;           // Base64 encoded result (if succeeded)
  final bool success;
}
```

**Security Features:**

- Sensitive data (body, result, error) encoded as Base64
- Request body excluded from storage (security)
- Prepared for future encryption with developer-specific keys
- Request info stores only metadata (headers, query, method, path)

#### Request Info Stored

```json
{
  "headers": { ... },
  "query": { ... },
  "method": "POST",
  "path": "/",
  "content_type": "application/json",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Container Execution Details

#### Volume Mounts

Three files are mounted into the container:

1. **request.json** (read-only)

   - Contains function input (body, query, headers, method)
   - Path: `/request.json`

2. **.env.config** (read-only)

   - Environment variables (timeout, memory limits)
   - Path: `/.env.config`

3. **result.json** (read-write)
   - Function writes execution result here
   - Path: `/result.json`
   - Persisted on host at: `{FUNCTIONS_DIR}/{functionUUID}/v{version}/result.json`

#### Container Logs

stdout/stderr are captured as logs only (not mixed with results):

```json
{
  "stderr": "error output",
  "exit_code": 0,
  "timestamp": "2024-01-15T10:30:00Z",
  "logs": "stdout output"
}
```

#### Timeout Handling

- Timeout: `FUNCTION_TIMEOUT_SECONDS` (default: 5 seconds)
- Exit code: `-1` indicates timeout
- Error message: "Function execution timed out (Xms)"

### Response Format

#### Success Response

```json
{
  "success": true,
  "result": {
    "message": "Hello, World!",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

#### Error Response

```json
{
  "success": false,
  "error": "Function execution failed: ..."
}
```

**Note:** Error responses exclude logs and sensitive data for security.

### Database Schema

#### function_invocations Table

```sql
CREATE TABLE function_invocations (
  id UUID PRIMARY KEY,
  function_id UUID NOT NULL REFERENCES functions(id),
  status VARCHAR(20),           -- 'success' or 'error'
  duration_ms INTEGER,          -- Execution time in milliseconds
  error TEXT,                   -- Base64 encoded error message
  logs JSONB,                   -- Structured invocation logs
  request_info JSONB,           -- Request metadata
  result TEXT,                  -- Base64 encoded result
  success BOOLEAN,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

## Function Structure

Deployed functions should have the following structure:

```

my-function/
├── pubspec.yaml
├── main.dart (or bin/main.dart)
└── ... other files

````

The function's `main.dart` should:
- Read input from `/request.json` (mounted volume)
- Write output to `/result.json` (mounted volume)
- Exit with code 0 on success

Example function:

```dart
import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    // Read input from mounted request.json
    final requestFile = File('/request.json');
    final requestJson = await requestFile.readAsString();
    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    // Extract body, query, headers
    final body = request['body'] as Map<String, dynamic>? ?? {};
    final query = request['query'] as Map<String, dynamic>? ?? {};
    final headers = request['headers'] as Map<String, dynamic>? ?? {};

    // Process
    final result = {
      'message': 'Hello, ${body['name'] ?? 'World'}!',
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Write result to mounted result.json
    final resultFile = File('/result.json');
    await resultFile.writeAsString(jsonEncode({
      'body': result,
    }));

    exit(0);
  } catch (e) {
    // Write error to result.json
    final resultFile = File('/result.json');
    await resultFile.writeAsString(jsonEncode({
      'body': {
        'error': e.toString(),
      },
    }));
    exit(1);
  }
}

## Development

### Running Tests

```bash
dart test
````

### Linting

```bash
dart analyze
```

## Production Deployment

1. Set strong `JWT_SECRET` in production
2. Use SSL/TLS for database connections
3. Configure proper CORS settings
4. Set up monitoring and logging
5. Use a reverse proxy (nginx/Caddy) for HTTPS
6. Implement rate limiting
7. Set up database backups
