---
title: API Keys & Function Signing
description: Secure your functions with API key authentication and request signing
---

# API Keys & Function Signing

ContainerPub provides an API key system for securing function invocations with cryptographic signatures. This ensures that only authorized clients can invoke your functions.

## Overview

The API key system uses **HMAC-SHA256** signatures to authenticate requests:

- **Public Key**: Stored on the server, used to verify signatures
- **Private Key**: Returned only once at creation, stored locally by the CLI
- **Signature**: Created by hashing the payload with the private key

<Info>
The private key is only shown once when generated. Store it securely!
</Info>

## Key Features

- **Per-function keys**: Each function can have its own API key
- **Configurable validity**: 1 hour, 1 day, 1 week, 1 month, or forever
- **Replay protection**: 5-minute timestamp window prevents replay attacks
- **Automatic expiration**: Keys expire based on validity setting
- **One active key**: Generating a new key deactivates the previous one

## Validity Options

| Option    | Duration      | Use Case                     |
| --------- | ------------- | ---------------------------- |
| `1h`      | 1 hour        | Testing, temporary access    |
| `1d`      | 1 day         | Daily rotation               |
| `1w`      | 1 week        | Weekly rotation              |
| `1m`      | 1 month       | Monthly rotation             |
| `forever` | Never expires | Production (rotate manually) |

## CLI Commands

### Generate API Key

Generate a new API key for a deployed function:

```dart
# From function directory (uses function_config.json)
dart_cloud apikey generate --validity 1d

# With custom name
dart_cloud apikey generate --validity 1w --name "Production Key"

# For specific function
dart_cloud apikey generate --function-id <uuid> --validity 1m
```

**Output:**

```dart
✓ API key generated successfully!

╔════════════════════════════════════════════════════════════════════╗
║  ⚠️  IMPORTANT: Store the private key securely!                    ║
║  It will NOT be shown again.                                       ║
╚════════════════════════════════════════════════════════════════════╝

Key UUID: abc123-def456-...
Public Key: YWJjZGVmZ2hpams...
Private Key: eHl6MTIzNDU2Nzg5...
Validity: 1d
Expires At: 2025-12-16T02:00:00Z

✓ Private key saved to .dart_tool/api_key.secret
✓ Function config updated with API key info
```

### View API Key Info

Check the current API key status:

```dart
dart_cloud apikey info

# For specific function
dart_cloud apikey info --function-id <uuid>
```

### List All Keys

View API key history for a function:

```dart
dart_cloud apikey list

# For specific function
dart_cloud apikey list --function-id <uuid>
```

### Roll API Key

Extend an API key's expiration by its validity period:

```dart
# Roll key from current directory config
dart_cloud apikey roll

# Roll specific key
dart_cloud apikey roll --key-id <api-key-uuid>
```

This is useful for extending the lifetime of an active key without regenerating it. The expiration is extended by the key's validity period (e.g., if validity is `1d`, it adds 1 day to the current expiration).

### Revoke API Key

Revoke an active API key:

```dart
# Revoke key from current directory config
dart_cloud apikey revoke

# Revoke specific key
dart_cloud apikey revoke --key-id <api-key-uuid>
```

## Invoking with Signature

Use the `--sign` flag to sign requests with your API key:

```dart
dart_cloud invoke <function-id> --data '{"key": "value"}' --sign
```

The CLI will:

1. Load the private key from `.dart_tool/api_key.secret`
2. Create a timestamp
3. Generate HMAC-SHA256 signature
4. Include `X-Signature` and `X-Timestamp` headers

## Signature Algorithm

The signature is created using HMAC-SHA256:

```dart
// Data to sign
String dataToSign = "$timestamp:$payload";

// Create signature
var hmac = Hmac(sha256, utf8.encode(privateKey));
var digest = hmac.convert(utf8.encode(dataToSign));
String signature = base64Encode(digest.bytes);
```

**Components:**

- `timestamp`: Unix timestamp in seconds
- `payload`: JSON-encoded request body (empty string if no body)
- `privateKey`: Your API key private key

## HTTP Request Format

