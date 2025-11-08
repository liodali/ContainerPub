# ContainerPub Security & Function Control

## Overview

ContainerPub implements a comprehensive security system to ensure safe execution of user-submitted functions. This document explains the security measures, analysis process, and restrictions.

## Security Architecture

### 1. Function Analysis (Client-Side Pre-Deployment)

**Analysis is now performed on the client side (CLI) before deployment.**

Before a function is uploaded to the server, the CLI performs rigorous static analysis locally:

#### Analysis Components

**Annotation Validation**
- All functions MUST have the `@function` annotation
- Functions without this annotation are rejected
- Ensures explicit opt-in to cloud execution

**Security Scanning**
- AST (Abstract Syntax Tree) analysis of Dart code
- Pattern matching for dangerous operations
- Import validation for risky packages

**Code Pattern Detection**
- Process execution attempts
- Shell command invocation
- Raw socket operations
- FFI usage
- Reflection (dart:mirrors)
- Platform script access

### 2. Execution Restrictions

#### HTTP-Only Operations

Functions are restricted to HTTP-based operations:

```dart
// ✅ ALLOWED
import 'package:http/http.dart' as http;
await http.get(Uri.parse('https://api.example.com'));
await http.post(Uri.parse('https://api.example.com'), body: data);
```

```dart
// ❌ NOT ALLOWED
Process.run('ls', ['-la']);
Process.start('bash', ['-c', 'command']);
Shell.run('command');
```

#### Input Structure

Functions receive HTTP-like request structure:

```dart
{
  "body": {
    // POST/PUT body parameters
  },
  "query": {
    // Query string parameters
  },
  "headers": {
    // Request headers
  },
  "method": "POST" // HTTP method
}
```

### 3. Runtime Environment

#### Environment Variables

Functions execute with restricted environment:

- `FUNCTION_INPUT`: JSON-encoded HTTP request
- `HTTP_BODY`: JSON-encoded body parameters
- `HTTP_QUERY`: JSON-encoded query parameters
- `HTTP_METHOD`: HTTP method string
- `DART_CLOUD_RESTRICTED`: Flag indicating restricted mode

#### Process Isolation

- Each function runs in a separate process
- 30-second execution timeout
- Process killed on timeout
- No access to host system resources

## Analysis Process

### Step 1: Local Analysis (CLI)

1. Developer runs `dart_cloud deploy <function-path>`
2. CLI locates main.dart or bin/main.dart in the function directory
3. CLI performs static analysis locally

### Step 2: Static Analysis (Client-Side)

```
┌─────────────────────────────────────┐
│   Developer: dart_cloud deploy      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   CLI: AST Analysis (Local)         │
│   - Parse Dart code                 │
│   - Build syntax tree               │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   CLI: Annotation Check             │
│   - Verify @function present        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   CLI: Security Scan                │
│   - Check for risky patterns        │
│   - Validate imports                │
│   - Detect dangerous operations     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   CLI: Signature Validation         │
│   - Check handler function          │
│   - Validate parameters             │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   CLI: Display Analysis Result      │
│   - Show errors, warnings, risks    │
│   - isValid: bool                   │
│   - Exit if invalid                 │
└──────────────┬──────────────────────┘
               │
               ▼ (Only if valid)
┌─────────────────────────────────────┐
│   CLI: Package & Upload             │
│   - Create tar.gz archive           │
│   - Upload to backend               │
└─────────────────────────────────────┘
```

### Step 3: Validation & Upload

**If analysis passes (CLI):**
- CLI displays success message with any warnings
- CLI packages function into tar.gz
- CLI uploads to backend
- Backend stores function and marks as 'active'
- Function ready for invocation

**If analysis fails (CLI):**
- CLI displays detailed errors and risks
- CLI exits with error code
- **No upload occurs** - function never reaches backend
- Developer must fix issues before retry

## Detected Risks

### Critical Risks (Deployment Blocked)

1. **Process Execution**
   ```dart
   Process.run('command', args)
   Process.start('command', args)
   Process.runSync('command', args)
   ```

2. **Shell Access**
   ```dart
   Shell.run('command')
   // Any shell-related operations
   ```

3. **Raw Socket Operations**
   ```dart
   Socket.connect(host, port)
   ServerSocket.bind(address, port)
   ```

4. **FFI (Foreign Function Interface)**
   ```dart
   import 'dart:ffi';
   ```

5. **Reflection**
   ```dart
   import 'dart:mirrors';
   ```

6. **Platform Script Access**
   ```dart
   Platform.executable
   Platform.script
   ```

### Warnings (Deployment Allowed)

1. **File Write Operations**
   - Allowed within function scope
   - Warning issued for awareness

2. **Isolate Spawning**
   - May impact performance
   - Warning issued

