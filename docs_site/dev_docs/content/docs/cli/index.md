---
title: CLI Documentation
description: Command-line interface for ContainerPub
---

# CLI Documentation

Welcome to the ContainerPub CLI documentation. The CLI provides a powerful command-line interface for deploying and managing Dart serverless functions.

## Overview

The `dart_cloud_cli` tool enables developers to:

- **Deploy Functions** - Upload and deploy Dart functions with a single command
- **Manage Functions** - List, invoke, and delete deployed functions
- **View Logs** - Monitor function execution and debugging
- **Authenticate** - Secure access with JWT-based authentication
- **Validate Code** - Pre-deployment security and structure checks

## Quick Links

### Getting Started

- [dart_cloud_cli](./dart-cloud-cli.md) - Complete CLI reference and usage guide
- [dart_cloud_function Package](./dart-cloud-function.md) - Function development package

## Key Features

### Authentication System

- **Dual Token System** - Access tokens (1 hour) and refresh tokens (30 days)
- **Automatic Refresh** - CLI automatically refreshes expired tokens
- **Secure Storage** - Encrypted token storage in user home directory
- **Easy Logout** - Invalidate all tokens with single command

### Function Deployment

- **One Command Deploy** - `dart_cloud deploy ./my-function`
- **Automatic Validation** - Size limits, forbidden files, security checks
- **Code Analysis** - Validates function structure and annotations
- **Function Caching** - Stores function metadata locally for quick updates

### Function Management

- **List Functions** - View all deployed functions
- **Invoke Functions** - Test functions with custom data
- **View Logs** - Real-time and historical logs
- **Delete Functions** - Remove functions when no longer needed

## Installation

```dart
cd dart_cloud_cli
dart pub get
dart pub global activate --source path .
```

## Quick Start

```dart
# Login to platform
dart_cloud login

# Initialize function config
dart_cloud init

# Deploy function
dart_cloud deploy ./my-function

# List functions
dart_cloud list

# View logs
dart_cloud logs <function-id>

# Logout
dart_cloud logout
```

## Documentation Structure

### CLI Tool

- **[dart_cloud_cli](./dart-cloud-cli.md)** - Complete CLI reference
  - Installation and setup
  - All commands and options
  - Authentication flow
  - Configuration files
  - Troubleshooting

### Function Package

- **[dart_cloud_function](./dart-cloud-function.md)** - Function development
  - Package overview
  - API reference
  - Usage examples
  - Best practices
  - Testing guide

## Authentication Flow

### Login

1. User provides email and password
2. Backend validates and returns access + refresh tokens
3. CLI stores tokens securely
4. Ready to deploy and manage functions

### Token Refresh

1. CLI detects expired access token
2. Automatically sends refresh token
3. Receives new access token
4. Retries original request
5. Seamless user experience

### Logout

1. CLI sends both tokens to backend
2. Backend blacklists both tokens
3. CLI removes local token storage
4. User must login again

## Security Features

- **Token Encryption** - Tokens encrypted at rest
- **Automatic Expiry** - Access tokens expire after 1 hour
- **Refresh Rotation** - Old access tokens invalidated on refresh
- **Secure Storage** - Tokens in protected user directory
- **Blacklist System** - Compromised tokens can be invalidated

## Validation & Security

### Pre-Deployment Checks

- **Size Limits** - Functions must be under 5 MB
- **Forbidden Files** - No secrets, keys, or credentials
- **Forbidden Directories** - No version control or build artifacts
- **Code Structure** - Exactly one CloudDartFunction class
- **Annotations** - @cloudFunction annotation required
- **Security** - No dangerous imports or process execution

### Code Analysis

- Static analysis of function code
- Security vulnerability detection
- Structure validation
- Best practice enforcement

## Configuration

### Global Config

Location: `~/.dart_cloud/config.json`

```dart
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "serverUrl": "http://localhost:8080"
}
```

### Function Config

Location: `.dart_tool/function_config.json`

```dart
{
  "function_name": "my_function",
  "function_id": "abc123xyz789",
  "created_at": "2025-11-16T23:34:00.000Z"
}
```

## Common Workflows

### Deploy New Function

```dart
mkdir my-function
cd my-function
dart create -t console-simple .
dart_cloud init
# Edit main.dart with your function
dart_cloud deploy .
```

### Update Existing Function

```dart
cd my-function
# Make changes to your function
dart_cloud deploy .
```

### Monitor Function

```dart
dart_cloud logs <function-id> --follow
```

### Delete Function

```dart
dart_cloud delete <function-id>
```

## Troubleshooting

### Authentication Issues

- Run `dart_cloud logout` then `dart_cloud login`
- Check server URL in config file
- Verify credentials

### Deployment Failures

- Check function size (must be < 5 MB)
- Remove forbidden files and directories
- Verify @cloudFunction annotation
- Check for security violations

### Token Expired

- CLI automatically refreshes tokens
- If refresh fails, login again
- Check refresh token hasn't expired (30 days)

## Next Steps

- Read [dart_cloud_cli Guide](./dart-cloud-cli.md) for detailed CLI usage
- Check [dart_cloud_function Package](./dart-cloud-function.md) for function development
- Explore [Backend API Reference](../backend/api-reference.md) for API details
- Review [Backend Architecture](../backend/architecture.md) for system design

## Support

For issues, questions, or contributions:

- GitHub: [liodali/ContainerPub](https://github.com/liodali/ContainerPub)
- Documentation: [ContainerPub Docs](/)
