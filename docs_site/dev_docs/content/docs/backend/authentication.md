---
title: Authentication System
description: Complete authentication flow documentation for ContainerPub backend
---

# Authentication System

ContainerPub uses a dual-token JWT authentication system with a whitelist-based token storage approach for secure and scalable user authentication.

## Overview

The authentication system provides:

- **Dual Token Architecture** - Access tokens (1 hour) + Refresh tokens (30 days)
- **Whitelist-Based Storage** - Tokens stored as hashes in user-specific whitelists
- **SHA-256 Hashing** - Tokens hashed before storage (64 chars vs 255+ char JWTs)
- **Encrypted Storage** - Hive database with AES-256 encryption
- **Token Blacklisting** - Immediate token invalidation
- **Multi-Session Support** - Multiple active sessions per user

## Token Architecture

### Access Token

- **Lifetime**: 1 hour
- **Purpose**: API request authorization
- **Storage**: SHA-256 hash in user's whitelist
- **Payload**: `userId`, `email`, `type='access'`

### Refresh Token

- **Lifetime**: 30 days
- **Purpose**: Obtain new access tokens
- **Storage**: SHA-256 hash with user ID mapping
- **Payload**: `userId`, `email`, `type='refresh'`

## Storage Architecture

### Hive Boxes

The token service uses four encrypted Hive boxes:

| Box                | Key         | Value             | Description                             |
| ------------------ | ----------- | ----------------- | --------------------------------------- |
| `auth_tokens`      | userId      | List\<tokenHash\> | User's whitelist of valid access tokens |
| `blacklist_tokens` | tokenHash   | timestamp         | Invalidated tokens                      |
| `refresh_tokens`   | refreshHash | userId            | Refresh token to user mapping           |
| `token_links`      | refreshHash | accessHash        | Refresh to access token links           |

### Why Whitelist Approach?

JWT tokens exceed Hive's 255-character key limit. The whitelist approach:

1. **Hashes tokens** - SHA-256 produces 64-character hashes
2. **Uses userId as key** - Short, predictable key length
3. **Stores token list** - Supports multiple active sessions
4. **Enables fast lookup** - O(n) where n = user's active sessions

## Authentication Flow

### Registration

