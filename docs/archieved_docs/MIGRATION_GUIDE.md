# Migration Guide: Function Security & Control

## Overview

This guide helps you migrate existing functions to the new security model that requires `@function` annotations and enforces HTTP-only operations.

## What Changed?

### 1. Required @function Annotation

**Before:**
```dart
void main() async {
  // Function code
}
```

**After:**
```dart
const function = 'function';

@function
void main() async {
  // Function code
}
```

### 2. HTTP Request Structure

**Before:**
```dart
void main() async {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  // Direct access to input
}
```

**After:**
```dart
@function
void main() async {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  
  // Structured HTTP request
  final body = input['body'] as Map<String, dynamic>? ?? {};
  final query = input['query'] as Map<String, dynamic>? ?? {};
  final method = input['method'] as String? ?? 'POST';
}
```

### 3. Function Invocation

**Before:**
```bash
dart_cloud invoke <function-id> --data '{"key": "value"}'
```

**After:**
```bash
dart_cloud invoke <function-id> --body '{"key": "value"}' --query '{"param": "value"}'
```

## Migration Steps

### Step 1: Add @function Annotation

Add the annotation constant and decorator to your function:

```dart
// At the top of your file
const function = 'function';

// Before your main function
@function
void main() async {
  // ...
}

// Also annotate handler functions
@function
Future<Map<String, dynamic>> handler(...) async {
  // ...
}
```

### Step 2: Update Input Handling

Modify how you access input parameters:

```dart
// Old way
final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
final name = input['name'];

// New way
final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
final body = input['body'] as Map<String, dynamic>? ?? {};
final query = input['query'] as Map<String, dynamic>? ?? {};
final name = body['name'] ?? query['name'];
```

### Step 3: Remove Risky Operations

Remove any operations that are no longer allowed:

```dart
// ❌ Remove Process execution
// Process.run('ls', ['-la']);

// ❌ Remove shell commands
// Shell.run('command');

// ❌ Remove raw sockets
// Socket.connect('host', 80);

// ✅ Replace with HTTP requests
import 'package:http/http.dart' as http;
await http.get(Uri.parse('https://api.example.com'));
```

### Step 4: Update Dependencies

If you were using restricted packages, replace them:

```yaml
# pubspec.yaml

# ❌ Remove
# dependencies:
#   dart_ffi: ^x.x.x

# ✅ Add allowed packages
dependencies:
  http: ^1.1.0
```

### Step 5: Test Locally

Test your migrated function:

```dart
// test.dart
import 'dart:convert';
import 'dart:io';

void main() async {
  // Simulate new input structure
  Platform.environment['FUNCTION_INPUT'] = jsonEncode({
    'body': {'name': 'Test'},
    'query': {'debug': 'true'},
    'method': 'POST',
  });
  
  // Run your function
  // import 'main.dart' as function;
  // await function.main();
}
```

### Step 6: Redeploy

Deploy your updated function:

```bash
dart_cloud deploy my-function ./path/to/function
```

## Common Migration Scenarios

### Scenario 1: Simple Data Processing

**Before:**
```dart
void main() async {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  final numbers = input['numbers'] as List;
  final sum = numbers.reduce((a, b) => a + b);
  print(jsonEncode({'sum': sum}));
}
```

**After:**
```dart
const function = 'function';

@function
void main() async {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  final body = input['body'] as Map<String, dynamic>? ?? {};
  
  final numbers = (body['numbers'] as List?)?.cast<num>() ?? [];
  final sum = numbers.reduce((a, b) => a + b);
  
  print(jsonEncode({'sum': sum}));
}
```

### Scenario 2: External API Calls

**Before:**
```dart
void main() async {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  final url = input['url'];
  
  // Using Process to call curl
  final result = await Process.run('curl', [url]);
  print(result.stdout);
}
```

**After:**
```dart
import 'package:http/http.dart' as http;

const function = 'function';

@function
void main() async {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  final body = input['body'] as Map<String, dynamic>? ?? {};
  final url = body['url'] as String?;
  
  if (url == null) {
    print(jsonEncode({'error': 'URL required'}));
    exit(1);
  }
  
  // Use HTTP package
  final response = await http.get(Uri.parse(url));
  print(jsonEncode({
    'statusCode': response.statusCode,
    'body': response.body,
  }));
}
```

