---
title: Architecture Overview
description: Understand the ContainerPub backend architecture
---

# Architecture Overview

ContainerPub backend is built on a modern, scalable architecture designed for security and performance.

## System Components

### 1. API Server (Shelf)

The HTTP server built with Dart Shelf framework:

- **Function Deployment** - Upload and deploy functions
- **Function Execution** - Execute functions in containers
- **Metrics Collection** - Track performance and usage
- **Authentication** - JWT-based auth with access and refresh tokens
- **User Management** - User registration and profile management

### 2. Container Runtime (Podman)

Rootless container management:

- **Build Images** - Create function container images
- **Run Containers** - Execute functions in isolated environments
- **Manage Resources** - CPU, memory, and disk limits
- **Network Isolation** - Isolated container networks

### 3. Database (PostgreSQL)

Persistent data storage:

- **Function Metadata** - Function definitions and configurations
- **User Data** - User accounts and profiles
- **Execution History** - Function invocation logs
- **Metrics** - Performance and usage statistics

### 4. Token Service (Hive)

Encrypted token storage and management:

- **Token Storage** - Encrypted access and refresh tokens
- **Token Blacklist** - Invalidated tokens
- **Token Linking** - Refresh token to access token mapping
- **Secure Key Management** - Encryption key storage

## Architecture Diagram

```
┌─────────────────────────────────────────────┐
│         Developer Machine                   │
│  ┌──────────────────────────────────────┐  │
│  │    dart_cloud CLI Tool               │  │
│  │  - Deploy functions                  │  │
│  │  - Manage lifecycle                  │  │
│  │  - View logs                         │  │
│  └──────────────────────────────────────┘  │
└──────────────┬──────────────────────────────┘
               │ HTTP/REST API
               │ JWT Authentication
               ▼
┌─────────────────────────────────────────────┐
│    ContainerPub Backend Server              │
│  ┌──────────────────────────────────────┐  │
│  │  API Server (Shelf)                  │  │
│  │  - Function deployment               │  │
│  │  - Function execution                │  │
│  │  - Metrics collection                │  │
│  │  - JWT authentication                │  │
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │  Token Service (Hive)                │  │
│  │  - Encrypted token storage           │  │
│  │  - Token blacklist                   │  │
│  │  - Token linking                     │  │
│  │  - Refresh token management          │  │
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

### Token-Based Authentication

ContainerPub uses a dual-token authentication system:

**Access Token:**

- Short-lived (1 hour)
- Used for API requests
- Contains user ID and email
- Stored in encrypted Hive database
- Blacklisted on logout or refresh

**Refresh Token:**

- Long-lived (30 days)
- Used to obtain new access tokens
- Contains user ID and email
- Linked to current access token
- Blacklisted on logout

### Authentication Flow

```
┌──────────┐                ┌──────────┐
│  Client  │                │  Backend │
└────┬─────┘                └────┬─────┘
     │                           │
     │  POST /api/auth/login     │
     │  {email, password}        │
     ├──────────────────────────>│
     │                           │
     │                           │ Validate credentials
     │                           │ Generate access token (1h)
     │                           │ Generate refresh token (30d)
     │                           │ Store tokens in Hive
     │                           │ Link tokens
     │                           │
     │  {accessToken,            │
     │   refreshToken}           │
     │<──────────────────────────┤
     │                           │
     │  API Request              │
     │  Authorization: Bearer    │
     │  <accessToken>            │
     ├──────────────────────────>│
     │                           │
     │                           │ Validate token
     │                           │ Check not blacklisted
     │                           │
     │  Response                 │
     │<──────────────────────────┤
     │                           │
```

### Token Refresh Flow

```
┌──────────┐                ┌──────────┐
│  Client  │                │  Backend │
└────┬─────┘                └────┬─────┘
     │                           │
     │  API Request              │
     │  (expired access token)   │
     ├──────────────────────────>│
     │                           │
     │  401 Unauthorized         │
     │<──────────────────────────┤
     │                           │
     │  POST /api/auth/refresh   │
     │  {refreshToken}           │
     ├──────────────────────────>│
     │                           │
     │                           │ Verify refresh token
     │                           │ Check not blacklisted
     │                           │ Generate new access token
     │                           │ Blacklist old access token
     │                           │ Update token link
     │                           │
     │  {accessToken}            │
     │<──────────────────────────┤
     │                           │
     │  Retry API Request        │
     │  (new access token)       │
     ├──────────────────────────>│
     │                           │
     │  Response                 │
     │<──────────────────────────┤
     │                           │
