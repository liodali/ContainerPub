# Dart Cloud CLI

Command-line interface for deploying and managing Dart serverless functions.

## Overview

`dart_cloud_cli` is a powerful CLI tool that enables developers to:

- Deploy Dart cloud functions with a single command
- Validate function structure and security automatically
- Manage deployed functions (list, invoke, delete)
- View function logs and metrics
- Authenticate with the Dart Cloud platform using access and refresh tokens

## Installation

### From Source

```bash
cd dart_cloud_cli
dart pub get
dart pub global activate --source path .
```

Now you can use `dart_cloud` from anywhere.

## Quick Start

### 1. Login

```bash
dart_cloud login
```

You'll be prompted for your email and password. Upon successful login, you'll receive:

- **Access Token** - Short-lived token (1 hour) for API requests
- **Refresh Token** - Long-lived token (30 days) for obtaining new access tokens

Both tokens are securely stored in `~/.dart_cloud/config.json`.

### 2. Create a Function

```bash
mkdir my-function
cd my-function
dart create -t console-simple .
```

### 3. Initialize Function Config

```bash
dart_cloud init
```

This creates a `.dart_tool/function_config.json` file that stores your function metadata and ID for caching.

### 4. Add dart_cloud_function Dependency

Edit `pubspec.yaml`:

```yaml
dependencies:
  dart_cloud_function: ^1.0.0
```

### 5. Write Your Function

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

### 6. Deploy

```bash
dart_cloud deploy ./my-function
```

## Commands

### init

Initialize function configuration in the current directory.

```bash
dart_cloud init
```

Creates a `.dart_tool/function_config.json` file that stores:

- `function_name` - The project name from `pubspec.yaml`
- `function_id` - Cached after deployment (auto-populated)
- `created_at` - Timestamp of initialization

This file is used as a cache for function metadata, allowing you to:

- Update functions without specifying the ID
- Invoke functions locally using the cached ID
- Track function metadata in your project

**Output:**

```
✓ Successfully initialized function config
✓ Config file created at: .dart_tool/function_config.json
✓ Function name: my_function
```

### login

Authenticate with the Dart Cloud platform.

```bash
dart_cloud login
```

**Authentication Flow:**

1. Enter email and password
2. Backend validates credentials
3. Receives access token (1 hour expiry) and refresh token (30 days expiry)
4. Tokens stored securely in `~/.dart_cloud/config.json`

**Token Storage:**

```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "serverUrl": "http://localhost:8080"
}
```

### logout

Logout from the platform and invalidate tokens.

```bash
dart_cloud logout
```

**Logout Flow:**

1. Sends access token and refresh token to backend
2. Backend blacklists both tokens
3. Removes tokens from local storage
4. User must login again to access platform

### deploy

Deploy a Dart function from a directory.

```bash
dart_cloud deploy <path-to-function>
```

After successful deployment, the function ID is automatically cached in `.dart_tool/function_config.json` for future reference.

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

**Post-Deployment:**

- Function ID is stored in `.dart_tool/function_config.json`
- Can be used for subsequent updates or local invocations

### list

List all deployed functions.

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

### delete

Delete a deployed function.

```bash
dart_cloud delete <function-id>
```

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

## Authentication System

### Token Types

**Access Token:**

- Short-lived (1 hour)
- Used for API requests
- Automatically refreshed when expired
- Stored in `~/.dart_cloud/config.json`

**Refresh Token:**

- Long-lived (30 days)
- Used to obtain new access tokens
- Invalidated on logout
- Stored in `~/.dart_cloud/config.json`

### Token Refresh Flow

When an access token expires:

1. CLI detects 401 Unauthorized response
2. Automatically sends refresh token to `/api/auth/refresh`
3. Receives new access token
4. Retries original request with new token
5. Updates local token storage

### Security Features

- **Token Encryption** - Tokens stored with encryption at rest
- **Automatic Expiry** - Access tokens expire after 1 hour
- **Blacklisting** - Tokens invalidated on logout
- **Secure Storage** - Tokens stored in user home directory with restricted permissions

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

### Global CLI Configuration

The CLI configuration is stored at `~/.dart_cloud/config.json`:

```json
{
  "accessToken": "your-access-token",
  "refreshToken": "your-refresh-token",
  "serverUrl": "http://localhost:8080"
}
```

You can manually edit this file to change the server URL.

### Function Configuration

Each function directory contains a `.dart_tool/function_config.json` file:

```json
{
  "function_name": "my_function",
  "function_id": "abc123xyz789",
  "created_at": "2025-11-16T23:34:00.000Z"
}
```

This file is:

- **Created** by `dart_cloud init`
- **Updated** automatically after `dart_cloud deploy`
- **Used** for caching function metadata locally
- **Optional** but recommended for better developer experience

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

```bash
dart_cloud login
```

### Token Expired

The CLI automatically refreshes expired access tokens. If refresh fails, login again:

```bash
dart_cloud logout
dart_cloud login
```

### Deployment Size Exceeded

Remove unnecessary files:

```bash
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

## See Also

- [dart_cloud_function Package](./dart-cloud-function.md)
- [Backend API Reference](../backend/api-reference.md)
- [Backend Architecture](../backend/architecture.md)
