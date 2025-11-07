# Function Template Guide

## Overview

ContainerPub functions must follow specific syntax and security requirements to ensure safe execution.

## Requirements

1. **@function Annotation**: All functions must be annotated with `@function`
2. **HTTP Request Structure**: Functions receive HTTP-like requests with `body` and `query` parameters
3. **Security Restrictions**: No command execution, shell access, or dangerous operations
4. **HTTP-Only Operations**: Only HTTP requests are allowed (no system commands)

## Function Structure

### Basic Template

```dart
import 'dart:convert';
import 'dart:io';

/// Annotation to mark this as a cloud function
const function = 'function';

/// Main handler function
@function
void main() async {
  try {
    // Read HTTP request from environment
    final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
    
    // Extract body and query parameters
    final body = input['body'] as Map<String, dynamic>? ?? {};
    final query = input['query'] as Map<String, dynamic>? ?? {};
    final method = input['method'] as String? ?? 'POST';
    
    // Your function logic here
    final result = await handler(body, query, method);
    
    // Return JSON response
    print(jsonEncode(result));
  } catch (e) {
    print(jsonEncode({
      'error': 'Function execution failed',
      'message': e.toString(),
    }));
    exit(1);
  }
}

/// Handler function that processes the request
@function
Future<Map<String, dynamic>> handler(
  Map<String, dynamic> body,
  Map<String, dynamic> query,
  String method,
) async {
  // Your business logic here
  return {
    'success': true,
    'message': 'Hello from cloud function!',
    'receivedBody': body,
    'receivedQuery': query,
    'method': method,
  };
}
```

## Example Functions

### 1. Simple Echo Function

```dart
import 'dart:convert';
import 'dart:io';

const function = 'function';

@function
void main() async {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  final body = input['body'] as Map<String, dynamic>? ?? {};
  
  print(jsonEncode({
    'echo': body,
    'timestamp': DateTime.now().toIso8601String(),
  }));
}
```

### 2. HTTP Request Function (Allowed)

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const function = 'function';

@function
void main() async {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  final body = input['body'] as Map<String, dynamic>? ?? {};
  final url = body['url'] as String?;
  
  if (url == null) {
    print(jsonEncode({'error': 'URL is required'}));
    exit(1);
  }
  
  try {
    // HTTP requests are allowed
    final response = await http.get(Uri.parse(url));
    
    print(jsonEncode({
      'statusCode': response.statusCode,
      'body': response.body,
    }));
  } catch (e) {
    print(jsonEncode({'error': e.toString()}));
    exit(1);
  }
}
```

### 3. Data Processing Function

```dart
import 'dart:convert';
import 'dart:io';

const function = 'function';

@function
void main() async {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  final body = input['body'] as Map<String, dynamic>? ?? {};
  
  final numbers = (body['numbers'] as List?)?.cast<num>() ?? [];
  
  if (numbers.isEmpty) {
    print(jsonEncode({'error': 'Numbers array is required'}));
    exit(1);
  }
  
  final sum = numbers.reduce((a, b) => a + b);
  final average = sum / numbers.length;
  final max = numbers.reduce((a, b) => a > b ? a : b);
  final min = numbers.reduce((a, b) => a < b ? a : b);
  
  print(jsonEncode({
    'sum': sum,
    'average': average,
    'max': max,
    'min': min,
    'count': numbers.length,
  }));
}
```

## Security Restrictions

### ❌ NOT ALLOWED

```dart
// Command execution
Process.run('ls', ['-la']);
Process.start('bash', ['-c', 'echo hello']);

// Shell access
Shell.run('command');

// Raw socket operations
Socket.connect('example.com', 80);
ServerSocket.bind('0.0.0.0', 8080);

// FFI (Foreign Function Interface)
import 'dart:ffi';

// Reflection
import 'dart:mirrors';

// Platform script access
Platform.executable;
Platform.script;
```

### ✅ ALLOWED

```dart
// HTTP requests
import 'package:http/http.dart' as http;
await http.get(Uri.parse('https://api.example.com'));

// JSON processing
jsonEncode(data);
jsonDecode(string);

// File operations (within function scope)
final file = File('.temp.json');
await file.writeAsString(data);

// Standard library operations
DateTime.now();
List, Map, Set operations
String manipulation
Math operations
```

## Input/Output Format

### Input Structure

```json
{
  "body": {
    "key": "value",
    "data": [1, 2, 3]
  },
  "query": {
    "param1": "value1",
    "param2": "value2"
  },
  "headers": {
    "Content-Type": "application/json"
  },
  "method": "POST"
}
```

### Output Format

Functions should output JSON to stdout:

```json
{
  "success": true,
  "result": {
    "message": "Operation completed"
  }
}
```

## Deployment

1. Create your function with the `@function` annotation
2. Create a `pubspec.yaml` file with dependencies
3. Deploy using the CLI:

```bash
dart_cloud deploy my-function /path/to/function
```

## Analysis Process

When you deploy a function, it goes through analysis:

1. **Syntax Check**: Validates Dart syntax
2. **Annotation Check**: Ensures `@function` annotation is present
3. **Security Scan**: Detects risky patterns (Process.run, shell access, etc.)
4. **Import Validation**: Checks for dangerous imports (dart:mirrors, dart:ffi)
5. **Signature Validation**: Ensures proper function structure

If analysis fails, deployment is rejected with detailed error messages.

## Best Practices

1. **Always use @function annotation** on your handler functions
2. **Keep functions focused** - one function, one purpose
3. **Handle errors gracefully** - use try-catch blocks
4. **Return structured JSON** - makes responses predictable
5. **Use environment variables** - for configuration
6. **Test locally** - before deploying
7. **Log important events** - helps with debugging
8. **Validate inputs** - check body and query parameters
9. **Set timeouts** - for external HTTP requests
10. **Use type safety** - leverage Dart's type system

## Common Errors

### Missing @function Annotation

```
Error: Missing @function annotation. Functions must be annotated with @function
```

**Solution**: Add `@function` annotation to your handler function.

### Risky Code Detected

```
Error: Detected Process execution - command execution is not allowed
```

**Solution**: Remove Process.run, Process.start, or similar dangerous operations.

### Invalid Input Structure

```
Error: Invalid input: must contain "body" or "query" fields
```

**Solution**: Ensure your function invocation includes body or query parameters.

## Example Project Structure

```
my-function/
├── main.dart          # Your function code
├── pubspec.yaml       # Dependencies
└── README.md          # Function documentation
```

### pubspec.yaml Example

```yaml
name: my_function
description: A cloud function
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  http: ^1.1.0
```

## Testing Locally

Before deploying, test your function locally:

```dart
// test.dart
import 'dart:convert';
import 'dart:io';

void main() async {
  // Simulate environment
  Platform.environment['FUNCTION_INPUT'] = jsonEncode({
    'body': {'name': 'John'},
    'query': {'age': '30'},
    'method': 'POST',
  });
  
  // Run your function
  // ... (your function code)
}
```

## Support

For issues or questions, refer to the ContainerPub documentation or contact support.
