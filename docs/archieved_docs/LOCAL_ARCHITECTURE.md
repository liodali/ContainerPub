# Local Development Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Local Development Setup                   │
└─────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐
│   Terminal 1     │         │   Terminal 2     │
│                  │         │                  │
│  Backend Server  │         │   CLI Client     │
│  (Port 8080)     │         │                  │
└────────┬─────────┘         └────────┬─────────┘
         │                            │
         │ HTTP API                   │ Commands
         │                            │
         ▼                            ▼
┌─────────────────────────────────────────────────┐
│           dart_cloud_backend                    │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  API Layer (Shelf Router)                │  │
│  │  - /api/auth/*                           │  │
│  │  - /api/functions/*                      │  │
│  └──────────────┬───────────────────────────┘  │
│                 │                               │
│  ┌──────────────▼───────────────────────────┐  │
│  │  Handlers                                │  │
│  │  - AuthHandler                           │  │
│  │  - FunctionHandler                       │  │
│  └──────────────┬───────────────────────────┘  │
│                 │                               │
│  ┌──────────────▼───────────────────────────┐  │
│  │  Services                                │  │
│  │  - FunctionAnalyzer (security)           │  │
│  │  - FunctionExecutor (timeout: 5s)        │  │
│  │  - FunctionDatabasePool (5 connections)  │  │
│  └──────────────┬───────────────────────────┘  │
│                 │                               │
│                 ├──────────────┬────────────────┤
│                 ▼              ▼                │
│  ┌──────────────────┐  ┌──────────────────┐   │
│  │  File System     │  │  Process         │   │
│  │  ./functions/    │  │  Isolation       │   │
│  │  - func-uuid-1/  │  │  - Separate proc │   │
│  │  - func-uuid-2/  │  │  - 5s timeout    │   │
│  └──────────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│      PostgreSQL (Docker Container)              │
│      containerpub-postgres                      │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  dart_cloud (Main Database)              │  │
│  │  - users                                 │  │
│  │  - functions (with analysis_result)      │  │
│  │  - function_logs                         │  │
│  │  - function_invocations                  │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  functions_db (Functions Database)       │  │
│  │  - items (test table)                    │  │
│  │  - (user application data)               │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  Port: 5432                                     │
│  User: dart_cloud                               │
│  Password: dev_password                         │
└─────────────────────────────────────────────────┘
```

## Request Flow

### 1. Function Deployment

```
CLI Client
    │
    │ POST /api/functions/deploy
    │ (multipart: name, archive)
    ▼
Backend Handler
    │
    ├─ Authenticate (JWT)
    ├─ Extract archive
    ├─ Run FunctionAnalyzer
    │   ├─ Check @function annotation
    │   ├─ Scan for risky code
    │   ├─ Validate imports
    │   └─ Return analysis result
    │
    ├─ If Valid:
    │   ├─ Store function files
    │   ├─ Save to database (with analysis_result)
    │   └─ Return success (201)
    │
    └─ If Invalid:
        └─ Return error (422) with details
```

### 2. Function Invocation

```
CLI Client
    │
    │ POST /api/functions/{id}/invoke
    │ {"body": {...}, "query": {...}}
    ▼
Backend Handler
    │
    ├─ Authenticate (JWT)
    ├─ Verify function ownership
    │
    ▼
FunctionExecutor
    │
    ├─ Check concurrent limit (max 10)
    ├─ Prepare environment:
    │   ├─ FUNCTION_INPUT (HTTP request)
    │   ├─ DATABASE_URL (if configured)
    │   ├─ DB_TIMEOUT_MS (5000)
    │   └─ FUNCTION_TIMEOUT_MS (5000)
    │
    ├─ Start process (dart run main.dart)
    │   └─ Timeout: 5 seconds
    │
    ├─ Wait for completion
    │   ├─ Success → Return result
    │   └─ Timeout → Kill process (SIGKILL)
    │
    └─ Cleanup & return response
```

### 3. Database Access (from Function)

```
Function Code
    │
    │ Read DATABASE_URL from environment
    ▼
Connection Pool (Backend)
    │
    ├─ Get connection (timeout: 5s)
    ├─ Execute query (timeout: 5s)
    ├─ Return result
    └─ Release connection
    │
    ▼
PostgreSQL (functions_db)
    │
    └─ Return data to function
```

## File Structure

```
ContainerPub/
├── dart_cloud_backend/
│   ├── bin/
│   │   └── server.dart              # Entry point
│   ├── lib/
│   │   ├── config/
│   │   │   └── config.dart          # Configuration
│   │   ├── database/
│   │   │   └── database.dart        # Database setup
│   │   ├── handlers/
│   │   │   ├── auth_handler.dart
│   │   │   └── function_handler.dart
│   │   ├── middleware/
│   │   │   └── auth_middleware.dart
│   │   ├── services/
│   │   │   ├── function_analyzer.dart    # Security analysis
│   │   │   ├── function_executor.dart    # Execution engine
│   │   │   └── function_db_pool.dart     # Connection pool
│   │   └── router.dart
│   ├── functions/                   # Deployed functions
│   │   ├── <uuid-1>/
│   │   │   ├── main.dart
│   │   │   └── pubspec.yaml
│   │   └── <uuid-2>/
│   ├── .env                         # Configuration
│   └── pubspec.yaml
│
├── dart_cloud_cli/
│   ├── bin/
│   │   └── main.dart
│   ├── lib/
│   │   ├── api/
│   │   │   └── api_client.dart
│   │   ├── commands/
│   │   │   ├── deploy_command.dart
│   │   │   ├── invoke_command.dart
│   │   │   └── ...
│   │   └── config/
│   │       └── config.dart
│   └── pubspec.yaml
│
├── examples/
│   ├── simple-function/
│   ├── http-function/
│   └── database-function/
│
├── setup-local.sh                   # Setup script
├── test-local.sh                    # Test script
├── Makefile                         # Make commands
└── LOCAL_DEPLOYMENT.md              # This guide
```

## Environment Variables

### Backend (.env)

```bash
# Server
PORT=8080
FUNCTIONS_DIR=./functions
DATABASE_URL=postgres://dart_cloud:dev_password@localhost:5432/dart_cloud
JWT_SECRET=local-dev-secret

# Execution Limits
FUNCTION_TIMEOUT_SECONDS=5          # Max execution time
FUNCTION_MAX_MEMORY_MB=128          # Memory limit
FUNCTION_MAX_CONCURRENT=10          # Concurrent limit

# Database Access
FUNCTION_DATABASE_URL=postgres://dart_cloud:dev_password@localhost:5432/functions_db
FUNCTION_DB_MAX_CONNECTIONS=5       # Pool size
FUNCTION_DB_TIMEOUT_MS=5000         # Query timeout
```

### Function Runtime (Automatic)

```bash
# Passed to function process
FUNCTION_INPUT={"body":{...},"query":{...}}
HTTP_BODY={"key":"value"}
HTTP_QUERY={"param":"value"}
HTTP_METHOD=POST
DATABASE_URL=postgres://...
DB_TIMEOUT_MS=5000
FUNCTION_TIMEOUT_MS=5000
FUNCTION_MAX_MEMORY_MB=128
DART_CLOUD_RESTRICTED=true
```

## Port Usage

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Backend | 8080 | HTTP | API server |
| PostgreSQL | 5432 | TCP | Database |

## Resource Limits

| Resource | Default | Configurable | Purpose |
|----------|---------|--------------|---------|
| Execution Timeout | 5s | ✅ Yes | Prevent hanging functions |
| Memory | 128 MB | ✅ Yes | Limit memory usage |
| Concurrent Executions | 10 | ✅ Yes | Prevent overload |
| DB Connections | 5 | ✅ Yes | Connection pool size |
| DB Query Timeout | 5s | ✅ Yes | Prevent slow queries |

## Security Layers

```
┌─────────────────────────────────────────┐
│  Layer 1: Pre-Deployment Analysis       │
│  - @function annotation check           │
│  - Security pattern detection           │
│  - Import validation                    │
│  - AST analysis                         │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  Layer 2: Runtime Isolation             │
│  - Separate process                     │
│  - Environment restrictions             │
│  - Timeout enforcement (5s)             │
│  - Memory limits (128 MB)               │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  Layer 3: Database Protection           │
│  - Connection pooling (5 connections)   │
│  - Query timeout (5s)                   │
│  - Automatic cleanup                    │
│  - Separate database                    │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  Layer 4: Concurrent Control            │
│  - Max 10 simultaneous executions       │
│  - Active execution tracking            │
│  - Queue management                     │
└─────────────────────────────────────────┘
```

## Development Workflow

```
1. Setup
   └─ ./setup-local.sh
      ├─ Start PostgreSQL
      ├─ Create databases
      ├─ Create .env
      └─ Setup directories

2. Development
   ├─ Terminal 1: dart run bin/server.dart
   └─ Terminal 2: dart run bin/main.dart <command>

3. Testing
   ├─ ./test-local.sh (automated)
   └─ Manual testing via CLI

4. Monitoring
   ├─ Backend logs (terminal)
   ├─ Database logs (make logs)
   └─ Function logs (CLI)

5. Cleanup
   └─ make clean-all
```

## Quick Commands

```bash
# Setup
make setup              # One-time setup
make start-db           # Start PostgreSQL
make start-backend      # Start backend

# Development
make status             # Check system status
make logs               # View recent logs
make db-shell           # Database shell

# Testing
make test               # Run all tests

# Cleanup
make clean              # Clean test data
make clean-all          # Remove everything
```

## Monitoring Points

1. **Backend Logs** - Terminal output
2. **Function Logs** - Database: `function_logs` table
3. **Execution Metrics** - Database: `function_invocations` table
4. **Pool Statistics** - `FunctionDatabasePool.getStats()`
5. **Active Executions** - `FunctionExecutor.activeExecutions`

## Success Indicators

✅ Backend starts without errors
✅ Database connection successful
✅ Function pool initialized
✅ Functions deploy successfully
✅ Security checks reject dangerous code
✅ Functions execute within timeout
✅ Database queries complete successfully
✅ Logs are recorded properly

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Port 8080 in use | Another service | Change PORT in .env |
| DB connection failed | PostgreSQL not running | `make start-db` |
| Function timeout | Slow code | Optimize or increase timeout |
| Pool exhausted | Too many requests | Increase pool size or concurrent limit |
| Deployment rejected | Missing @function | Add annotation |
| Security violation | Dangerous code | Remove Process.run, etc. |

This local setup provides a complete, production-like environment for testing all ContainerPub features!
