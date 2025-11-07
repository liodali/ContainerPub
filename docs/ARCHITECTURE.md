# ContainerPub Architecture

## Overview

ContainerPub is a Dart-based serverless platform that allows developers to deploy and execute Dart functions in a managed environment.

## System Components

### 1. CLI (dart_cloud_cli)
**Purpose**: Command-line interface for developers to interact with the platform

**Key Features**:
- User authentication (login/logout)
- Function deployment
- Function management (list, delete)
- Function invocation
- Log viewing

**Technology Stack**:
- Dart SDK
- HTTP client for API communication
- Archive library for packaging functions
- Local configuration storage

### 2. Backend (dart_cloud_backend)
**Purpose**: Server platform for hosting and executing functions

**Key Features**:
- RESTful API for function management
- JWT-based authentication
- Function storage and execution
- Logging and monitoring
- Database integration

**Technology Stack**:
- Shelf (HTTP server framework)
- PostgreSQL (metadata storage)
- JWT for authentication
- Process isolation for function execution

## Architecture Diagram

```
┌─────────────────┐
│   Developer     │
└────────┬────────┘
         │
         │ CLI Commands
         ▼
┌─────────────────┐
│  dart_cloud_cli │
│                 │
│  - Login        │
│  - Deploy       │
│  - Invoke       │
│  - Manage       │
└────────┬────────┘
         │
         │ HTTPS/REST API
         ▼
┌─────────────────────────────────────┐
│     dart_cloud_backend              │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   API Layer (Shelf Router)   │  │
│  └──────────┬───────────────────┘  │
│             │                       │
│  ┌──────────▼───────────────────┐  │
│  │   Auth Middleware (JWT)      │  │
│  └──────────┬───────────────────┘  │
│             │                       │
│  ┌──────────▼───────────────────┐  │
│  │   Handlers                   │  │
│  │   - AuthHandler              │  │
│  │   - FunctionHandler          │  │
│  └──────────┬───────────────────┘  │
│             │                       │
│  ┌──────────▼───────────────────┐  │
│  │   Services                   │  │
│  │   - FunctionExecutor         │  │
│  └──────────┬───────────────────┘  │
│             │                       │
│  ┌──────────▼───────────────────┐  │
│  │   Database Layer             │  │
│  │   - PostgreSQL               │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   File System                │  │
│  │   - Function Storage         │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Data Flow

### Function Deployment Flow

1. **Developer** creates a Dart function with `pubspec.yaml`
2. **CLI** packages the function into a tar.gz archive
3. **CLI** sends multipart request to `/api/functions/deploy`
4. **Backend** authenticates the request via JWT
5. **Backend** generates unique function ID
6. **Backend** extracts archive to function storage directory
7. **Backend** stores metadata in PostgreSQL
8. **Backend** returns function details to CLI

### Function Invocation Flow

1. **Developer** invokes function via CLI or direct API call
2. **Backend** authenticates the request
3. **Backend** verifies function ownership
4. **Backend** creates isolated process for function execution
5. **FunctionExecutor** runs `dart run` with input as environment variable
6. **Function** processes input and outputs result to stdout
7. **Backend** captures output and returns to caller
8. **Backend** logs invocation metrics to database

## Security Model

### Authentication
- JWT-based token authentication
- Tokens issued on login with user ID and email
- Tokens required for all function operations

### Authorization
- Functions are user-scoped
- Users can only access their own functions
- Database queries include user_id filtering

### Function Isolation
- Each function runs in a separate process
- Configurable execution timeout (default: 5 seconds)
- Memory limits enforced (default: 128 MB)
- Concurrent execution limits (default: 10)
- Environment variable-based input (no direct stdin)
- Process killed on timeout (SIGKILL)
- Database connection pooling with timeout protection

## Database Schema

### users
Stores user account information
- Passwords hashed with bcrypt
- Email used as unique identifier

### functions
Stores function metadata
- Links to user via foreign key
- Tracks deployment status
- Timestamps for auditing

### function_logs
Stores execution logs
- Links to function via foreign key
- Supports different log levels
- Timestamped for chronological ordering

### function_invocations
Stores invocation metrics
- Tracks success/failure status
- Records execution duration
- Stores error messages

## Scalability Considerations

### Current Limitations
- Single-server deployment
- Synchronous function execution
- File system-based function storage
- No horizontal scaling

### Future Enhancements
1. **Containerization**: Use Docker for better isolation
2. **Queue System**: Async function execution with message queue
3. **Load Balancing**: Multiple backend instances
4. **Object Storage**: S3/MinIO for function artifacts
5. **Caching**: Redis for session and result caching
6. **Monitoring**: Prometheus/Grafana integration
7. **Auto-scaling**: Kubernetes-based orchestration

## Development Workflow

### Adding New Features

1. **CLI Changes**:
   - Add command in `lib/commands/`
   - Update router in `bin/main.dart`
   - Add API client method in `lib/api/api_client.dart`

2. **Backend Changes**:
   - Add handler in `lib/handlers/`
   - Add route in `lib/router.dart`
   - Update database schema if needed
   - Add service logic in `lib/services/`

### Testing Strategy

1. **Unit Tests**: Test individual components
2. **Integration Tests**: Test API endpoints
3. **E2E Tests**: Test CLI → Backend flow
4. **Load Tests**: Verify performance under load

## Deployment Architecture

### Development
```
localhost:8080 (Backend)
↑
CLI (local)
```

### Production
```
┌─────────────────┐
│  Load Balancer  │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼──┐  ┌──▼───┐
│ App1 │  │ App2 │
└───┬──┘  └──┬───┘
    │        │
    └────┬───┘
         │
┌────────▼────────┐
│   PostgreSQL    │
│   (Primary)     │
└─────────────────┘
```

## Configuration Management

### CLI Configuration
- Stored in `~/.dart_cloud/config.json`
- Contains auth token and server URL
- Automatically created on first login

### Backend Configuration
- Environment variables via `.env` file
- Core settings: PORT, DATABASE_URL, JWT_SECRET, FUNCTIONS_DIR
- Function execution limits: FUNCTION_TIMEOUT_SECONDS, FUNCTION_MAX_MEMORY_MB, FUNCTION_MAX_CONCURRENT
- Database access: FUNCTION_DATABASE_URL, FUNCTION_DB_MAX_CONNECTIONS, FUNCTION_DB_TIMEOUT_MS
- Defaults provided for development

## Error Handling

### CLI Errors
- Network errors: Retry with exponential backoff
- Auth errors: Prompt re-login
- Validation errors: Display helpful messages

### Backend Errors
- Database errors: Return 500 with generic message
- Auth errors: Return 401/403 with specific reason
- Validation errors: Return 400 with details
- Function errors: Capture and return in response

## Monitoring and Observability

### Logging
- Backend: Request/response logging via Shelf middleware
- Functions: Stdout/stderr captured and stored
- Database: Invocation metrics tracked

### Metrics (Future)
- Request rate
- Function execution time
- Error rate
- Active functions
- User activity

## API Versioning

Current: v1 (implicit in `/api/` prefix)

Future versioning strategy:
- URL-based: `/api/v2/functions`
- Header-based: `Accept: application/vnd.dartcloud.v2+json`
