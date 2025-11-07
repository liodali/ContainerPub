# Database Access Protection for Functions

## Overview

ContainerPub provides secure, time-limited database access for functions with built-in protection mechanisms to prevent abuse and ensure fast execution times.

## Security Model

### 1. Execution Time Limits

**Default: 5 seconds** (configurable)

Functions are terminated if they exceed the execution timeout:

```bash
# .env configuration
FUNCTION_TIMEOUT_SECONDS=5  # Total function execution time
```

This ensures:
- ✅ Fast response times
- ✅ No hanging connections
- ✅ Resource efficiency
- ✅ Predictable performance

### 2. Database Connection Limits

**Connection Pool Protection:**

```bash
# .env configuration
FUNCTION_DB_MAX_CONNECTIONS=5      # Max connections in pool
FUNCTION_DB_TIMEOUT_MS=5000        # Connection timeout (5 seconds)
```

**Features:**
- Connection pooling prevents connection exhaustion
- Automatic timeout on slow queries
- Connection reuse for efficiency
- Isolated from main application database

### 3. Concurrent Execution Limits

**Default: 10 concurrent executions**

```bash
# .env configuration
FUNCTION_MAX_CONCURRENT=10  # Max simultaneous function executions
```

Prevents:
- ❌ Resource exhaustion
- ❌ Database overload
- ❌ Memory issues
- ❌ CPU saturation

### 4. Memory Limits

**Default: 128 MB per function**

```bash
# .env configuration
FUNCTION_MAX_MEMORY_MB=128
```

## Configuration

### Environment Variables

Create or update `.env` file in backend:

```bash
# Function Execution Limits
FUNCTION_TIMEOUT_SECONDS=5          # Execution timeout
FUNCTION_MAX_MEMORY_MB=128          # Memory limit per function
FUNCTION_MAX_CONCURRENT=10          # Max concurrent executions

# Database Access for Functions
FUNCTION_DATABASE_URL=postgres://user:pass@localhost:5432/functions_db
FUNCTION_DB_MAX_CONNECTIONS=5       # Connection pool size
FUNCTION_DB_TIMEOUT_MS=5000         # Query timeout (5 seconds)
```

### Separate Database Recommendation

**Best Practice:** Use a separate database for functions:

```
┌─────────────────────────────────┐
│   Main Application Database     │
│   (User data, functions, logs)  │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│   Functions Database             │
│   (Read-only or limited access) │
│   (Isolated from main data)     │
└─────────────────────────────────┘
```

**Why?**
- Isolates function queries from critical data
- Prevents accidental data corruption
- Allows different access controls
- Easier to monitor and limit

## Function Implementation

### Basic Database Access

```dart
import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';

const function = 'function';

@function
void main() async {
  try {
    final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
    final body = input['body'] as Map<String, dynamic>? ?? {};
    
    final result = await handler(body);
    print(jsonEncode(result));
  } catch (e) {
    print(jsonEncode({'error': e.toString()}));
    exit(1);
  }
}

@function
Future<Map<String, dynamic>> handler(Map<String, dynamic> body) async {
  // Get database URL from environment (provided by platform)
  final databaseUrl = Platform.environment['DATABASE_URL'];
  
  if (databaseUrl == null) {
    return {'success': false, 'error': 'Database not configured'};
  }
  
  // Get timeout from environment (enforced by platform)
  final timeoutMs = int.parse(
    Platform.environment['DB_TIMEOUT_MS'] ?? '5000',
  );
  
  Connection? connection;
  
  try {
    final uri = Uri.parse(databaseUrl);
    
    // Connect with timeout
    connection = await Connection.open(
      Endpoint(
        host: uri.host,
        port: uri.port,
        database: uri.pathSegments[0],
        username: uri.userInfo.split(':').first,
        password: uri.userInfo.split(':')[1],
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
        connectTimeout: Duration(milliseconds: timeoutMs),
      ),
    ).timeout(Duration(milliseconds: timeoutMs));
    
    // Execute query with timeout
    final result = await connection
        .execute('SELECT * FROM items LIMIT 10')
        .timeout(Duration(milliseconds: timeoutMs));
    
    return {
      'success': true,
      'count': result.length,
      'data': result.map((row) => row.toColumnMap()).toList(),
    };
  } on TimeoutException {
    return {'success': false, 'error': 'Query timed out'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  } finally {
    await connection?.close();
  }
}
```

### Best Practices

#### 1. Always Use Timeouts

```dart
// ✅ GOOD - With timeout
final result = await connection
    .execute(query)
    .timeout(Duration(milliseconds: timeoutMs));

// ❌ BAD - No timeout
final result = await connection.execute(query);
```

#### 2. Always Close Connections

```dart
Connection? connection;
try {
  connection = await Connection.open(...);
  // Use connection
} finally {
  await connection?.close();  // Always close
}
```

#### 3. Use Parameterized Queries

```dart
// ✅ GOOD - Parameterized (prevents SQL injection)
await connection.execute(
  'SELECT * FROM items WHERE id = \$1',
  parameters: [id],
);

// ❌ BAD - String interpolation (SQL injection risk)
await connection.execute(
  'SELECT * FROM items WHERE id = $id',
);
```

#### 4. Limit Result Sets

```dart
// ✅ GOOD - Limited results
await connection.execute('SELECT * FROM items LIMIT 100');

// ❌ BAD - Unbounded results
await connection.execute('SELECT * FROM items');
```

#### 5. Handle Timeouts Gracefully

