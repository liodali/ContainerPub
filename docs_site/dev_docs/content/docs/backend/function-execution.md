---
title: Function Execution
description: How cloud functions are executed and the main.dart injection system
---

# Function Execution

This document describes how cloud functions are executed, including the main.dart injection system that automatically generates entry points for deployed functions.

## Overview

When you deploy a function, the backend:

1. Receives your function archive
2. Analyzes the code to find your `@cloudFunction` class
3. **Generates a main.dart** that serves as the entry point
4. Builds a container image with your function
5. Executes the container when the function is invoked

## Architecture

### Components

| Component                 | File                                                    | Purpose                               |
| ------------------------- | ------------------------------------------------------- | ------------------------------------- |
| **FunctionMainInjection** | `lib/services/function_main_injection.dart`             | Analyzes code and generates main.dart |
| **DeploymentHandler**     | `lib/handlers/function_handler/deployment_handler.dart` | Orchestrates deployment               |
| **DockerService**         | `lib/services/docker_service.dart`                      | Manages container execution           |

## Deployment Flow

```
1. User uploads function archive (tar.gz)
2. Backend extracts archive to function directory
3. FunctionMainInjection analyzes code:
   - Scans all .dart files (excluding main.dart)
   - Finds class with @cloudFunction annotation
   - Validates class extends CloudDartFunction
4. Generate main.dart:
   - Import dart:io, dart:convert
   - Import dart_cloud_function package
   - Import user's cloud function file
   - Create main() that handles invocation
5. Build Docker image with generated main.dart
6. Deploy function
```

## Execution Flow

```
1. User invokes function via API
2. Backend receives request with body, query, headers
3. DockerService.runContainer():
   - Creates temp directory
   - Writes request.json with CloudRequest data
   - Mounts request.json into container at /app/request.json
   - Runs container with environment variables
4. Container executes main.dart:
   - Reads environment variables
   - Reads request.json
   - Creates CloudRequest object
   - Instantiates user's cloud function class
   - Calls handle(request: request, env: env)
   - Writes CloudResponse to stdout
5. Backend captures stdout
6. Parses JSON response
7. Returns result to user
8. Cleans up temp directory
```

## Generated main.dart Structure

The system generates a main.dart file like this:

```dart
import 'dart:io';
import 'dart:convert';
import 'package:dart_cloud_function/dart_cloud_function.dart';
import 'lib/my_function.dart'; // User's function file

void main() async {
  try {
    // Read environment variables
    final env = Platform.environment;

    // Read request from request.json
    final requestFile = File('request.json');
    final requestJson = jsonDecode(await requestFile.readAsString());

    // Parse CloudRequest from JSON
    final request = CloudRequest(
      method: requestJson['method'] ?? 'POST',
      path: requestJson['path'] ?? '/',
      headers: Map<String, String>.from(requestJson['headers'] ?? {}),
      query: Map<String, String>.from(requestJson['query'] ?? {}),
      body: requestJson['body'],
    );

    // Instantiate the cloud function
    final function = MyFunction(); // User's class name

    // Execute the function
    final response = await function.handle(
      request: request,
      env: env,
    );

    // Write response to stdout as JSON
    final responseJson = {
      'statusCode': response.statusCode,
      'headers': response.headers,
      'body': response.body,
    };

    stdout.writeln(jsonEncode(responseJson));
    exit(0);
  } catch (e, stackTrace) {
    _writeError('Function execution failed: $e\n$stackTrace');
    exit(1);
  }
}

void _writeError(String message) {
  final errorResponse = {
    'statusCode': 500,
    'headers': {'content-type': 'application/json'},
    'body': {'error': message},
  };
  stdout.writeln(jsonEncode(errorResponse));
}
```

## User Function Requirements

For the injection to work, user functions must follow these rules:

| Requirement           | Description                                     |
| --------------------- | ----------------------------------------------- |
| **One class**         | Exactly one class extending `CloudDartFunction` |
| **Annotation**        | `@cloudFunction` annotation on that class       |
| **No main()**         | No `main()` function in user code               |
| **Override handle()** | Implement the `handle()` method                 |

### handle() Method Signature

```dart
Future<CloudResponse> handle({
  required CloudRequest request,
  Map<String, String>? env,
})
```

### Example User Function

```dart
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class MyFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    // Access environment variables
    final dbUrl = env?['DATABASE_URL'];

    // Access request data
    final body = request.body;
    final query = request.query;
    final headers = request.headers;

    // Return response
    return CloudResponse.json({
      'message': 'Hello from cloud function',
      'receivedBody': body,
    });
  }
}
```

## Data Flow

### Request Data (request.json)

```dart
{
  "method": "POST",
  "path": "/",
  "headers": {
    "content-type": "application/json",
    "authorization": "Bearer token"
  },
  "query": {
    "param1": "value1"
  },
  "body": {
    "key": "value"
  }
}
```

### Response Data (stdout)

```dart
{
  "statusCode": 200,
  "headers": {
    "content-type": "application/json"
  },
  "body": {
    "result": "success"
  }
}
```

## Environment Variables

Available to functions via `env` parameter:

| Variable                 | Description                         |
| ------------------------ | ----------------------------------- |
| `DART_CLOUD_RESTRICTED`  | Always "true"                       |
| `FUNCTION_TIMEOUT_MS`    | Execution timeout                   |
| `FUNCTION_MAX_MEMORY_MB` | Memory limit                        |
| `DATABASE_URL`           | Database connection (if configured) |
| `DB_MAX_CONNECTIONS`     | Max DB connections                  |
| `DB_TIMEOUT_MS`          | DB connection timeout               |

## Security

| Feature               | Description                          |
| --------------------- | ------------------------------------ |
| **Network Isolation** | Containers run with `--network none` |
| **Memory Limits**     | Default 128MB per function           |
| **CPU Limits**        | 0.5 cores per function               |
| **Execution Timeout** | Default 5 seconds                    |
| **Read-only Mount**   | request.json mounted as read-only    |
| **Auto-cleanup**      | Containers removed after execution   |
| **Temp File Cleanup** | request.json deleted after execution |

## Error Handling

### Injection Errors

If injection fails, deployment is aborted with error message:

```
Failed to inject main.dart. Ensure function has exactly one class
extending CloudDartFunction with @cloudFunction annotation.
```

**Common causes:**

- No `@cloudFunction` annotation
- Multiple classes with annotation
- Class doesn't extend `CloudDartFunction`
- No .dart files in function directory

### Runtime Errors

If function execution fails, error response is written to stdout:

```dart
{
  "statusCode": 500,
  "headers": { "content-type": "application/json" },
  "body": { "error": "Function execution failed: ..." }
}
```

## Troubleshooting

### Injection fails with "No class found"

- Verify `@cloudFunction` annotation is present
- Check class extends `CloudDartFunction`
- Ensure .dart files exist in archive

### Container fails to start

- Check Docker/Podman is running
- Verify base image is available
- Check function directory has main.dart

### Function times out

- Increase timeout in config
- Check for infinite loops
- Verify async operations complete

### request.json not found

- Check volume mount is working
- Verify temp directory creation
- Check file permissions

## Future Improvements

1. **Caching** - Cache analyzed function metadata
2. **Validation** - Pre-validate functions before deployment
3. **Hot Reload** - Support function updates without rebuild
4. **Streaming** - Support streaming responses
5. **Multi-file** - Support multiple function files
6. **Dependencies** - Auto-detect and install dependencies

## See Also

- [Backend Architecture](./architecture.md)
- [API Reference](./api-reference.md)
- [dart_cloud_function Package](../cli/dart-cloud-function.md)
