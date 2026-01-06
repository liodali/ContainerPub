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
   - Creates shared directory at: functionsDir/functionUUID/version/containerName
   - Writes request.json with CloudRequest data
   - Writes .env.config with environment variables
   - Creates empty logs.json and result.json placeholders
   - Mounts shared volume (functions_data) into container
   - Runs container with working directory set to shared path
4. Container executes main.dart:
   - Reads environment variables from .env.config
   - Reads request.json from shared volume
   - Creates CloudRequest object
   - Instantiates user's cloud function class
   - Calls handle(request: request, env: env)
   - Writes logs to logs.json in shared volume
   - Writes CloudResponse to result.json in shared volume
5. Backend reads result.json from shared volume
6. Backend reads logs.json from shared volume
7. Returns result to user
8. Cleans up shared directory
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

## Shared Volume Architecture

### Volume Structure

ContainerPub uses a **shared named volume** (`functions_data`) to exchange data between the backend and function containers:

```
functions_data/
└── {functionUUID}/
    └── v{version}/
        └── {containerName}/
            ├── request.json      # Input (backend → function)
            ├── .env.config       # Environment (backend → function)
            ├── logs.json         # Logs (function → backend)
            └── result.json       # Output (function → backend)
```

**Volume Configuration:**

- **Name:** Configurable via `SHARED_VOLUME_NAME` environment variable
- **Default:** `functions_data`
- **Mount:** `functions_data:/app/functions:Z,rshared`
- **Propagation:** `rshared` for nested mounts

### Data Flow

#### 1. Request Data (request.json)

**Written by:** Backend  
**Read by:** Function container  
**Location:** `{sharedDir}/request.json`

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

#### 2. Environment Config (.env.config)

**Written by:** Backend  
**Read by:** Function container  
**Location:** `{sharedDir}/.env.config`

```bash
DART_CLOUD_RESTRICTED=true
FUNCTION_TIMEOUT_MS=5000
FUNCTION_MAX_MEMORY_MB=128
SHARED_PATH=/app/functions/{uuid}/v{version}/{containerName}
```

#### 3. Function Logs (logs.json)

**Written by:** Function container  
**Read by:** Backend  
**Location:** `{sharedDir}/logs.json`

```json
{
  "logs": [
    {
      "level": "info",
      "message": "Processing request",
      "timestamp": "2024-01-06T00:00:00.000Z"
    }
  ]
}
```

#### 4. Response Data (result.json)

**Written by:** Function container  
**Read by:** Backend  
**Location:** `{sharedDir}/result.json`

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

Available to functions via `.env.config` file in shared volume:

| Variable                 | Description                         | Example                           |
| ------------------------ | ----------------------------------- | --------------------------------- |
| `DART_CLOUD_RESTRICTED`  | Always "true"                       | `true`                            |
| `FUNCTION_TIMEOUT_MS`    | Execution timeout                   | `5000`                            |
| `FUNCTION_MAX_MEMORY_MB` | Memory limit                        | `128`                             |
| `SHARED_PATH`            | Path to shared volume directory     | `/app/functions/{uuid}/v1/{name}` |
| `DATABASE_URL`           | Database connection (if configured) | `postgres://...`                  |
| `DB_MAX_CONNECTIONS`     | Max DB connections                  | `5`                               |
| `DB_TIMEOUT_MS`          | DB connection timeout               | `3000`                            |

## Security

| Feature               | Description                                  |
| --------------------- | -------------------------------------------- |
| **Network Isolation** | Containers run with `--network none`         |
| **Memory Limits**     | Dynamic based on image size (min 20MB)       |
| **CPU Limits**        | 0.5 cores per function                       |
| **Execution Timeout** | Default 5 seconds                            |
| **Volume Isolation**  | Each function gets isolated shared directory |
| **SELinux Labels**    | Volume mounted with `:Z` for proper labeling |
| **Propagation**       | `rshared` for nested mount support           |
| **Auto-cleanup**      | Containers and shared directories removed    |
| **File Cleanup**      | All files in shared directory deleted        |

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

- Check shared volume mount is working
- Verify shared directory creation at: `functionsDir/{uuid}/v{version}/{containerName}`
- Check volume name matches `SHARED_VOLUME_NAME` environment variable
- Verify file permissions in shared volume
- Test volume mount: `podman volume inspect functions_data`

## Shared Volume Benefits

### Advantages

1. **Separation of Concerns**

   - Function output (result.json) separate from debug logs (stdout/stderr)
   - Clean separation between function logs and container logs

2. **Persistent Storage**

   - Shared volume persists across backend and function containers
   - No need for temporary directories in backend container

3. **Structured Data Exchange**

   - JSON files for structured data
   - Environment file for configuration
   - Clear contract between backend and function

4. **Debugging**
   - Easy to inspect files in shared volume
   - Logs and results available for troubleshooting
   - Clear separation of concerns

### Volume Management

**Create Volume:**

```bash
podman volume create functions_data
```

**Inspect Volume:**

```bash
podman volume inspect functions_data
```

**List Files:**

```bash
podman run --rm -v functions_data:/data alpine ls -la /data
```

**Clean Volume:**

```bash
podman volume rm functions_data
```

## Future Improvements

1. **Caching** - Cache analyzed function metadata
2. **Validation** - Pre-validate functions before deployment
3. **Hot Reload** - Support function updates without rebuild
4. **Streaming** - Support streaming responses via shared volume
5. **Multi-file** - Support multiple function files
6. **Dependencies** - Auto-detect and install dependencies
7. **Volume Cleanup** - Automatic cleanup of old function directories
8. **Volume Encryption** - Encrypt shared volume data at rest

## See Also

- [Backend Architecture](./architecture.md)
- [API Reference](./api-reference.md)
- [dart_cloud_function Package](../cli/dart-cloud-function.md)
