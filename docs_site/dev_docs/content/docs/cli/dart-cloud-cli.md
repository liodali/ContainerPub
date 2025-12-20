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

You'll be prompted for your email and password. Upon successful login, you'll receive:

- **Access Token** - Short-lived token (1 hour) for API requests
- **Refresh Token** - Long-lived token (30 days) for obtaining new access tokens

Both tokens are securely stored in `~/.dart_cloud/config.json`.

### 2. Create a Function

```dart
mkdir my-function
cd my-function
dart create -t console-simple .
```

### 3. Initialize Function

```dart
dart_cloud init
```

This:

1. Validates function structure (pubspec.yaml, entry point)
2. Creates function on backend with status `init` and generates UUID
3. Stores UUID in `.dart_tool/function_config.json`
4. Returns the function UUID for deployment

You can also generate an API key during initialization:

```dart
# Generate API key valid for 1 day
dart_cloud init --apikey 1d

# Generate API key with forever validity
dart_cloud init --apikey

# Revoke existing key and generate new one
dart_cloud init --apikey 1w --revoke
```

### 4. Add dart_cloud_function Dependency

Edit `pubspec.yaml`:

```dart
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

```dart
dart_cloud deploy ./my-function
```

## Commands

### init

Initialize function configuration in the current directory.

```dart
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

```dart
dart_cloud login
```

**Authentication Flow:**

1. Enter email and password
2. Backend validates credentials
3. Receives access token (1 hour expiry) and refresh token (30 days expiry)
4. Tokens stored securely in `~/.dart_cloud/config.json`

**Token Storage:**

```dart
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "serverUrl": "http://localhost:8080"
}
```

### logout

Logout from the platform and invalidate tokens.

```dart
dart_cloud logout
```

**Logout Flow:**

1. Sends access token and refresh token to backend
2. Backend blacklists both tokens
3. Removes tokens from local storage
4. User must login again to access platform

### deploy

Deploy a Dart function from a directory.

```dart
dart_cloud deploy [--force|-f]
```

**Requirements:**

- Function must be initialized first (run `dart_cloud init`)
- Function directory must contain `pubspec.yaml`
- Function must have entry point (`main.dart` or `bin/main.dart`)

**Options:**

- `--force, -f` - Force deployment even if no changes detected

**What it does:**

1. Validates function is initialized (has UUID in config)
2. Validates function structure and code
3. Creates archive of function code
4. Uploads to backend with function UUID
5. Backend changes status from `init` → `building` → `active`

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

- Function deployment hash is stored in `.dart_tool/function_config.json`
- Deployment version is tracked for updates

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

### apikey

Manage API keys for function signing and secure invocation.

```dart
dart_cloud apikey <subcommand> [options]
```

**Subcommands:**

#### generate

Generate a new API key for a function.

```dart
dart_cloud apikey generate [--function-id <uuid>] [--validity <duration>] [--name <name>]
```

**Options:**

- `--function-id, -f` - Function UUID (uses current directory config if not provided)
- `--validity, -v` - Key validity: `1h`, `1d`, `1w`, `1m`, or `forever` (default: `1d`)
- `--name, -n` - Optional friendly name for the key

**Validity Options:**

- `1h` - 1 hour
- `1d` - 1 day (default)
- `1w` - 1 week
- `1m` - 1 month
- `forever` - Never expires

**Examples:**

```dart
dart_cloud apikey generate --validity 1d
dart_cloud apikey generate --function-id <uuid> --validity 1w --name "Production Key"
```

**What it does:**

1. Generates a public/private key pair
2. Stores public key on backend
3. Returns private key (only shown once!)
4. Stores private key in Hive database (`~/.containerpub/api_keys/`)
5. Updates function config with API key metadata

#### info

Get API key info for a function.

```dart
dart_cloud apikey info [--function-id <uuid>]
```

#### revoke

Revoke an API key.

```dart
dart_cloud apikey revoke [--key-id <uuid>] [--revoke]
```

#### list

List all API keys for a function.

```dart
dart_cloud apikey list [--function-id <uuid>]
```

#### roll

Extend an API key's expiration by its validity period.

```dart
dart_cloud apikey roll [--key-id <uuid>]
```

