# ContainerPub Quick Reference

## Function Execution Protection

### Configuration (.env)

```bash
# Execution Limits
FUNCTION_TIMEOUT_SECONDS=5          # Max execution time (default: 5s)
FUNCTION_MAX_MEMORY_MB=128          # Memory limit (default: 128MB)
FUNCTION_MAX_CONCURRENT=10          # Max concurrent executions (default: 10)

# Database Access
FUNCTION_DATABASE_URL=postgres://user:pass@host:5432/db
FUNCTION_DB_MAX_CONNECTIONS=5       # Connection pool size (default: 5)
FUNCTION_DB_TIMEOUT_MS=5000         # Query timeout (default: 5000ms)
```

## Function Template

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const function = 'function';

@function
void main() async {
  try {
    final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
    final body = input['body'] as Map<String, dynamic>? ?? {};
    final query = input['query'] as Map<String, dynamic>? ?? {};
    
    final result = await handler(body, query);
    print(jsonEncode(result));
  } catch (e) {
    print(jsonEncode({'error': e.toString()}));
    exit(1);
  }
}

@function
Future<Map<String, dynamic>> handler(
  Map<String, dynamic> body,
  Map<String, dynamic> query,
) async {
  // Your logic here
  return {'success': true, 'message': 'Hello!'};
}
```

## Database Access Template

```dart
import 'dart:async';
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
  final databaseUrl = Platform.environment['DATABASE_URL'];
  if (databaseUrl == null) {
    return {'success': false, 'error': 'Database not configured'};
  }
  
  final timeoutMs = int.parse(Platform.environment['DB_TIMEOUT_MS'] ?? '5000');
  Connection? connection;
  
  try {
    final uri = Uri.parse(databaseUrl);
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
    
    final result = await connection
        .execute('SELECT * FROM items LIMIT 10')
        .timeout(Duration(milliseconds: timeoutMs));
    
    return {'success': true, 'count': result.length};
  } on TimeoutException {
    return {'success': false, 'error': 'Query timed out'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  } finally {
    await connection?.close();
  }
}
```

## Security Checklist

### ✅ Required
- [ ] `@function` annotation on all handler functions
- [ ] HTTP request structure (body/query)
- [ ] Timeout handling for all async operations
- [ ] Connection cleanup (finally block)
- [ ] Parameterized queries (no string interpolation)
- [ ] Error handling with try-catch
- [ ] JSON output to stdout

### ❌ Prohibited
- [ ] Process.run / Process.start
- [ ] Shell commands
- [ ] Raw socket operations
- [ ] dart:ffi
- [ ] dart:mirrors
- [ ] Unbounded queries (always use LIMIT)
- [ ] String interpolation in SQL

## Environment Variables Available

```dart
// HTTP Request
Platform.environment['FUNCTION_INPUT']  // Full HTTP request JSON
Platform.environment['HTTP_BODY']       // Body as JSON
Platform.environment['HTTP_QUERY']      // Query params as JSON
Platform.environment['HTTP_METHOD']     // HTTP method

// Limits
Platform.environment['FUNCTION_TIMEOUT_MS']    // Execution timeout
Platform.environment['FUNCTION_MAX_MEMORY_MB'] // Memory limit

// Database (if configured)
Platform.environment['DATABASE_URL']           // Database connection URL
Platform.environment['DB_MAX_CONNECTIONS']     // Pool size
Platform.environment['DB_TIMEOUT_MS']          // Query timeout

// Security
Platform.environment['DART_CLOUD_RESTRICTED']  // 'true' if restricted
```

## Deployment

```bash
# Deploy function
dart_cloud deploy my-function ./path/to/function

# Invoke with body
dart_cloud invoke <function-id> --body '{"key": "value"}'

# Invoke with query
dart_cloud invoke <function-id> --query '{"param": "value"}'

# View logs
dart_cloud logs <function-id>

# Delete function
dart_cloud delete <function-id>
```

## Common Patterns

### Timeout Wrapper

```dart
Future<T> withTimeout<T>(
  Future<T> Function() operation,
  int timeoutMs,
) async {
  try {
    return await operation().timeout(Duration(milliseconds: timeoutMs));
  } on TimeoutException {
    throw Exception('Operation timed out after ${timeoutMs}ms');
  }
}

// Usage
final result = await withTimeout(
  () => connection.execute(query),
  5000,
);
```

### Connection Helper

```dart
Future<Map<String, dynamic>> withConnection(
  Future<Map<String, dynamic>> Function(Connection) operation,
) async {
  final databaseUrl = Platform.environment['DATABASE_URL'];
  if (databaseUrl == null) {
    return {'success': false, 'error': 'Database not configured'};
  }
  
  Connection? connection;
  try {
    connection = await _connect(databaseUrl);
    return await operation(connection);
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  } finally {
    await connection?.close();
  }
}
```

### Input Validation

```dart
Map<String, dynamic> validateInput(
  Map<String, dynamic> body,
  List<String> requiredFields,
) {
  for (final field in requiredFields) {
    if (!body.containsKey(field)) {
      throw Exception('Missing required field: $field');
    }
  }
  return body;
}

// Usage
try {
  validateInput(body, ['name', 'email']);
} catch (e) {
  return {'success': false, 'error': e.toString()};
}
```

## Performance Tips

1. **Use LIMIT** - Always limit query results
2. **Add Indexes** - Index frequently queried columns
3. **Cache Results** - Cache static or slow queries
4. **Batch Operations** - Group multiple queries
5. **Select Specific Columns** - Avoid SELECT *
6. **Use Connection Pool** - Reuse connections (automatic)
7. **Optimize Queries** - Use EXPLAIN to analyze

## Monitoring Queries

```sql
-- Slow queries
SELECT 
  function_id,
  AVG(duration_ms) as avg_ms,
  MAX(duration_ms) as max_ms
FROM function_invocations
WHERE duration_ms > 1000
GROUP BY function_id;

-- Error rate
SELECT 
  function_id,
  COUNT(*) FILTER (WHERE status = 'error') * 100.0 / COUNT(*) as error_rate
FROM function_invocations
GROUP BY function_id;

-- Timeout rate
SELECT 
  COUNT(*) FILTER (WHERE error LIKE '%timed out%') as timeouts,
  COUNT(*) as total
FROM function_invocations
WHERE timestamp > NOW() - INTERVAL '1 hour';
```

## Troubleshooting

### Function Times Out

**Problem:** `Function execution timed out (5s)`

**Solutions:**
1. Optimize database queries (add indexes)
2. Reduce result set size (use LIMIT)
3. Cache frequently accessed data
4. Increase timeout (if justified)

### Connection Pool Exhausted

**Problem:** `Function execution limit reached`

**Solutions:**
1. Increase `FUNCTION_MAX_CONCURRENT`
2. Increase `FUNCTION_DB_MAX_CONNECTIONS`
3. Optimize function to execute faster
4. Implement retry logic in client

### Query Timeout

**Problem:** `Query timed out`

**Solutions:**
1. Add database indexes
2. Optimize query (use EXPLAIN)
3. Reduce result set (LIMIT)
4. Split into multiple smaller queries

## Resources

- **SECURITY.md** - Complete security documentation
- **FUNCTION_TEMPLATE.md** - Function templates and examples
- **DATABASE_ACCESS.md** - Database access guide
- **MIGRATION_GUIDE.md** - Migration instructions
- **examples/** - Working examples

## Support

For issues:
1. Check function logs: `dart_cloud logs <function-id>`
2. Review error messages in response
3. Verify configuration in `.env`
4. Test locally with environment variables
5. Check database connection and permissions
