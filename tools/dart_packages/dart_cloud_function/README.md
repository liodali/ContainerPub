---

# dart_cloud_function

Minimal foundation for serverless HTTP functions in Dart. Extend `CloudDartFunction`, implement `handle()`, and deploy.

**Note:** This package is still in development and subject to change. Not Fully opensource we will make opensource when our early access platform become available

## Install

```yaml
dependencies:
  dart_cloud_function: ^0.2.0
```

```dart
import 'package:dart_cloud_function/dart_cloud_function.dart';
```

## Quick Start

```dart
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class EchoFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    required CloudDartFunctionLogger logger,
    Map<String, String>? env,
  }) async {
    logger.info('Handling request: ${request.path}');
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
    required CloudDartFunctionLogger logger,
    Map<String, String>? env,
  }) async {
    logger.info('Processing request');
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

- `CloudDartFunction` (abstract)
  - `Future<CloudResponse> handle({required CloudRequest request, required CloudDartFunctionLogger logger, Map<String, String>? env})`
- `CloudRequest`
  - `String method`
  - `String path`
  - `Map<String, String> headers`
  - `Map<String, String> query`
  - `dynamic body` (JSON-decoded object when `content-type: application/json`, otherwise `String`)
  - `HttpRequest? raw`
- `CloudResponse`
  - `int statusCode`
  - `Map<String, String> headers`
  - `dynamic body` (`String`, `List<int>` for binary, or any JSON-encodable object)
  - Helpers: `CloudResponse.json(Object body, {int statusCode, Map<String,String>? headers})`, `CloudResponse.text(String body, {int statusCode, Map<String,String>? headers})`
  - `void writeTo(HttpResponse res)` to flush the response on a `dart:io` server.

## Request Body Parsing

- `CloudRequest` is framework-agnostic; construct it from your platform’s incoming request.
- Recommended mapping with `dart:io`:
  ```dart
  Future<CloudRequest> toCloudRequest(HttpRequest req) async {
    dynamic body;
    if (req.method != 'GET' && req.method != 'HEAD') {
      final bytes = await req.fold<List<int>>(<int>[], (p, e) { p.addAll(e); return p; });
      final mime = req.headers.contentType?.mimeType ?? '';
      if (mime == 'application/json') {
        body = jsonDecode(utf8.decode(bytes));
      } else {
        body = utf8.decode(bytes);
      }
    }
    return CloudRequest(
      method: req.method,
      path: req.uri.path,
      headers: { for (final e in req.headers.entries) e.key: e.value.join(',') },
      query: req.uri.queryParameters,
      body: body,
      raw: req,
    );
  }
  ```

## Error Handling

- Handle errors inside `handle` and return a `CloudResponse` with the appropriate status and body.
- Example:
  ```dart
  try {
    // business logic
    return CloudResponse.json({'ok': true});
  } catch (e) {
    return CloudResponse.json({'error': e.toString()}, statusCode: 500);
  }
  ```

## Advanced Usage

- Custom status and headers:
  ```dart
  return CloudResponse(statusCode: 201, headers: {'cache-control': 'no-store'}, body: {'created': true});
  ```
- Binary responses (e.g., images):
  ```dart
  return CloudResponse(statusCode: 200, headers: {'content-type': 'image/png'}, body: pngBytes);
  ```
- Basic routing inside `handle`:
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

## Testing

- Unit test your function classes by directly invoking `handle`:

  ```dart
  class TestFn extends CloudDartFunction {
    @override
    Future<CloudResponse> handle(CloudRequest request) async => CloudResponse.text('ok');
  }

  final res = await TestFn().handle(CloudRequest(method: 'GET', path: '/', headers: {}, query: {}));
  ```

- See `test/dart_cloud_function_test.dart` for an example.

## Source Layout

- Public API: `lib/dart_cloud_function.dart`
- Core implementation: `lib/src/dart_cloud_function_base.dart`
- Example app: `example/dart_cloud_function_example.dart`
