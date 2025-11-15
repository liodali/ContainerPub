
---

# dart_cloud_function

Minimal, opinionated foundation for serverless-style HTTP functions in Dart. Implement a single `handle` method and let the package take care of the HTTP server, request parsing, and response writing.

## Features

- Simple abstract base: implement `handle({required CloudRequest request, Map<String, String>? env})` and return `CloudResponse`.
- Lightweight request/response models to keep business logic focused.
- Automatic parsing guidance for method, path, headers, query, and body (JSON/text).
- Convenience response helpers: `CloudResponse.json(...)`, `CloudResponse.text(...)`.
- Support for binary responses via `List<int>` body.
- Access to the underlying `HttpRequest` when needed.

## Install

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

Create a function by extending `CloudDartFunction` and implement `handle`. Export a single handler your platform can invoke with a `CloudRequest` and environment map:

```dart
import 'package:dart_cloud_function/dart_cloud_function.dart';

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

Future<CloudResponse> functionHandler(CloudRequest request, Map<String, String> env) {
  return EchoFunction().handle(request: request, env: env);
}
```

See the runnable example in `example/dart_cloud_function_example.dart`.

## API Reference

- `CloudDartFunction` (abstract)
  - `Future<CloudResponse> handle({required CloudRequest request, Map<String, String>? env})`
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
