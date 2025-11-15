# Dart Cloud CLI

Command-line interface for deploying and managing Dart serverless functions on Dart Cloud.

## Installation

### From Source

```bash
cd dart_cloud_cli
dart pub get
dart pub global activate --source path .
```

Now you can use `dart_cloud` from anywhere.

## Configuration

The CLI stores configuration in `~/.dart_cloud/config.json`.

## Commands

### login
Authenticate with the Dart Cloud platform.

```bash
dart_cloud login
```

You'll be prompted for your email and password.

### deploy
Deploy a Dart function from a directory.

```bash
dart_cloud deploy <path-to-function>
```

Example:
```bash
dart_cloud deploy ./my-function
```

The function directory must contain a `pubspec.yaml` file.

**Deployment Validation:**
Before deployment, the CLI performs strict validation in two phases:

**Phase 1 - Deployment Restrictions:**
- **Size limit** - Function must be < 5 MB
- **Forbidden directories** - No `.git`, `node_modules`, `.dart_tool`, `build`, etc.
- **Forbidden files** - No `.env`, `secrets.json`, `*.pem`, `*.key`, etc.
- **Required files** - Must have `pubspec.yaml` and `main.dart` (or `bin/main.dart`)

**Phase 2 - Code Analysis:**
- **Exactly one CloudDartFunction class** - Must have one class extending `CloudDartFunction`
- **@cloudFunction annotation required** - The class must be annotated with `@cloudFunction`
- **No main() function** - The `main.dart` file must not contain a `main()` function
- **Security checks** - Scans for risky patterns (Process execution, shell access, etc.)
- **Import validation** - Checks for dangerous imports (dart:mirrors, dart:ffi)

Only functions that pass all validations are uploaded to the server.

### list
List all your deployed functions.

```bash
dart_cloud list
```

### logs
View logs for a specific function.

```bash
dart_cloud logs <function-id>
```

### invoke
Invoke a deployed function with optional data.

```bash
dart_cloud invoke <function-id> [--data '{"key": "value"}']
```

Example:
```bash
dart_cloud invoke abc-123 --data '{"name": "Alice"}'
```

### delete
Delete a deployed function.

```bash
dart_cloud delete <function-id>
```

You'll be asked to confirm the deletion.

### help
Show help information.

```bash
dart_cloud help
```

### version
Show CLI version.

```bash
dart_cloud version
```

## Creating a Function

1. Create a new directory for your function:
```bash
mkdir my-function
cd my-function
```

2. Initialize a Dart project:
```bash
dart create -t console-simple .
```

3. Add the `dart_cloud_function` dependency to `pubspec.yaml`:
```yaml
dependencies:
  dart_cloud_function: ^1.0.0
```

4. Write your function in `main.dart`:
```dart
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class MyFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    final name = request.query['name'] ?? 'World';
    
    return CloudResponse.json({
      'message': 'Hello, $name!',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

**Important:** 
- Your function must have exactly **one** class extending `CloudDartFunction`
- The class must be annotated with `@cloudFunction`
- Do **not** include a `main()` function

5. Deploy your function:
```bash
dart_cloud deploy ./my-function
```

## Examples

### Simple Hello World Function

```dart
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class HelloFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    final name = request.body?['name'] ?? 'World';
    
    return CloudResponse.json({
      'message': 'Hello, $name!',
    });
  }
}
```

### Data Processing Function

```dart
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class DataProcessorFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    final numbers = (request.body?['numbers'] as List?)?.cast<num>() ?? [];
    
    if (numbers.isEmpty) {
      return CloudResponse.json(
        {'error': 'No numbers provided'},
        statusCode: 400,
      );
    }
    
    final result = {
      'sum': numbers.fold(0, (a, b) => a + b),
      'average': numbers.reduce((a, b) => a + b) / numbers.length,
      'count': numbers.length,
      'min': numbers.reduce((a, b) => a < b ? a : b),
      'max': numbers.reduce((a, b) => a > b ? a : b),
    };
    
    return CloudResponse.json(result);
  }
}
```

## Troubleshooting

### Authentication Issues
If you're having authentication issues, try logging in again:
```bash
dart_cloud login
```

### Deployment Failures

**Deployment Restrictions:**
- Function size exceeds 5 MB → Remove unnecessary files (`.git`, `node_modules`, `build/`, etc.)
- Forbidden directories found → Remove `.git`, `.dart_tool`, `build`, `node_modules`
- Forbidden files found → Remove `.env`, `secrets.json`, `*.pem`, `*.key` files
- Missing `pubspec.yaml` → Ensure it exists in function root
- Missing `main.dart` → Create `main.dart` or `bin/main.dart`

**Code Analysis Errors:**
- No CloudDartFunction class found → Add a class extending `CloudDartFunction`
- Multiple CloudDartFunction classes → Keep only one class
- Missing `@cloudFunction` annotation → Add `@cloudFunction` above your class
- `main()` function is not allowed → Remove the `main()` function
- Dangerous operations detected → Remove Process.run, Shell, FFI, mirrors imports
- Restricted imports found → Avoid dart:mirrors, dart:ffi

### Connection Issues
Make sure the backend server is running and accessible at the configured URL (default: http://localhost:8080).

## Configuration File

The CLI configuration is stored at `~/.dart_cloud/config.json`:

```json
{
  "authToken": "your-jwt-token",
  "serverUrl": "http://localhost:8080"
}
```

You can manually edit this file to change the server URL if needed.
