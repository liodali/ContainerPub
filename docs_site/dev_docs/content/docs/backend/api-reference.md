---
title: API Reference
description: Backend API endpoints and authentication
---

# API Reference

Complete reference for ContainerPub backend API endpoints.

## Authentication

### POST /api/auth/register

Register a new user account.

**Request:**

```dart
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response:**

```dart
{
  "message": "Account created successfully"
}
```

**Notes:**

- Password must meet security requirements
- Email must be unique
- No tokens returned - user must login after registration

### POST /api/auth/login

Authenticate and receive access and refresh tokens.

**Request:**

```dart
{
  "email": "user@example.com",
  "password": "password"
}
```

**Response:**

```dart
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc..."
}
```

**Token Details:**

- **Access Token**: Short-lived (1 hour), used for API requests
- **Refresh Token**: Long-lived (30 days), used to obtain new access tokens

**Authentication Flow:**

1. User provides email and password
2. Backend validates credentials against database
3. Generates access token (1 hour expiry) with user info
4. Generates refresh token (30 days expiry) with user info
5. Stores both tokens in encrypted Hive database
6. Links refresh token to access token for tracking
7. Returns both tokens to client

### POST /api/auth/refresh

Refresh an expired access token using a refresh token.

**Request:**

```dart
{
  "refreshToken": "eyJhbGc..."
}
```

**Response:**

```dart
{
  "accessToken": "eyJhbGc..."
}
```

**Refresh Flow:**

1. Client sends refresh token
2. Backend verifies refresh token signature and expiry
3. Checks if refresh token is valid in storage (not blacklisted)
4. Generates new access token (1 hour expiry)
5. Blacklists old access token
6. Updates link between refresh token and new access token
7. Returns new access token

**Error Responses:**

- `400` - Refresh token missing
- `403` - Invalid token type or expired/blacklisted token
- `500` - Token refresh failed

### POST /api/auth/logout

Logout and invalidate tokens.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Request:**

```dart
{
  "refreshToken": "eyJhbGc..."
}
```

**Response:**

```dart
{
  "message": "Logout successful"
}
```

**Logout Flow:**

1. Client sends access token (in header) and refresh token (in body)
2. Backend validates access token
3. Blacklists access token
4. Blacklists refresh token
5. Removes refresh token from storage
6. Removes token link
7. User must login again to access platform

**Notes:**

- Both access and refresh tokens are required
- Tokens are permanently invalidated
- Cannot be undone

## API Keys

API keys provide an additional layer of security for function invocations using HMAC-SHA256 signatures.

<Info>
For detailed documentation on API keys, see [API Keys & Signing](./api-keys.md).
</Info>

### POST /api/auth/apikey/generate

Generate a new API key for a function.

**Headers:**

```dart
Authorization: Bearer <access-token>
Content-Type: application/json
```

**Request:**

```dart
{
  "function_id": "function-uuid",
  "validity": "1d",  // Options: 1h, 1d, 1w, 1m, forever
  "name": "Optional key name"
}
```

**Response:**

```dart
{
  "message": "API key generated successfully",
  "warning": "Store the private_key securely - it will not be shown again!",
  "api_key": {
    "uuid": "key-uuid",
    "public_key": "base64-public-key",
    "private_key": "base64-private-key",
    "validity": "1d",
    "expires_at": "2025-12-16T02:00:00Z",
    "created_at": "2025-12-15T02:00:00Z"
  }
}
```

### GET /api/auth/apikey/:function_id

Get API key info for a function.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Response:**

```dart
{
  "has_api_key": true,
  "api_key": {
    "uuid": "key-uuid",
    "public_key": "base64-public-key",
    "validity": "1d",
    "is_active": true,
    "expires_at": "2025-12-16T02:00:00Z"
  }
}
```

### DELETE /api/auth/apikey/:api_key_uuid/revoke

Revoke an API key (deactivate but keep in history).

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Response:**

```dart
{
  "message": "API key revoked successfully"
}
```

**What it does:**

- Marks the API key as inactive
- Records the revocation timestamp
- Key remains in database for audit history
- Cannot be reactivated

### DELETE /api/auth/apikey/:api_key_uuid

Delete an API key (remove from database).

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Response:**

```dart
{
  "message": "API key revoked successfully"
}
```

**What it does:**

- Permanently removes the API key from the database
- No audit trail remains
- Cannot be recovered

### GET /api/auth/apikey/:function_id/list

List all API keys for a function.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Response:**

```dart
{
  "api_keys": [
    {
      "uuid": "key-uuid",
      "validity": "1d",
      "is_active": true,
      "expires_at": "2025-12-16T02:00:00Z"
    }
  ]
}
```

### PUT /api/auth/apikey/:api_key_uuid/roll

Extend an API key's expiration by its validity period.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Response:**

```dart
{
  "message": "API key updated successfully"
}
```

**What it does:**

- Extends the expiration date by the key's validity period
- For example, if validity is `1d`, it adds 1 day to the current expiration
- Useful for extending active keys without regenerating them
- Does not change the key UUID or secret

## Token Security

### Token Storage

- **Backend**: Tokens stored in encrypted Hive database
- **Encryption**: HiveAesCipher with generated secure key
- **Key Storage**: Encryption key stored in `data/key.txt`
- **Blacklist**: Separate box for invalidated tokens

### Token Validation

```dart
// Check if access token is valid
bool isValid = TokenService.instance.isTokenValid(token);

