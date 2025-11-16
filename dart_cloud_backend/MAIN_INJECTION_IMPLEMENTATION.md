# Main.dart Injection Implementation

## Overview

This document describes the implementation of the main.dart injection system for cloud function deployment. The system automatically generates a main.dart file that serves as the entry point for deployed cloud functions.

## Architecture

### Components

1. **FunctionMainInjection** (`lib/services/function_main_injection.dart`)
   - Analyzes function code to find `@cloudFunction` annotated classes
   - Generates main.dart with proper imports and invocation logic
   - Writes the generated file to the function directory

2. **DeploymentHandler** (`lib/handlers/function_handler/deployment_handler.dart`)
   - Calls `FunctionMainInjection.injectMain()` after extracting function archive
   - Validates injection success before building Docker image
   - Logs injection progress

3. **DockerService** (`lib/services/docker_service.dart`)
   - Creates `request.json` file with CloudRequest data
   - Mounts request.json into container at `/app/request.json`
   - Cleans up temporary files after execution

## Workflow

### Deployment Flow

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
   - Create main() that:
     * Reads Platform.environment for env vars
     * Reads request.json for CloudRequest
     * Instantiates cloud function class
     * Calls handle() method
     * Writes CloudResponse to stdout as JSON
5. Build Docker image with generated main.dart
6. Deploy function
```

### Execution Flow

```
1. User invokes function via API
2. Backend receives request with body, query, headers
3. DockerService.runContainer():
   - Creates temp directory
   - Writes request.json with CloudRequest data:
     {
       "method": "POST",
       "path": "/",
       "headers": {...},
       "query": {...},
       "body": {...}
     }
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

1. **Exactly one class** extending `CloudDartFunction`
2. **@cloudFunction annotation** on that class
3. **No main() function** in user code
4. **Override handle() method** with signature:
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

## Error Handling

### Injection Errors

If injection fails, deployment is aborted with error message:
```
Failed to inject main.dart. Ensure function has exactly one class 
extending CloudDartFunction with @cloudFunction annotation.
```

Common causes:
- No `@cloudFunction` annotation
- Multiple classes with annotation
- Class doesn't extend `CloudDartFunction`
- No .dart files in function directory

### Runtime Errors

If function execution fails, error response is written to stdout:
```json
{
  "statusCode": 500,
  "headers": {"content-type": "application/json"},
  "body": {"error": "Function execution failed: ..."}
}
```

## Data Flow

### Request Data (request.json)

```json
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

```json
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

- `DART_CLOUD_RESTRICTED`: Always "true"
- `FUNCTION_TIMEOUT_MS`: Execution timeout
- `FUNCTION_MAX_MEMORY_MB`: Memory limit
- `DATABASE_URL`: Database connection (if configured)
- `DB_MAX_CONNECTIONS`: Max DB connections
- `DB_TIMEOUT_MS`: DB connection timeout

## Security

1. **Network Isolation**: Containers run with `--network none`
2. **Memory Limits**: Default 128MB per function
3. **CPU Limits**: 0.5 cores per function
4. **Execution Timeout**: Default 5 seconds
5. **Read-only Mount**: request.json mounted as read-only
6. **Auto-cleanup**: Containers removed after execution
7. **Temp File Cleanup**: request.json deleted after execution

## Testing

To test the injection system:

1. Create a test function:
```dart
// lib/test_function.dart
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class TestFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({'test': 'success'});
  }
}
```

2. Package and deploy:
```bash
tar -czf function.tar.gz lib/ pubspec.yaml
curl -X POST http://localhost:8080/api/functions/deploy \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=test-function" \
  -F "archive=@function.tar.gz"
```

3. Invoke function:
```bash
curl -X POST http://localhost:8080/api/functions/{id}/invoke \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"body": {"test": "data"}}'
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

1. **Caching**: Cache analyzed function metadata
2. **Validation**: Pre-validate functions before deployment
3. **Hot Reload**: Support function updates without rebuild
4. **Streaming**: Support streaming responses
5. **Multi-file**: Support multiple function files
6. **Dependencies**: Auto-detect and install dependencies
