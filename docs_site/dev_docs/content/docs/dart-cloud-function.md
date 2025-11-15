# dart_cloud_function Package

Minimal foundation for serverless HTTP functions in Dart.

## Overview

`dart_cloud_function` is a lightweight Dart package that provides:
- Simple abstract base class for cloud functions
- Lightweight request/response models
- Automatic HTTP parsing and handling
- Convenience response helpers
- Support for binary responses
- Zero-cost abstractions

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dart_cloud_function: ^1.0.0
```

Import the library:

```dart
import 'package:dart_cloud_function/dart_cloud_function.dart';
```

## Quick Start

Create a function by extending `CloudDartFunction` and implementing `handle()`:

```dart
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class EchoFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({
      'method': request.method,
      'path': request.path,
      'query': request.query,
      'body': request.body,
    });
  }
}
```

## Required Structure

When deploying with `dart_cloud_cli`, your function **must** follow these rules:

### ✓ Exactly One CloudDartFunction Class
Your `main.dart` must contain exactly one class extending `CloudDartFunction`.

### ✓ @cloudFunction Annotation
The class must be annotated with `@cloudFunction`.

### ✓ No main() Function
Do not include a `main()` function. The platform handles invocation.

### Example - Valid ✅
```dart
@cloudFunction
class MyFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({'message': 'Hello'});
  }
}
```

### Example - Invalid ❌
```dart
// Missing @cloudFunction annotation
class MyFunction extends CloudDartFunction { ... }

// Multiple classes not allowed
@cloudFunction
class Function1 extends CloudDartFunction { ... }
@cloudFunction
class Function2 extends CloudDartFunction { ... }

// main() not allowed
void main() { }
```

## API Reference

### CloudDartFunction
Abstract base class for cloud functions.

```dart
abstract class CloudDartFunction {
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  });
}
```

### CloudRequest
Incoming HTTP request.

**Properties:**
- `String method` - HTTP method (GET, POST, etc.)
- `String path` - Request path
- `Map<String, String> headers` - HTTP headers
- `Map<String, String> query` - Query parameters
- `dynamic body` - Request body (auto-parsed JSON or String)
- `HttpRequest? raw` - Access to underlying HttpRequest

### CloudResponse
HTTP response to send back.

**Properties:**
- `int statusCode` - HTTP status code (default: 200)
- `Map<String, String> headers` - Response headers
- `dynamic body` - Response body (String, List<int>, or JSON-encodable object)

**Constructors:**
- `CloudResponse(statusCode, headers, body)` - Full control
- `CloudResponse.json(Object body, {statusCode, headers})` - JSON response
- `CloudResponse.text(String body, {statusCode, headers})` - Text response

**Methods:**
- `void writeTo(HttpResponse res)` - Write response to HttpResponse

## Usage Examples

### Error Handling
```dart
@cloudFunction
class SafeFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    try {
      // business logic
      return CloudResponse.json({'ok': true});
    } catch (e) {
      return CloudResponse.json(
        {'error': e.toString()},
        statusCode: 500,
      );
    }
  }
}
```

### Custom Status & Headers
```dart
return CloudResponse(
  statusCode: 201,
  headers: {'cache-control': 'no-store'},
  body: {'created': true},
);
```

### Binary Responses
```dart
return CloudResponse(
  statusCode: 200,
  headers: {'content-type': 'image/png'},
  body: pngBytes,  // List<int>
);
```

### Basic Routing
```dart
switch (request.path) {
  case '/health':
    return CloudResponse.text('ok');
  case '/users':
    return CloudResponse.json({'users': []});
  default:
    return CloudResponse.text('not found', statusCode: 404);
}
```

### Query Parameters
```dart
final name = request.query['name'] ?? 'World';
return CloudResponse.json({'message': 'Hello, $name!'});
```

### Request Body Parsing
```dart
// Automatic JSON parsing
final data = request.body as Map<String, dynamic>;
final id = data['id'] as int;
```

## Deployment Validation

The `dart_cloud_cli` analyzer validates:
- ✓ Exactly one `CloudDartFunction` class
- ✓ `@cloudFunction` annotation present
- ✓ No `main()` function
- ✓ Security checks (no process execution, FFI, mirrors)

**Common Errors:**
- `No CloudDartFunction class found` → Add a class extending `CloudDartFunction`
- `Missing @cloudFunction annotation` → Add `@cloudFunction` above your class
- `main() function is not allowed` → Remove the `main()` function
- `Multiple CloudDartFunction classes found` → Keep only one class

## Testing

```dart
test('echo function works', () async {
  final fn = EchoFunction();
  final res = await fn.handle(
    request: CloudRequest(
      method: 'GET',
      path: '/test',
      headers: {},
      query: {'name': 'test'},
    ),
    env: {},
  );
  
  expect(res.statusCode, 200);
  expect(res.body, isNotNull);
});
```

## Best Practices

1. **Keep it simple** - One function per package
2. **Use descriptive names** - `UserAuthFunction`, `DataProcessorFunction`
3. **Document your function** - Add doc comments
4. **Handle errors gracefully** - Return appropriate HTTP status codes
5. **Use environment variables** - Access secrets via `env` parameter
6. **Minimize dependencies** - Keep function size under 5 MB
7. **Test locally** - Verify before deployment

## Project Structure

```
my-function/
├── main.dart              # Your @cloudFunction class
├── pubspec.yaml           # Dependencies
├── test/
│   └── main_test.dart     # Unit tests
└── README.md              # Documentation
```

## Deployment

Deploy your function using `dart_cloud_cli`:

```bash
dart_cloud deploy ./my-function
```

The CLI will:
1. Validate deployment restrictions (size, files, directories)
2. Analyze code structure and security
3. Create an archive
4. Upload to the platform

## See Also

- [dart_cloud_cli Documentation](./dart-cloud-cli.md) - CLI usage guide
- [Analyzer Rules](../../../dart_cloud_cli/docs/ANALYZER_RULES.md) - Validation rules
- [Deployment Config](../../../dart_cloud_cli/docs/DEPLOYMENT_CONFIG.md) - Configuration details