When invoking a signed function via HTTP:

```dart
POST /api/functions/<function-id>/invoke HTTP/1.1
Host: api.containerpub.dev
Authorization: Bearer <access-token>
Content-Type: application/json
X-Signature: <base64-signature>
X-Timestamp: <unix-timestamp>

{
  "body": {
    "key": "value"
  }
}
```

## Security Considerations

### Timestamp Window

Requests are only valid within a **5-minute window** of the timestamp. This prevents replay attacks where an attacker captures and resends a valid request.

### Key Storage

- **Private key**: Stored in `.dart_tool/api_key.secret`
- **Auto-gitignore**: The CLI automatically adds this file to `.gitignore`
- **Never commit**: Never commit private keys to version control

### Key Rotation

Best practices for key rotation:

1. Generate new key before old one expires
2. Update all clients with new private key
3. Old key is automatically deactivated
4. Monitor for failed signature verifications

## API Endpoints

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
  "validity": "1d",
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

Get API key info for a function (without private key).

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
    "expires_at": "2025-12-16T02:00:00Z",
    "is_active": true,
    "created_at": "2025-12-15T02:00:00Z"
  }
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

### DELETE /api/auth/apikey/:api_key_uuid

Revoke an API key.

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

### GET /api/auth/apikey/:function_id/list

List all API keys for a function (history).

**Headers:**

```
Authorization: Bearer <access-token>
```

**Response:**

```dart
{
  "api_keys": [
    {
      "uuid": "key-uuid-1",
      "public_key": "base64-public-key",
      "validity": "1d",
      "expires_at": "2025-12-16T02:00:00Z",
      "is_active": true,
      "created_at": "2025-12-15T02:00:00Z"
    },
    {
      "uuid": "key-uuid-2",
      "public_key": "base64-public-key",
      "validity": "1w",
      "expires_at": null,
      "is_active": false,
      "revoked_at": "2025-12-14T00:00:00Z",
      "created_at": "2025-12-07T00:00:00Z"
    }
  ]
}
```

## Error Responses

### Missing Signature (403)

When a function requires API key but signature is missing:

```dart
{
  "error": "This function requires API key signature",
  "message": "Include X-Signature and X-Timestamp headers"
}
```

### Invalid Signature (403)

When signature verification fails:

```dart
{
  "error": "Invalid signature",
  "message": "Signature verification failed. Check your API key and timestamp."
}
```

### Expired Timestamp (403)

When timestamp is outside the 5-minute window:

```dart
{
  "error": "Invalid signature",
  "message": "Signature verification failed. Check your API key and timestamp."
}
```

## Database Schema

The `api_keys` table stores API key metadata:

```dart
CREATE TABLE api_keys (
  id SERIAL PRIMARY KEY,
  uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
  function_uuid UUID NOT NULL REFERENCES functions(uuid) ON DELETE CASCADE,
  public_key TEXT NOT NULL,
  private_key_hash VARCHAR(255),
  validity VARCHAR(20) NOT NULL CHECK (validity IN ('1h', '1d', '1w', '1m', 'forever')),
  expires_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  name VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  revoked_at TIMESTAMP WITH TIME ZONE
);
```

## Example: Programmatic Signing

If you need to sign requests programmatically (not using the CLI):

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

String createSignature({
  required String privateKey,
  required String payload,
  required int timestamp,
}) {
  final dataToSign = '$timestamp:$payload';
  final hmac = Hmac(sha256, utf8.encode(privateKey));
  final digest = hmac.convert(utf8.encode(dataToSign));
  return base64Encode(digest.bytes);
}

// Usage
final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
final payload = jsonEncode({'key': 'value'});
final signature = createSignature(
  privateKey: 'your-private-key',
  payload: payload,
  timestamp: timestamp,
);

// Include in request headers
// X-Signature: $signature
// X-Timestamp: $timestamp
```

## Next Steps

- Read [Authentication](./authentication.md) for token-based auth
- Check [Function Execution](./function-execution.md) for invocation details
- Explore [CLI Reference](../cli/dart-cloud-cli.md) for all commands