// Check if refresh token is valid
bool isRefreshValid = TokenService.instance.isRefreshTokenValid(refreshToken);
```

### Token Linking

- Each refresh token is linked to its current access token
- When access token is refreshed, old token is blacklisted
- Link is updated to point to new access token
- Prevents reuse of old access tokens

## Functions API

### POST /api/functions/deploy

Deploy a new function or update existing one.

**Headers:**

```dart
Authorization: Bearer <access-token>
Content-Type: multipart/form-data
```

**Form Data:**

- `name` - Function name
- `archive` - Function archive (tar.gz)
- `env` - Environment variables (JSON)

**Response:**

```dart
{
  "id": "function-id",
  "name": "my-function",
  "status": "deployed",
  "url": "https://api.containerpub.dev/functions/function-id"
}
```

### GET /api/functions

List all deployed functions for authenticated user.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Query Parameters:**

- `limit` - Number of results (default: 10)
- `offset` - Pagination offset (default: 0)

**Response:**

```dart
{
  "functions": [
    {
      "id": "function-id",
      "name": "my-function",
      "status": "active",
      "created_at": "2025-01-01T00:00:00Z"
    }
  ],
  "total": 1
}
```

### GET /api/functions/:id

Get function details.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Response:**

```dart
{
  "id": "function-id",
  "name": "my-function",
  "status": "active",
  "memory": 512,
  "timeout": 30,
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

### DELETE /api/functions/:id

Delete a function.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Response:**

```dart
{
  "message": "Function deleted successfully"
}
```

## Function Execution

### POST /api/functions/:id/invoke

Invoke a deployed function.

**Headers:**

```dart
Authorization: Bearer <access-token>
Content-Type: application/json
```

**Request:**

```dart
{
  "body": {
    "key": "value"
  }
}
```

**Response:**

```dart
{
  "execution_id": "exec-id",
  "status": "success",
  "result": {
    "output": "result"
  },
  "duration_ms": 150
}
```

### GET /api/functions/:id/executions

Get execution history for a function.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Query Parameters:**

- `limit` - Number of results (default: 10)
- `offset` - Pagination offset (default: 0)

**Response:**

```dart
{
  "executions": [
    {
      "id": "exec-id",
      "status": "success",
      "started_at": "2025-01-01T00:00:00Z",
      "completed_at": "2025-01-01T00:00:05Z",
      "duration_ms": 150
    }
  ],
  "total": 1
}
```

## Logs API

### GET /api/functions/:id/logs

Get function execution logs.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Query Parameters:**

- `limit` - Number of lines (default: 100)
- `since` - Timestamp filter (ISO 8601)

**Response:**

```dart
{
  "logs": [
    {
      "timestamp": "2025-01-01T00:00:00Z",
      "level": "info",
      "message": "Function started"
    }
  ]
}
```

## Error Responses

### 400 Bad Request

```dart
{
  "error": "Invalid request",
  "details": "Missing required field: name"
}
```

### 401 Unauthorized

```dart
{
  "error": "Unauthorized",
  "details": "Invalid or expired token"
}
```

**Common Causes:**

- Missing Authorization header
- Invalid access token
- Expired access token (use refresh token to get new one)

### 403 Forbidden

```dart
{
  "error": "Forbidden",
  "details": "Access denied"
}
```

### 404 Not Found

```dart
{
  "error": "Not found",
  "details": "Function not found"
}
```

### 500 Internal Server Error

```dart
{
  "error": "Internal server error",
  "details": "An unexpected error occurred"
}
```

## Rate Limiting

- **Requests per minute**: 60
- **Requests per hour**: 1000
- **Concurrent executions**: 10 per function

## Statistics API

### GET /api/stats/overview

Get aggregated statistics for all user's functions.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Query Parameters:**

- `period` - Time period: `1h`, `24h`, `7d`, `30d` (default: `24h`)

**Response:**

```dart
{
  "total_functions": 5,
  "invocations_count": 1250,
  "success_count": 1245,
  "error_count": 5,
  "average_latency_ms": 120,
  "period": "24h"
}
```

### GET /api/stats/overview/hourly

Get hourly chart data for all user's functions.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Query Parameters:**

- `hours` - Number of hours (default: 24, max: 168)

**Response:**

```dart
{
  "data": [
    {
      "hour": "2024-01-15T10:00:00Z",
      "total_requests": 150,
      "success_count": 148,
      "error_count": 2,
      "average_latency_ms": 120
    }
  ],
  "hours": 24
}
```

### GET /api/stats/overview/daily

Get daily chart data for all user's functions.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Query Parameters:**

- `days` - Number of days (default: 30, max: 90)

**Response:**

```dart
{
  "data": [
    {
      "day": "2024-01-15T00:00:00Z",
      "total_requests": 1500,
      "success_count": 1495,
      "error_count": 5,
      "average_latency_ms": 115
    }
  ],
  "days": 30
}
```

### GET /api/functions/:uuid/stats

Get statistics for a specific function.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Query Parameters:**

- `period` - Time period: `1h`, `24h`, `7d`, `30d` (default: `24h`)

**Response:**

```dart
{
  "invocations_count": 250,
  "success_count": 248,
  "error_count": 2,
  "average_latency_ms": 125,
  "period": "24h"
}
```

### GET /api/functions/:uuid/stats/hourly

Get hourly chart data for a specific function.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Query Parameters:**

- `hours` - Number of hours (default: 24, max: 168)

**Response:**

```dart
{
  "data": [
    {
      "hour": "2024-01-15T10:00:00Z",
      "total_requests": 25,
      "success_count": 24,
      "error_count": 1,
      "average_latency_ms": 125
    }
  ],
  "hours": 24
}
```

### GET /api/functions/:uuid/stats/daily

Get daily chart data for a specific function.

**Headers:**

```dart
Authorization: Bearer <access-token>
```

**Query Parameters:**

- `days` - Number of days (default: 30, max: 90)

**Response:**

```dart
{
  "data": [
    {
      "day": "2024-01-15T00:00:00Z",
      "total_requests": 250,
      "success_count": 248,
      "error_count": 2,
      "average_latency_ms": 125
    }
  ],
  "days": 30
}
```

<Info>
For detailed documentation on statistics and monitoring, see [Statistics & Monitoring](./statistics.md).
</Info>

## Health Check

### GET /health

Check backend server health.

**Response:**

```dart
{
  "status": "ok",
  "timestamp": "2025-01-01T00:00:00Z"
}
```

**No authentication required.**

## Next Steps

- Read [Statistics & Monitoring](./statistics.md) for dashboard metrics documentation
- Read [Architecture Overview](./architecture.md)
- Check [CLI Documentation](../cli/dart-cloud-cli.md)
- Explore [Development Guide](../development.md)
