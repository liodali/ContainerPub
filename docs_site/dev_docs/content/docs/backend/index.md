---
title: Backend Documentation
description: Backend server architecture and API reference
---

# Backend Documentation

Welcome to the ContainerPub backend documentation. The backend provides a secure, scalable platform for hosting and executing Dart serverless functions.

## Overview

The `dart_cloud_backend` is the core platform that:

- **Hosts Functions** - Execute Dart functions in isolated containers
- **Manages Containers** - Podman-based container orchestration
- **Provides APIs** - RESTful HTTP endpoints for function management
- **Handles Authentication** - JWT-based dual-token authentication system
- **Stores Data** - PostgreSQL for metadata, Hive for tokens
- **Monitors Performance** - Metrics collection and logging

## Quick Links

### Core Documentation

- [Authentication System](./authentication.md) - Complete authentication flow and token management
- [API Keys & Signing](./api-keys.md) - Secure function invocations with HMAC signatures
- [Input Validation Middleware](./validation-middleware.md) - Schema-based request validation with Zard
- [Statistics & Monitoring](./statistics.md) - Dashboard metrics and performance tracking
- [Architecture Overview](./architecture.md) - System design and components
- [Function Execution](./function-execution.md) - How functions are executed
- [API Reference](./api-reference.md) - Complete API endpoint documentation

## Key Features

### Statistics & Monitoring

- **User Overview Stats** - Aggregated metrics across all user's functions
- **Per-Function Stats** - Detailed metrics for individual functions
- **Hourly Charts** - Request distribution by hour (up to 168 hours)
- **Daily Charts** - Request distribution by day (up to 90 days)
- **Real-time Metrics** - Invocation counts, success/error rates, latency tracking

### Authentication System

- **Dual Token Architecture** - Access tokens (1 hour) + refresh tokens (30 days)
- **Whitelist-Based Storage** - Tokens stored as SHA-256 hashes in user-specific whitelists
- **Multi-Session Support** - Multiple active sessions per user
- **Encrypted Storage** - Hive database with AES-256 encryption
- **Token Blacklisting** - Immediate token invalidation
- **Token Linking** - Track refresh token to access token relationships
- **Automatic Refresh** - Seamless token renewal with old token invalidation

### Container Management

- **Rootless Podman** - Secure container execution without root
- **Resource Isolation** - CPU, memory, and disk limits
- **Network Isolation** - Isolated container networks
- **Image Building** - Automatic function containerization

### Data Storage

- **PostgreSQL** - Function metadata, user data, execution history
- **Hive** - Encrypted token storage with fast lookups
- **File System** - Function archives and build artifacts

### Security

- **JWT Authentication** - Industry-standard token-based auth
- **API Key Signing** - HMAC-SHA256 signatures for function invocations
- **Token Encryption** - AES-256 encryption for stored tokens
- **Container Sandboxing** - Isolated execution environments
- **Replay Protection** - 5-minute timestamp window for signed requests
- **Audit Logging** - Complete request and authentication logging

## Architecture Overview

### System Components

```dart
┌─────────────────────────────────────────────┐
│    ContainerPub Backend Server              │
│  ┌──────────────────────────────────────┐  │
│  │  API Server (Shelf)                  │  │
│  │  - Function deployment               │  │
│  │  - Function execution                │  │
│  │  - JWT authentication                │  │
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │  Token Service (Hive)                │  │
│  │  - Encrypted token storage           │  │
│  │  - Token blacklist                   │  │
│  │  - Token linking                     │  │
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │  Container Runtime (Podman)          │  │
│  │  - Build images                      │  │
│  │  - Run containers                    │  │
│  │  - Manage resources                  │  │
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │  Database (PostgreSQL)               │  │
│  │  - Function metadata                 │  │
│  │  - User data                         │  │
│  │  - Execution history                 │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Authentication Architecture

### Token Types

**Access Token:**

- Lifetime: 1 hour
- Purpose: API request authorization
- Storage: Encrypted Hive database
- Payload: User ID, email, type='access'

**Refresh Token:**

- Lifetime: 30 days
- Purpose: Obtain new access tokens
- Storage: Encrypted Hive database
- Payload: User ID, email, type='refresh'

### Authentication Endpoints

- **POST /api/auth/register** - Create new user account
- **POST /api/auth/login** - Authenticate and receive tokens
- **POST /api/auth/refresh** - Get new access token
- **POST /api/auth/logout** - Invalidate all tokens

### Token Flow

```dart
Login → Access Token (1h) + Refresh Token (30d)
  ↓
API Requests → Validate Access Token
  ↓
Token Expired → Use Refresh Token → New Access Token
  ↓
Logout → Blacklist Both Tokens
```

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login and get tokens
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/logout` - Logout and invalidate tokens

### Functions

- `POST /api/functions/deploy` - Deploy function
- `GET /api/functions` - List functions
- `GET /api/functions/:id` - Get function details
- `DELETE /api/functions/:id` - Delete function

### Execution

- `POST /api/functions/:id/invoke` - Invoke function
- `GET /api/functions/:id/executions` - Get execution history

### Logs

- `GET /api/functions/:id/logs` - Get function logs

### Health

- `GET /health` - Server health check

## Token Service

### Storage Structure

**Hive Boxes (Whitelist Approach):**

