# ContainerPub Function Examples

This directory contains example functions that demonstrate the required syntax and security features.

## Examples

### 1. Simple Function (`simple-function/`)

A basic function that demonstrates:
- `@function` annotation requirement
- HTTP request structure (body and query parameters)
- Proper input/output handling
- Error handling

**Usage:**
```bash
dart_cloud deploy simple-function ./simple-function
dart_cloud invoke <function-id> --body '{"name": "Alice"}'
```

### 2. HTTP Function (`http-function/`)

Demonstrates allowed HTTP operations:
- Making external HTTP requests
- Timeout handling
- Error handling for network operations

**Usage:**
```bash
dart_cloud deploy http-function ./http-function
dart_cloud invoke <function-id> --body '{"url": "https://api.github.com"}'
```

## Key Requirements

All functions must:

1. **Have @function annotation**
   ```dart
   const function = 'function';
   
   @function
   void main() async {
     // function code
   }
   ```

2. **Accept HTTP request structure**
   - `body`: Request body parameters
   - `query`: Query string parameters
   - `method`: HTTP method (GET, POST, etc.)
   - `headers`: Request headers

3. **Follow security restrictions**
   - ❌ No command execution (Process.run, Process.start)
   - ❌ No shell access
   - ❌ No raw socket operations
   - ❌ No FFI (dart:ffi)
   - ❌ No reflection (dart:mirrors)
   - ✅ HTTP requests allowed
   - ✅ JSON processing allowed
   - ✅ Standard library operations allowed

4. **Return JSON to stdout**
   ```dart
   print(jsonEncode({
     'success': true,
     'result': data,
   }));
   ```

## Testing Locally

Before deploying, test your function:

```dart
// Set environment variable
Platform.environment['FUNCTION_INPUT'] = jsonEncode({
  'body': {'key': 'value'},
  'query': {},
  'method': 'POST',
});

// Run your function
dart run main.dart
```

## Deployment Process

1. **Analysis Phase**: Function code is analyzed for:
   - @function annotation presence
   - Security violations
   - Dangerous imports
   - Risky patterns

2. **Validation Phase**: If analysis fails, deployment is rejected with detailed errors

3. **Execution Phase**: Valid functions are stored and can be invoked

## Common Errors

### Missing @function Annotation
```
Error: Missing @function annotation. Functions must be annotated with @function
```
**Fix**: Add `@function` annotation to your handler function.

### Security Violation
```
Error: Detected Process execution - command execution is not allowed
```
**Fix**: Remove Process.run, Process.start, or similar operations.

### Invalid Input
```
Error: Invalid input: must contain "body" or "query" fields
```
**Fix**: Invoke function with proper body or query parameters.

## Best Practices

1. Always validate input parameters
2. Use try-catch for error handling
3. Return structured JSON responses
4. Set timeouts for external requests
5. Keep functions focused and simple
6. Test locally before deploying
7. Document your function's expected inputs/outputs

## Need Help?

Refer to `FUNCTION_TEMPLATE.md` in the root directory for detailed documentation.
