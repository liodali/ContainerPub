---
title: API Reference
description: CLI commands and API endpoints
---

# API Reference

Complete reference for ContainerPub CLI commands and API endpoints.

## CLI Commands

### Authentication

#### Login
```bash
dart_cloud login
```
Authenticate with ContainerPub platform.

**Options:**
- `--email` - Email address
- `--password` - Password (will prompt if not provided)

### Function Management

#### Deploy
```bash
dart_cloud deploy <path> [options]
```
Deploy a new function or update existing one.

**Options:**
- `--name` - Function name (defaults to directory name)
- `--env` - Environment variables (can be used multiple times)
- `--memory` - Memory limit (default: 512MB)
- `--timeout` - Execution timeout (default: 30s)

**Example:**
```bash
dart_cloud deploy ./my_function \
  --name my-function \
  --env DATABASE_URL=postgresql://... \
  --memory 1024
```

#### List
```bash
dart_cloud list [options]
```
List all deployed functions.

**Options:**
- `--format` - Output format (json, table)
- `--limit` - Number of results (default: 10)

#### Delete
```bash
dart_cloud delete <function-id>
```
Delete a function.

**Confirmation:** Will prompt for confirmation.

#### Status
```bash
dart_cloud status <function-id>
```
Check function status and details.

### Monitoring

#### Logs
```bash
dart_cloud logs <function-id> [options]
```
View function execution logs.

**Options:**
- `--follow` - Stream logs in real-time
- `--lines` - Number of lines to show (default: 100)
- `--since` - Show logs since timestamp

**Example:**
```bash
dart_cloud logs my-function-id --follow
dart_cloud logs my-function-id --lines 50
```

#### Metrics
```bash
dart_cloud metrics <function-id> [options]
```
View function metrics and statistics.

**Options:**
- `--period` - Time period (1h, 24h, 7d)
- `--format` - Output format (json, table)

### Configuration

#### Set Environment Variable
```bash
dart_cloud env set <function-id> <key> <value>
```
Set environment variable for function.

#### Get Environment Variable
```bash
dart_cloud env get <function-id> <key>
```
Get environment variable value.

#### List Environment Variables
```bash
dart_cloud env list <function-id>
```
List all environment variables for function.

## REST API Endpoints

### Authentication

#### POST /api/auth/login
Login to platform.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password"
}
```

**Response:**
```json
{
  "token": "eyJhbGc...",
  "user": {
    "id": "user-id",
    "email": "user@example.com"
  }
}
```

### Functions

#### POST /api/functions/deploy
Deploy a function.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Data:**
- `name` - Function name
- `archive` - Function archive (tar.gz)
- `env` - Environment variables (JSON)

**Response:**
```json
{
  "id": "function-id",
  "name": "my-function",
  "status": "deployed",
  "url": "https://api.containerpub.dev/functions/function-id"
}
```

#### GET /api/functions
List functions.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` - Number of results
- `offset` - Pagination offset

**Response:**
```json
{
  "functions": [
    {
      "id": "function-id",
      "name": "my-function",
      "status": "active",
      "created_at": "2025-01-01T00:00:00Z"
    }
  ],
  "total": 1
}
```

#### GET /api/functions/:id
Get function details.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "id": "function-id",
  "name": "my-function",
  "status": "active",
  "memory": 512,
  "timeout": 30,
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

#### DELETE /api/functions/:id
Delete a function.

**Headers:**
```
Authorization: Bearer <token>
```

### Execution

#### POST /api/functions/:id/invoke
Invoke a function.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "body": {
    "key": "value"
  }
}
```

**Response:**
```json
{
  "execution_id": "exec-id",
  "status": "success",
  "result": {
    "output": "result"
  },
  "duration_ms": 150
}
```

#### GET /api/functions/:id/executions
Get execution history.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` - Number of results
- `offset` - Pagination offset

### Logs

#### GET /api/functions/:id/logs
Get function logs.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` - Number of lines
- `since` - Timestamp filter

## Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid request",
  "details": "Missing required field: name"
}
```

### 401 Unauthorized
```json
{
  "error": "Unauthorized",
  "details": "Invalid or expired token"
}
```

### 404 Not Found
```json
{
  "error": "Not found",
  "details": "Function not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "details": "An unexpected error occurred"
}
```

## Rate Limiting

- **Requests per minute**: 60
- **Requests per hour**: 1000
- **Concurrent executions**: 10 per function

## Next Steps

- Read [Development Guide](/docs/development)
- Check [Architecture Overview](/docs/architecture)
- Explore [CLI Usage Examples](/docs/development)