| Box                | Key         | Value             | Description                             |
| ------------------ | ----------- | ----------------- | --------------------------------------- |
| `auth_tokens`      | userId      | List\<tokenHash\> | User's whitelist of valid access tokens |
| `blacklist_tokens` | tokenHash   | timestamp         | Invalidated tokens                      |
| `refresh_tokens`   | refreshHash | userId            | Refresh token to user mapping           |
| `token_links`      | refreshHash | accessHash        | Refresh to access token links           |

> **Note:** All tokens are hashed with SHA-256 before storage (64 chars vs 255+ char JWTs) to overcome Hive's key length limitations.

### Token Operations

```dart
// Add access token to user's whitelist
await TokenService.instance.addAuthToken(
  token: accessToken,
  userId: userId,
);

// Add refresh token with link to access token
await TokenService.instance.addRefreshToken(
  refreshToken: refreshToken,
  userId: userId,
  accessToken: accessToken,
);

// Validate token (async - checks whitelist)
final isValid = await TokenService.instance.isTokenValid(token, userId);

// Blacklist token and remove from whitelist
await TokenService.instance.blacklistToken(token, userId: userId);

// Refresh access token (blacklists old, links new)
await TokenService.instance.updateLinkedAccessToken(
  refreshToken: refreshToken,
  newAccessToken: newAccessToken,
  userId: userId,
);

// Logout from all devices
await TokenService.instance.removeAllUserTokens(userId);
```

### Security Features

- **Encryption**: HiveAesCipher with 256-bit key
- **Key Storage**: Secure key file in `data/key.txt`
- **Blacklisting**: Immediate token invalidation
- **Token Linking**: Track token relationships
- **Automatic Cleanup**: Old tokens can be purged

## Database Schema

### Users Table

```dart
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Functions Table

```dart
CREATE TABLE functions (
  id UUID PRIMARY KEY,
  name VARCHAR(255),
  owner_id UUID REFERENCES users(id),
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  status VARCHAR(50),
  metadata JSONB
);
```

### Executions Table

```dart
CREATE TABLE executions (
  id UUID PRIMARY KEY,
  function_id UUID REFERENCES functions(id),
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  status VARCHAR(50),
  logs TEXT,
  result JSONB
);
```

## Technology Stack

- **Language**: Dart 3.x
- **HTTP Server**: Shelf
- **Database**: PostgreSQL
- **Token Storage**: Hive with encryption
- **Container Runtime**: Podman (rootless)
- **Authentication**: JWT (dart_jsonwebtoken)
- **Encryption**: HiveAesCipher (256-bit AES)

## Security Model

### Container Security

- **Rootless Execution** - No root privileges required
- **User Namespaces** - Isolated user spaces per container
- **Resource Limits** - CPU, memory, disk constraints
- **Network Isolation** - Containers on isolated networks

### API Security

- **JWT Authentication** - Token-based auth
- **HTTPS** - Encrypted communications
- **Token Blacklisting** - Invalidate compromised tokens
- **Audit Logging** - Complete request logging

### Token Security

- **Encrypted Storage** - Tokens encrypted at rest
- **Short-lived Access** - 1 hour expiry
- **Refresh Rotation** - Old tokens blacklisted on refresh
- **Logout Invalidation** - Both tokens blacklisted
- **Secure Key Management** - Protected encryption key

## Performance

### Cold Start Optimization

- Optimized base images
- Minimal dependencies
- Fast container startup
- Cached image layers

### Warm Execution

- Container reuse
- Memory caching
- Connection pooling
- Optimized runtime

### Token Performance

- In-memory caching
- Fast Hive lookups
- Efficient blacklist checking
- JWT signature verification

## Monitoring

### Metrics

- Function execution time
- Memory usage
- CPU usage
- Error rates
- Request count
- Token operations

### Logging

- Function stdout/stderr
- API request logs
- Authentication events
- Token operations
- System events
- Audit trail

## Deployment

### Requirements

- Dart 3.x SDK
- PostgreSQL database
- Podman container runtime
- Linux/macOS (Podman support)

### Configuration

- Environment variables for database
- JWT secret configuration
- Token service initialization
- Container runtime setup

### Running

```dart
cd dart_cloud_backend
dart pub get
dart run bin/server.dart
```

## Development

### Project Structure

```dart
dart_cloud_backend/
├── bin/
│   └── server.dart          # Entry point
├── lib/
│   ├── router.dart          # Route definitions
│   ├── handlers/
│   │   └── auth_handler.dart # Auth endpoints
│   └── services/
│       └── token_service.dart # Token management
├── data/
│   ├── tokens/              # Hive database
│   └── key.txt              # Encryption key
└── pubspec.yaml
```

### Key Files

- **router.dart** - Route configuration
- **auth_handler.dart** - Authentication logic
- **token_service.dart** - Token storage and validation

## Next Steps

- Read [Statistics & Monitoring](./statistics.md) for dashboard metrics documentation
- Read [Authentication System](./authentication.md) for complete auth flow documentation
- Read [Architecture Overview](./architecture.md) for detailed system design
- Check [API Reference](./api-reference.md) for complete API documentation
- Explore [CLI Documentation](../cli/index.md) for client-side tools
- Review [Development Guide](../development.md) for contributing

## Support

For issues, questions, or contributions:

- GitHub: [liodali/ContainerPub](https://github.com/liodali/ContainerPub)
- Documentation: [ContainerPub Docs](/)