```dart
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response:**

```dart
{
  "message": "Account created successfully"
}
```

**Flow:**

1. Validate email and password
2. Hash password with BCrypt
3. Insert user into PostgreSQL
4. Return success message

### Login

```dart
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "base64EncodedPassword"
}
```

**Response:**

```dart
{
  "accessToken": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Flow:**

1. Validate credentials against PostgreSQL
2. Generate access token (HS512, 1 hour)
3. Generate refresh token (HS256, 30 days)
4. Hash both tokens with SHA-256
5. Add access token hash to user's whitelist
6. Store refresh token hash with user mapping
7. Link refresh hash to access hash
8. Return both tokens

### Token Validation (Middleware)

```dart
// Request with Authorization header
GET /api/functions
Authorization: Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9...
```

**Flow:**

1. Extract token from `Authorization: Bearer <token>`
2. Verify JWT signature with secret
3. Extract `userId` from JWT payload
4. Hash token with SHA-256
5. Check if hash exists in user's whitelist
6. Check if hash is NOT in blacklist
7. Allow or deny request

### Token Refresh

```dart
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**

```dart
{
  "accessToken": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9..."
}
```

**Flow:**

1. Verify refresh token JWT signature
2. Validate token type is 'refresh'
3. Check refresh token hash is valid (exists and not blacklisted)
4. Generate new access token
5. Hash new access token
6. Add new hash to user's whitelist
7. Blacklist old access token hash
8. Remove old hash from user's whitelist
9. Update token link with new access hash
10. Return new access token

### Logout

```dart
POST /api/auth/logout
Authorization: Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**

```dart
{
  "message": "Logout successful"
}
```

**Flow:**

1. Extract access token from header
2. Extract refresh token from body
3. Verify access token to get userId
4. Hash access token, add to blacklist
5. Remove access hash from user's whitelist
6. Hash refresh token, add to blacklist
7. Remove refresh token from storage
8. Remove token link

## Token Service API

### Adding Tokens

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
```

### Validating Tokens

```dart
// Check if access token is valid (async)
final isValid = await TokenService.instance.isTokenValid(
  token,
  userId,
);

// Check if refresh token is valid (sync)
final isRefreshValid = TokenService.instance.isRefreshTokenValid(
  refreshToken,
);

// Check if token is blacklisted (sync)
final isBlacklisted = TokenService.instance.isTokenBlacklisted(token);
```

### Invalidating Tokens

```dart
// Blacklist access token and remove from whitelist
await TokenService.instance.blacklistToken(
  token,
  userId: userId,
);

// Blacklist refresh token
await TokenService.instance.blacklistRefreshToken(refreshToken);

// Remove all tokens for a user (logout from all devices)
await TokenService.instance.removeAllUserTokens(userId);
```

### Refreshing Tokens

```dart
// Update linked access token (blacklists old, links new)
await TokenService.instance.updateLinkedAccessToken(
  refreshToken: refreshToken,
  newAccessToken: newAccessToken,
  userId: userId,
);
```

## Security Features

### Token Hashing

All tokens are hashed using SHA-256 before storage:

```dart
String _hashToken(String token) {
  final bytes = utf8.encode(token);
  final digest = sha256.convert(bytes);
  return digest.toString(); // 64 characters
}
```

**Benefits:**

- Tokens never stored in plain text
- Fixed 64-character hash length
- One-way transformation (cannot recover token)
- Fast computation

### Encrypted Storage

Hive boxes use AES-256 encryption:

```dart
final cipher = HiveAesCipher(key); // 256-bit key
await Hive.openLazyBox<List<dynamic>>(
  'auth_tokens',
  encryptionCipher: cipher,
);
```

**Key Management:**

- Key stored in `data/key.txt`
- Auto-generated on first run
- Base64 encoded for storage

### Blacklist Checking

Blacklist is checked before whitelist:

```dart
Future<bool> isTokenValid(String token, String userId) async {
  final tokenHash = _hashToken(token);

  // Check blacklist first (fast rejection)
  if (_blacklistBox.containsKey(tokenHash)) {
    return false;
  }

  // Check whitelist
  final existingTokens = await _authTokenBox.get(userId);
  if (existingTokens == null) return false;

  return existingTokens.cast<String>().contains(tokenHash);
}
```

### Multi-Session Support

Each user can have multiple active sessions:

```dart
// User's whitelist: ["hash1", "hash2", "hash3"]
// Each hash represents an active session/device
```

**Session Management:**

- Login adds new hash to list
- Logout removes specific hash
- `removeAllUserTokens()` clears all sessions

## JWT Configuration

### Access Token

```dart
final accessJwt = JWT({
  'userId': userId,
  'email': email,
  'type': 'access',
});
final accessToken = accessJwt.sign(
  SecretKey(Config.jwtSecret),
  algorithm: JWTAlgorithm.HS512,
  expiresIn: Duration(hours: 1),
);
```

### Refresh Token

```dart
final refreshJwt = JWT({
  'userId': userId,
  'email': email,
  'type': 'refresh',
});
final refreshToken = refreshJwt.sign(
  SecretKey(Config.jwtSecret),
  expiresIn: Duration(days: 30),
);
```

## Middleware Integration

The auth middleware validates tokens on protected routes:

```dart
Middleware get authMiddleware {
  return (Handler handler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.forbidden(
          jsonEncode({'error': 'Missing or invalid authorization header'}),
        );
      }

      final token = authHeader.substring(7);

      try {
        final jwt = JWT.verify(token, SecretKey(Config.jwtSecret));
        final userId = jwt.payload['userId'] as String;

        // Validate against whitelist
        final isValid = await TokenService.instance.isTokenValid(token, userId);
        if (!isValid) {
          return Response.forbidden(
            jsonEncode({'error': 'Invalid or expired token'}),
          );
        }

        // Add userId to request context
        return await handler(request.change(context: {'userId': userId}));
      } catch (e) {
        return Response.forbidden(
          jsonEncode({'error': 'Invalid or expired token'}),
        );
      }
    };
  };
}
```

## Error Handling

### Common Errors

| Error                        | Status | Cause                       |
| ---------------------------- | ------ | --------------------------- |
| Missing authorization header | 403    | No `Authorization` header   |
| Invalid token format         | 403    | Not `Bearer <token>` format |
| Token expired                | 403    | JWT expiry exceeded         |
| Token blacklisted            | 403    | Token in blacklist          |
| Token not in whitelist       | 403    | Token hash not found        |
| Invalid credentials          | 403    | Wrong email/password        |

### Error Responses

```dart
{
  "error": "Invalid or expired token"
}
```

## Development Setup

### Dependencies

```dart
dependencies:
  dart_jsonwebtoken: ^3.3.1
  hive_ce: ^2.15.1
  crypto: ^3.0.6
  bcrypt: ^1.1.3
```

### Initialization

```dart
// In server startup
await TokenService.instance.initialize();
```

### Configuration

```dart
// Environment variables
JWT_SECRET=your-secret-key-here
```

## Best Practices

### Token Handling

1. **Never log tokens** - Use hashes for debugging
2. **Short access token lifetime** - 1 hour maximum
3. **Rotate refresh tokens** - Consider rotation on each use
4. **Secure transmission** - Always use HTTPS

### Storage

1. **Encrypt at rest** - Use HiveAesCipher
2. **Protect encryption key** - Secure `key.txt` file
3. **Regular cleanup** - Purge old blacklist entries
4. **Backup tokens** - Include in disaster recovery

### Security

1. **Validate on every request** - Use middleware
2. **Check blacklist first** - Fast rejection
3. **Log authentication events** - Audit trail
4. **Rate limit auth endpoints** - Prevent brute force

## Next Steps

- [API Reference](./api-reference) - Complete endpoint documentation
- [Architecture Overview](./architecture) - System design details
- [CLI Authentication](../cli/dart-cloud-cli) - Client-side token handling