**Options:**

- `--key-id, -k` - API key UUID to roll (uses current directory config if not provided)

**What it does:**

1. Extends the API key's expiration by its validity period
2. For example, if validity is `1d`, it adds 1 day to the current expiration
3. Useful for extending active keys without regenerating them

**Examples:**

```dart
# Roll key from current directory config
dart_cloud apikey roll

# Roll specific key
dart_cloud apikey roll --key-id <api-key-uuid>
```

### invoke

Invoke a deployed function with optional data and optional signature.

```dart
dart_cloud invoke <function-id> [--data '{"key": "value"}'] [--sign]
```

**Options:**

- `--data` - JSON data to pass to the function
- `--sign` - Sign the request with stored API key

**With API Key Signature:**

If your function has an API key configured, use the `--sign` flag to sign the request:

```dart
dart_cloud invoke <function-id> --data '{"key": "value"}' --sign
```

This will:

1. Load the private key from Hive database
2. Create a timestamp and HMAC-SHA256 signature
3. Send request with `X-Signature` and `X-Timestamp` headers
4. Include `X-Signature` and `X-Timestamp` headers in the request

### apikey

Manage API keys for function signing. API keys provide an additional layer of security using HMAC-SHA256 signatures.

**Generate a new API key:**

```dart
# From function directory
dart_cloud apikey generate --validity 1d

# With custom name
dart_cloud apikey generate --validity 1w --name "Production Key"

# For specific function
dart_cloud apikey generate --function-id <uuid> --validity 1m
```

**Validity options:** `1h` (1 hour), `1d` (1 day), `1w` (1 week), `1m` (1 month), `forever`

**View API key info:**

```dart
dart_cloud apikey info
dart_cloud apikey info --function-id <uuid>
```

**List all keys:**

```dart
dart_cloud apikey list
dart_cloud apikey list --function-id <uuid>
```

**Roll an API key (extend expiration):**

```dart
dart_cloud apikey roll
dart_cloud apikey roll --key-id <api-key-uuid>
```

**Revoke an API key:**

```dart
dart_cloud apikey revoke
dart_cloud apikey revoke --key-id <api-key-uuid>
```

<Info>
The private key is only shown once when generated. It's automatically saved to `.dart_tool/api_key.secret` and added to `.gitignore`.
</Info>

See [API Keys & Signing](../backend/api-keys.md) for detailed documentation.

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

```dart
{
  "accessToken": "your-access-token",
  "refreshToken": "your-refresh-token",
  "serverUrl": "http://localhost:8080"
}
```

You can manually edit this file to change the server URL.

### Function Configuration

Each function directory contains a `.dart_tool/function_config.json` file:

```dart
{
  "function_name": "my_function",
  "function_id": "abc123xyz789",
  "created_at": "2025-11-16T23:34:00.000Z",
  "function_path": "/path/to/function",
  "last_deploy_hash": "abc123def456...",
  "last_deployed_at": "2025-12-15T02:00:00.000Z",
  "deploy_version": 3,
  "api_key_uuid": "key-uuid-if-configured",
  "api_key_public_key": "base64-public-key",
  "api_key_validity": "1d",
  "api_key_expires_at": "2025-12-16T02:00:00.000Z"
}
```

This file is:

- **Created** by `dart_cloud init`
- **Updated** automatically after `dart_cloud deploy` and `dart_cloud apikey generate`
- **Used** for caching function metadata locally
- **Optional** but recommended for better developer experience

### API Key Storage

When you generate an API key, the private key is stored separately:

- **Private Key**: `.dart_tool/api_key.secret` (auto-added to `.gitignore`)
- **Public Key Info**: Stored in `function_config.json`

<Warning>
Never commit `.dart_tool/api_key.secret` to version control. The CLI automatically adds it to `.gitignore`.
</Warning>

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

### Token Expired

The CLI automatically refreshes expired access tokens. If refresh fails, login again:

```dart
dart_cloud logout
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

## See Also

- [dart_cloud_function Package](./dart-cloud-function.md)
- [API Keys & Signing](../backend/api-keys.md)
- [Backend API Reference](../backend/api-reference.md)
- [Backend Architecture](../backend/architecture.md)
