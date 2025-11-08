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

**Security Analysis:**
Before deployment, the CLI performs local static analysis:
- Validates `@function` annotation is present
- Scans for risky code patterns (Process execution, shell access, etc.)
- Checks for dangerous imports (dart:mirrors, dart:ffi)
- Validates function signature
- Displays warnings and errors

Only functions that pass analysis are uploaded to the server.

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

3. Write your function in `bin/main.dart`:
```dart
import 'dart:convert';
import 'dart:io';

void main() {
  // Read input from environment variable
  final inputJson = Platform.environment['FUNCTION_INPUT'] ?? '{}';
  final input = jsonDecode(inputJson) as Map<String, dynamic>;
  
  // Your function logic
  final result = {
    'message': 'Hello, ${input['name'] ?? 'World'}!',
    'timestamp': DateTime.now().toIso8601String(),
  };
  
  // Output result as JSON
  print(jsonEncode(result));
}
```

4. Deploy your function:
```bash
cd ..
dart_cloud deploy ./my-function
```

## Examples

### Simple Hello World Function

```dart
import 'dart:convert';
import 'dart:io';

void main() {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  print(jsonEncode({'message': 'Hello, ${input['name'] ?? 'World'}!'}));
}
```

### Data Processing Function

```dart
import 'dart:convert';
import 'dart:io';

void main() {
  final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
  final numbers = (input['numbers'] as List?)?.cast<num>() ?? [];
  
  final result = {
    'sum': numbers.fold(0, (a, b) => a + b),
    'average': numbers.isEmpty ? 0 : numbers.reduce((a, b) => a + b) / numbers.length,
    'count': numbers.length,
  };
  
  print(jsonEncode(result));
}
```

## Troubleshooting

### Authentication Issues
If you're having authentication issues, try logging in again:
```bash
dart_cloud login
```

### Deployment Failures
- Ensure your function directory contains a valid `pubspec.yaml`
- Check that you're authenticated
- Verify the server is running
- **Analysis errors**: Fix security issues reported by the CLI analyzer
  - Add `@function` annotation if missing
  - Remove dangerous operations (Process.run, Shell, etc.)
  - Avoid restricted imports (dart:mirrors, dart:ffi)

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