### Scenario 3: File Processing

**Before:**
```dart
void main() async {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  final content = input['content'];
  
  // Write to system directory
  await File('/tmp/output.txt').writeAsString(content);
}
```

**After:**
```dart
const function = 'function';

@function
void main() async {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  final body = input['body'] as Map<String, dynamic>? ?? {};
  final content = body['content'] as String?;
  
  if (content == null) {
    print(jsonEncode({'error': 'Content required'}));
    exit(1);
  }
  
  // Write to function directory only
  await File('.output.txt').writeAsString(content);
  
  print(jsonEncode({
    'success': true,
    'message': 'File written',
  }));
}
```

## Troubleshooting

### Error: Missing @function annotation

**Problem:**
```
Error: Missing @function annotation. Functions must be annotated with @function
```

**Solution:**
Add the annotation to your function:
```dart
const function = 'function';

@function
void main() async {
  // ...
}
```

### Error: Detected Process execution

**Problem:**
```
Error: Detected Process execution - command execution is not allowed
```

**Solution:**
Remove `Process.run`, `Process.start`, or similar operations. Use HTTP requests instead:
```dart
import 'package:http/http.dart' as http;
final response = await http.get(Uri.parse(url));
```

### Error: Invalid input structure

**Problem:**
```
Error: Invalid input: must contain "body" or "query" fields
```

**Solution:**
Update your invocation to include body or query:
```bash
# Old
dart_cloud invoke <id> --data '{"key": "value"}'

# New
dart_cloud invoke <id> --body '{"key": "value"}'
```

### Warning: File write operations detected

**Problem:**
```
Warning: File write operations detected - ensure they are within function scope
```

**Solution:**
This is a warning, not an error. Ensure file operations are within the function directory:
```dart
// Good - relative path
await File('.temp.json').writeAsString(data);

// Bad - absolute path outside function
await File('/tmp/file.txt').writeAsString(data);
```

## Database Migration

If you're upgrading an existing deployment, run this SQL to add the analysis_result column:

```sql
ALTER TABLE functions 
ADD COLUMN IF NOT EXISTS analysis_result JSONB;
```

## CLI Updates

Update your CLI invocation commands:

**Old:**
```bash
dart_cloud invoke <function-id> --data '{"name": "Alice", "age": 30}'
```

**New:**
```bash
# Using body
dart_cloud invoke <function-id> --body '{"name": "Alice", "age": 30}'

# Using query
dart_cloud invoke <function-id> --query '{"name": "Alice", "age": "30"}'

# Using both
dart_cloud invoke <function-id> \
  --body '{"data": "value"}' \
  --query '{"filter": "active"}'
```

## Checklist

Before redeploying your functions:

- [ ] Added `const function = 'function';` at the top
- [ ] Added `@function` annotation to main and handler functions
- [ ] Updated input handling to use body/query structure
- [ ] Removed Process.run, Process.start, shell commands
- [ ] Removed raw socket operations
- [ ] Removed dart:ffi and dart:mirrors imports
- [ ] Replaced system commands with HTTP requests
- [ ] Updated pubspec.yaml with allowed dependencies
- [ ] Tested locally with new input structure
- [ ] Updated invocation commands to use --body/--query

## Support

If you encounter issues during migration:

1. Check `FUNCTION_TEMPLATE.md` for examples
2. Review `SECURITY.md` for detailed restrictions
3. Look at `examples/` directory for working examples
4. Check function logs for detailed error messages

## Rollback

If you need to rollback temporarily:

1. Keep old function code in a separate directory
2. Deploy old version without new security features
3. Note: Old functions will fail analysis in future versions

## Timeline

- **Phase 1**: New security features available (current)
- **Phase 2**: Warning period for old functions (30 days)
- **Phase 3**: Enforcement - all functions must comply (60 days)

Migrate your functions as soon as possible to avoid disruption.
