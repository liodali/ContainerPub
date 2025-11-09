# Function Execution Protection

## Overview

ContainerPub implements comprehensive execution protection for functions, enabling secure database access with strict time limits (5ms-5s configurable) and resource controls.

## Implemented Features

### 1. Configurable Execution Limits

**File:** `lib/config/config.dart`

```dart
// Execution timeouts
static late int functionTimeoutSeconds;        // Default: 5s
static late int functionMaxMemoryMb;           // Default: 128MB
static late int functionMaxConcurrentExecutions; // Default: 10

// Database access control
static late String? functionDatabaseUrl;
static late int functionDatabaseMaxConnections;  // Default: 5
static late int functionDatabaseConnectionTimeoutMs; // Default: 5000ms
```

**Environment Variables:**
```bash
FUNCTION_TIMEOUT_SECONDS=5          # Execution timeout
FUNCTION_MAX_MEMORY_MB=128          # Memory limit
FUNCTION_MAX_CONCURRENT=10          # Max concurrent executions
FUNCTION_DATABASE_URL=postgres://...
FUNCTION_DB_MAX_CONNECTIONS=5
FUNCTION_DB_TIMEOUT_MS=5000
```

### 2. Enhanced Function Executor

**File:** `lib/services/function_executor.dart`

**Features:**
- ✅ Concurrent execution tracking and limiting
- ✅ Configurable timeout enforcement (5s default)
- ✅ Database connection info passed via environment
- ✅ Resource limit variables exposed to functions
- ✅ Automatic cleanup on timeout (SIGKILL)
- ✅ Active execution monitoring

### 3. Database Connection Pool

**File:** `lib/services/function_db_pool.dart`

**Features:**
- ✅ Connection pooling (max 5 connections default)
- ✅ Automatic connection reuse
- ✅ Timeout on connection acquisition
- ✅ Query execution with timeout
- ✅ Automatic cleanup
- ✅ Pool statistics monitoring

## Protection Mechanisms

### Time-Based Protection

| Operation | Default Timeout | Configurable | Enforcement |
|---|---|---|---|
| Function Execution | 5 seconds | ✅ Yes | Process kill (SIGKILL) |
| Database Connection | 5 seconds | ✅ Yes | Connection timeout |
| Database Query | 5 seconds | ✅ Yes | Query timeout |

### Resource-Based Protection

| Resource | Default Limit | Configurable | Enforcement |
|---|---|---|---|
| Memory | 128 MB | ✅ Yes | Environment variable |
| Concurrent Executions | 10 | ✅ Yes | Active tracking |
| DB Connections | 5 | ✅ Yes | Connection pool |

### Access-Based Protection

| Access Type | Status | Notes |
|---|---|---|
| HTTP Requests | ✅ Allowed | With timeout |
| Database Queries | ✅ Allowed | With connection pool & timeout |
| File System (scoped) | ✅ Allowed | Within function directory |
| Process Execution | ❌ Blocked | Static analysis rejection |
| Shell Commands | ❌ Blocked | Static analysis rejection |
| Raw Sockets | ❌ Blocked | Static analysis rejection |
| FFI | ❌ Blocked | Static analysis rejection |
| Reflection | ❌ Blocked | Static analysis rejection |