3. **dart:io Import**
   - Allowed for HTTP operations
   - Warning to ensure proper usage

## Allowed Operations

### HTTP Requests

```dart
import 'package:http/http.dart' as http;

// GET request
final response = await http.get(Uri.parse(url));

// POST request
final response = await http.post(
  Uri.parse(url),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(data),
);

// With timeout
final response = await http.get(Uri.parse(url))
  .timeout(Duration(seconds: 10));
```

### JSON Processing

```dart
import 'dart:convert';

// Encode
final json = jsonEncode(data);

// Decode
final data = jsonDecode(json);
```

### File Operations (Scoped)

```dart
import 'dart:io';

// Read/write within function directory
final file = File('.temp.json');
await file.writeAsString(data);
final content = await file.readAsString();
```

### Standard Library

```dart
// DateTime operations
DateTime.now()
DateTime.parse(string)

// Collections
List, Map, Set operations

// String manipulation
string.split()
string.trim()
string.toLowerCase()

// Math operations
import 'dart:math';
```

## Database Schema

### functions Table

```sql
CREATE TABLE functions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  status VARCHAR(50) DEFAULT 'active',
  analysis_result JSONB,  -- Stores analysis results
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Analysis Result Structure

**Note**: Analysis results are now displayed in the CLI output, not stored in the database.

**CLI Output Example:**
```
Analyzing function code...

⚠️  Warnings:
  - File write operations detected - ensure they are within function scope

✓ Function analysis passed
```

## Error Responses

### Validation Failed (CLI Exit)

**Note**: Validation errors now appear in CLI output, not as HTTP responses.

**CLI Output Example:**
```
Analyzing function code...

⚠️  Detected Risks:
  - Detected Process execution - command execution is not allowed

✗ Function validation failed:
  - Missing @function annotation. Functions must be annotated with @function
```

### Invalid Input (400)

```json
{
  "error": "Invalid input: must contain \"body\" or \"query\" fields"
}
```

### Execution Timeout (200 with error)

```json
{
  "success": false,
  "error": "Function execution timed out (30s)",
  "result": null
}
```

## Best Practices

### 1. Always Use @function Annotation

```dart
const function = 'function';

@function
void main() async {
  // Your code
}
```

### 2. Validate Input

```dart
@function
Future<Map<String, dynamic>> handler(
  Map<String, dynamic> body,
  Map<String, dynamic> query,
) async {
  // Validate required parameters
  if (!body.containsKey('requiredField')) {
    return {
      'success': false,
      'error': 'Missing required field',
    };
  }
  
  // Your logic
}
```

### 3. Handle Errors Gracefully

```dart
try {
  final result = await riskyOperation();
  return {'success': true, 'result': result};
} catch (e) {
  return {
    'success': false,
    'error': e.toString(),
  };
}
```

### 4. Set Timeouts for External Requests

```dart
final response = await http.get(Uri.parse(url))
  .timeout(
    Duration(seconds: 10),
    onTimeout: () => throw TimeoutException('Request timed out'),
  );
```

### 5. Return Structured JSON

```dart
// Good
return {
  'success': true,
  'data': result,
  'timestamp': DateTime.now().toIso8601String(),
};

// Bad
return result; // Might not be JSON-serializable
```

## Testing Security

### Test Annotation Requirement

```bash
# Deploy without @function annotation
# Expected: Deployment rejected with error
```

### Test Risky Code Detection

```bash
# Deploy function with Process.run
# Expected: Deployment rejected with security violation
```

### Test Input Validation

```bash
# Invoke without body or query
# Expected: Error response
```

## Monitoring

### Function Logs

All analysis results and execution logs are stored:

```sql
SELECT * FROM function_logs 
WHERE function_id = 'xxx' 
ORDER BY timestamp DESC;
```

### Invocation Metrics

```sql
SELECT 
  status,
  COUNT(*) as count,
  AVG(duration_ms) as avg_duration
FROM function_invocations
WHERE function_id = 'xxx'
GROUP BY status;
```

## Future Enhancements

1. **Sandboxing**: Docker/container-based isolation
2. **Resource Limits**: CPU, memory, network quotas
3. **Rate Limiting**: Per-function invocation limits
4. **Dependency Scanning**: Analyze imported packages
5. **Runtime Monitoring**: Real-time security checks
6. **Audit Logging**: Comprehensive security audit trail

## Support

For security concerns or questions:
- Review this documentation
- Check FUNCTION_TEMPLATE.md for examples
- Contact platform administrators

## Compliance

This security system ensures:
- ✅ No arbitrary code execution
- ✅ No system command access
- ✅ Controlled network operations
- ✅ Process isolation
- ✅ Timeout enforcement
- ✅ Comprehensive logging
- ✅ Static analysis validation