```dart
try {
  final result = await query.timeout(duration);
  return {'success': true, 'data': result};
} on TimeoutException {
  return {
    'success': false,
    'error': 'Query took too long',
    'hint': 'Try a more specific query',
  };
}
```

## Protection Mechanisms

### 1. Automatic Timeout Enforcement

```dart
// Platform automatically enforces timeout
environment: {
  'FUNCTION_TIMEOUT_MS': '5000',  // 5 seconds max
  'DB_TIMEOUT_MS': '5000',        // 5 seconds for DB
}
```

If function exceeds timeout:
- Process is killed (SIGKILL)
- Connection is closed
- Error returned to caller

### 2. Connection Pool Management

```dart
// Backend manages connection pool
class FunctionDatabasePool {
  - Max connections: 5 (configurable)
  - Automatic connection reuse
  - Timeout on connection acquisition
  - Automatic cleanup
}
```

### 3. Concurrent Execution Control

```dart
// Backend tracks active executions
if (_activeExecutions >= Config.functionMaxConcurrentExecutions) {
  return {
    'success': false,
    'error': 'Function execution limit reached. Try again later.',
  };
}
```

### 4. Memory Limits

```dart
// Environment variable passed to function
environment: {
  'FUNCTION_MAX_MEMORY_MB': '128',
}
```

## Monitoring

### Execution Metrics

```sql
-- Average execution time
SELECT 
  AVG(duration_ms) as avg_duration,
  MAX(duration_ms) as max_duration,
  COUNT(*) as total_executions
FROM function_invocations
WHERE function_id = 'xxx'
  AND timestamp > NOW() - INTERVAL '1 hour';

-- Timeout rate
SELECT 
  COUNT(*) FILTER (WHERE error LIKE '%timed out%') as timeouts,
  COUNT(*) as total,
  (COUNT(*) FILTER (WHERE error LIKE '%timed out%') * 100.0 / COUNT(*)) as timeout_rate
FROM function_invocations
WHERE function_id = 'xxx';
```

### Database Connection Stats

```dart
// Get pool statistics
final stats = FunctionDatabasePool.instance.getStats();
// {
//   'initialized': true,
//   'totalConnections': 5,
//   'availableConnections': 3,
//   'inUseConnections': 2,
//   'maxConnections': 5
// }
```

## Performance Optimization

### 1. Use Indexes

```sql
-- Add indexes for common queries
CREATE INDEX idx_items_user_id ON items(user_id);
CREATE INDEX idx_items_created_at ON items(created_at);
```

### 2. Optimize Queries

```dart
// ✅ GOOD - Specific columns
SELECT id, name FROM items WHERE user_id = $1 LIMIT 10

// ❌ BAD - SELECT *
SELECT * FROM items WHERE user_id = $1
```

### 3. Cache Results

```dart
// Cache frequently accessed data
final cache = <String, dynamic>{};

if (cache.containsKey(key)) {
  return cache[key];
}

final result = await query();
cache[key] = result;
return result;
```

### 4. Use Connection Pooling

```dart
// Platform handles this automatically
// No need to create new connections per request
```

## Security Considerations

### 1. Read-Only Access

**Recommended:** Grant read-only access to functions database:

```sql
-- Create read-only user
CREATE USER function_user WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE functions_db TO function_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO function_user;
```

### 2. Row-Level Security

```sql
-- Enable RLS
ALTER TABLE items ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own data
CREATE POLICY user_items ON items
  FOR SELECT
  USING (user_id = current_setting('app.user_id')::uuid);
```

### 3. Connection Limits

```sql
-- Limit connections per user
ALTER USER function_user CONNECTION LIMIT 10;
```

### 4. Query Timeout

```sql
-- Set statement timeout
ALTER USER function_user SET statement_timeout = '5s';
```

## Error Handling

### Common Errors

#### 1. Connection Timeout

```json
{
  "success": false,
  "error": "Database operation timed out"
}
```

**Solution:** Optimize query or increase timeout (if appropriate)

#### 2. Connection Pool Exhausted

```json
{
  "success": false,
  "error": "Function execution limit reached. Try again later."
}
```

**Solution:** Wait and retry, or increase pool size

#### 3. Query Timeout

```json
{
  "success": false,
  "error": "Query timed out"
}
```

**Solution:** Add indexes, limit result set, optimize query

## Example: Complete Function

See `examples/database-function/main.dart` for a complete example with:
- ✅ Timeout protection
- ✅ Connection management
- ✅ Error handling
- ✅ Multiple operations (list, get, create)
- ✅ Parameterized queries
- ✅ Proper cleanup

## Testing

### Local Testing

```dart
// Set environment variables
Platform.environment['DATABASE_URL'] = 'postgres://localhost/test_db';
Platform.environment['DB_TIMEOUT_MS'] = '5000';
Platform.environment['FUNCTION_TIMEOUT_MS'] = '5000';

// Run function
dart run main.dart
```

### Load Testing

```bash
# Test concurrent executions
for i in {1..20}; do
  curl -X POST http://localhost:8080/api/functions/xxx/invoke \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"body": {"action": "list"}}' &
done
wait
```

## Summary

**Protection Layers:**

1. ✅ **5-second execution timeout** - Fast, predictable performance
2. ✅ **Connection pooling** - Prevents connection exhaustion
3. ✅ **Query timeouts** - No hanging queries
4. ✅ **Concurrent limits** - Prevents overload
5. ✅ **Memory limits** - Resource control
6. ✅ **Isolated database** - Separate from main app
7. ✅ **Automatic cleanup** - Connections always closed

**Result:** Secure, fast, reliable database access for functions with built-in protection against abuse and resource exhaustion.
