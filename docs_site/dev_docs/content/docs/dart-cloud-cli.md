# Dart Cloud CLI

Command-line interface for deploying and managing Dart serverless functions.

## Overview

`dart_cloud_cli` is a powerful CLI tool that enables developers to:
- Deploy Dart cloud functions with a single command
- Validate function structure and security automatically
- Manage deployed functions (list, invoke, delete)
- View function logs and metrics
- Authenticate with the Dart Cloud platform

## Installation

### From Source

```dart
cd dart_cloud_cli
dart pub get
dart pub global activate --source path .
```

Now you can use `dart_cloud` from anywhere.

## Quick Start

### 1. Login

```dart
dart_cloud login
```

You'll be prompted for your email and password.

### 2. Create a Function

```dart
mkdir my-function
cd my-function
dart create -t console-simple .
```

### 3. Add dart_cloud_function Dependency

Edit `pubspec.yaml`:

```dart
dependencies:
  dart_cloud_function: ^1.0.0
```

### 4. Write Your Function

Create `main.dart`:

```dart
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class MyFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({
      'message': 'Hello, World!',
      'path': request.path,
    });
  }
}
```

### 5. Deploy

```dart
dart_cloud deploy ./my-function
```

## Commands

### login
Authenticate with the Dart Cloud platform.

```dart
dart_cloud login
```

### deploy
Deploy a Dart function from a directory.

```dart
dart_cloud deploy <path-to-function>
```

**Validation Phases:**

**Phase 1 - Deployment Restrictions:**
- Function size < 5 MB
- No forbidden directories (`.git`, `node_modules`, etc.)
- No forbidden files (`.env`, `secrets.json`, etc.)
- Required files present (`pubspec.yaml`, `main.dart`)

**Phase 2 - Code Analysis:**
- Exactly one `CloudDartFunction` class
- `@cloudFunction` annotation present
- No `main()` function
- Security checks (no process execution, FFI, mirrors)

### list
List all deployed functions.

```dart
dart_cloud list
```

### logs
View logs for a specific function.

```dart
dart_cloud logs <function-id>
```

### invoke
Invoke a deployed function with optional data.

```dart
dart_cloud invoke <function-id> [--data '{"key": "value"}']
```

### delete
Delete a deployed function.

```dart
dart_cloud delete <function-id>
```

### help
Show help information.

```dart
dart_cloud help
```

### version
Show CLI version.

```dart
dart_cloud version
```

## Deployment Validation

The CLI performs comprehensive validation before deployment:

### Size Limits
- **Maximum:** 5 MB
- **Warning:** 4 MB

### Forbidden Directories
- `.git` - Version control
- `.github` - GitHub workflows
- `.vscode`, `.idea` - IDE configs
- `node_modules` - Node dependencies
- `.dart_tool` - Dart build artifacts
- `build`, `.gradle`, `.cocoapods` - Build directories

### Forbidden Files
- `.env`, `.env.local` - Environment files
- `secrets.json`, `credentials.json` - Credentials
- `*.pem`, `*.key`, `*.p12`, `*.pfx` - Private keys

### Code Validation
- Exactly one `CloudDartFunction` class
- `@cloudFunction` annotation required
- No `main()` function
- No dangerous imports (dart:mirrors, dart:ffi)
- No process execution (Process.run, Shell, etc.)

## Configuration

The CLI configuration is stored at `~/.dart_cloud/config.json`:

```dart
{
  "authToken": "your-jwt-token",
  "serverUrl": "http://localhost:8080"
}
```

You can manually edit this file to change the server URL.

## Examples

### Simple Echo Function

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

### JSON Processing Function

```dart
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class ProcessorFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    try {
      final data = request.body as Map<String, dynamic>;
      final result = {
        'processed': true,
        'input': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      return CloudResponse.json(result);
    } catch (e) {
      return CloudResponse.json(
        {'error': e.toString()},
        statusCode: 400,
      );
    }
  }
}
```

## Troubleshooting

### Authentication Issues
```dart
dart_cloud login
```

### Deployment Size Exceeded
Remove unnecessary files:
```dart
rm -rf .git .dart_tool build node_modules
```

### Missing @cloudFunction Annotation
Add annotation to your class:
```dart
@cloudFunction
class MyFunction extends CloudDartFunction { ... }
```

### main() Function Not Allowed
Remove the main function - the platform handles invocation.

### Connection Issues
Verify the backend server is running and accessible at the configured URL.

## Documentation

- [Analyzer Rules](../../../dart_cloud_cli/docs/ANALYZER_RULES.md) - Validation rules
- [Deployment Config](../../../dart_cloud_cli/docs/DEPLOYMENT_CONFIG.md) - Configuration details
- [dart_cloud_function Package](../dart-cloud-function.md) - Function package documentation

## See Also

- [dart_cloud_function Package](./dart-cloud-function.md)
- [Architecture](./architecture.md)
- [API Reference](./api-reference.md)