```

### Logout Flow

```
┌──────────┐                ┌──────────┐
│  Client  │                │  Backend │
└────┬─────┘                └────┬─────┘
     │                           │
     │  POST /api/auth/logout    │
     │  Authorization: Bearer    │
     │  <accessToken>            │
     │  {refreshToken}           │
     ├──────────────────────────>│
     │                           │
     │                           │ Validate access token
     │                           │ Blacklist access token
     │                           │ Blacklist refresh token
     │                           │ Remove refresh token
     │                           │ Remove token link
     │                           │
     │  {message: "Logout        │
     │   successful"}            │
     │<──────────────────────────┤
     │                           │
```

## Token Storage Architecture

### Hive Database Structure

**auth_tokens Box:**

```dart
{
  "token_string": "user_id",
  // Maps access tokens to user IDs
}
```

**blacklist_tokens Box:**

```dart
{
  "token_string": "timestamp",
  // Stores invalidated tokens with blacklist time
}
```

**refresh_tokens Box:**

```dart
{
  "refresh_token_string": "user_id",
  // Maps refresh tokens to user IDs
}
```

**token_links Box:**

```dart
{
  "refresh_token_string": "access_token_string",
  // Links refresh tokens to their current access token
}
```

### Encryption

- **Cipher**: HiveAesCipher with 256-bit key
- **Key Generation**: Secure random key generation
- **Key Storage**: `data/key.txt` (base64 encoded)
- **Encrypted Boxes**: auth_tokens, refresh_tokens, token_links
- **Unencrypted Boxes**: blacklist_tokens (for performance)

## Deployment Flow

### 1. Function Upload

```
Developer → CLI → API Server → Storage
```

### 2. Image Building

```
Storage → Extract → Build Image → Podman Registry
```

### 3. Function Execution

```
API Request → Scheduler → Podman Container → Response
```

### 4. Monitoring

```
Container → Metrics Collector → Database → Dashboard
```

## Technology Stack

### Backend

- **Language**: Dart 3.x
- **Framework**: Shelf (HTTP server)
- **Database**: PostgreSQL
- **Token Storage**: Hive with encryption
- **Container Runtime**: Podman
- **Storage**: File system / Object storage

### Security

- **Authentication**: JWT (dart_jsonwebtoken)
- **Encryption**: HiveAesCipher (256-bit)
- **Container Isolation**: Podman rootless
- **Token Management**: Blacklist + expiry

## Security Architecture

### Container Isolation

- **Rootless Containers** - Podman runs without root
- **User Namespaces** - Each container in isolated namespace
- **Resource Limits** - CPU, memory, disk constraints
- **Network Isolation** - Containers on isolated networks

### API Security

- **Authentication** - JWT-based with dual tokens
- **Authorization** - User-based access control
- **Encryption** - HTTPS for all communications
- **Token Blacklisting** - Invalidate compromised tokens
- **Audit Logging** - Complete request logging

### Token Security

- **Encrypted Storage** - Tokens encrypted at rest
- **Short-lived Access** - 1 hour expiry
- **Refresh Rotation** - Old access tokens blacklisted on refresh
- **Logout Invalidation** - Both tokens blacklisted
- **Secure Key Storage** - Encryption key in protected file

### Function Security

- **Client-side Analysis** - Pre-deployment security checks
- **Sandboxing** - Functions run in isolated containers
- **Environment Isolation** - Secrets via environment variables
- **Resource Limits** - Prevent resource exhaustion

## Scaling Architecture

### Horizontal Scaling

- Multiple backend instances
- Load balancer distribution
- Shared database
- Distributed token storage

### Vertical Scaling

- Resource allocation per function
- Dynamic resource adjustment
- Container resource limits
- Memory and CPU management

## Database Schema

### Users Table

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Functions Table

```sql
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

```sql
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

## Performance Considerations

### Cold Start

- Optimized base images
- Minimal dependencies
- Fast container startup
- Cached layers

### Warm Execution

- Container reuse
- Memory caching
- Connection pooling
- Optimized runtime

### Token Validation

- In-memory token cache
- Fast Hive lookups
- Blacklist checking
- JWT signature verification

## Monitoring & Observability

### Metrics Collected

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

### Alerting

- Performance degradation
- Error thresholds
- Resource exhaustion
- Security events
- Token abuse

## Future Enhancements

- **Kubernetes Integration** - Deploy on K8s
- **Multi-region** - Global function distribution
- **Advanced Scheduling** - Intelligent placement
- **Custom Runtimes** - Support other languages
- **Serverless Workflows** - Function orchestration
- **Token Rotation** - Automatic refresh token rotation
- **Redis Cache** - Distributed token cache

## Next Steps

- Read [API Reference](./api-reference.md)
- Check [CLI Documentation](../cli/dart-cloud-cli.md)
- Explore [Development Guide](../development.md)
