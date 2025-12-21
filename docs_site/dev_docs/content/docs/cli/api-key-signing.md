---
title: API Key Signing & Secure Invocation
description: Sign function invocations with API keys using HMAC-SHA256
---

# API Key Signing & Secure Invocation

Secure your function invocations with API key signing. This guide covers generating API keys, storing them securely, and signing requests to your deployed functions.

## Overview

API key signing provides an additional layer of security for function invocations using **HMAC-SHA256** signatures. This ensures:

- **Request Authentication** - Verify the request comes from an authorized client
- **Request Integrity** - Detect if the request has been tampered with
- **Replay Attack Prevention** - Timestamp-based validation prevents request replay

## Quick Start

### 1. Generate an API Key

```dart
dart_cloud apikey generate --validity 1d
```

**Output:**

```
✓ API key generated successfully
✓ Key UUID: abc123xyz789
✓ Validity: 1 day
✓ Expires at: 2025-12-17T10:30:00Z
✓ Secret key stored in Hive database
```

### 2. Invoke with Signature

```dart
dart_cloud invoke <function-id> --data '{"key": "value"}' --sign
```

The CLI automatically:

- Loads the secret key from Hive database
- Creates a timestamp
- Generates HMAC-SHA256 signature
- Sends request with signature headers

### 3. Backend Validates Signature

Your function receives the request with validation already performed by the platform.

## API Key Generation

### Command Syntax

```dart
dart_cloud apikey generate [options]
```

### Options

| Option          | Short | Description                                            | Default           |
| --------------- | ----- | ------------------------------------------------------ | ----------------- |
| `--function-id` | `-f`  | Function UUID (uses current directory if not provided) | Current directory |
| `--validity`    | `-v`  | Key validity duration                                  | `1d`              |
| `--name`        | `-n`  | Optional friendly name for the key                     | None              |

### Validity Options

- `1h` - 1 hour
- `1d` - 1 day (default)
- `1w` - 1 week
- `1m` - 1 month
- `forever` - Never expires

### Examples

**Generate key for current function (1 day validity):**

```dart
dart_cloud apikey generate
```

**Generate key with custom validity:**

```dart
dart_cloud apikey generate --validity 1w
```

**Generate key with friendly name:**

```dart
dart_cloud apikey generate --validity 1m --name "Production Key"
```

**Generate key for specific function:**

```dart
dart_cloud apikey generate --function-id <uuid> --validity 1d
```

## Secret Key Storage

When you generate an API key, the secret key is:

1. **Generated** on the backend
2. **Returned** to the CLI (only once!)
3. **Stored** in Hive database at `~/.dart_cloud/hive/`
4. **Never** transmitted again

### Storage Location

```
~/.dart_cloud/hive/
├── api_keys.hivedb
└── api_keys.lock
```

### Key Structure

The secret key is stored with:

- **Key**: Function UUID
- **Value**: Base64-encoded secret key

<Warning>
The secret key is only shown once during generation. Save it securely if you need to use it outside the CLI. The CLI stores it automatically in the Hive database.
</Warning>

## Signing Requests

### How Signing Works

When you invoke a function with `--sign`:

1. **Load Secret Key** - Retrieve from Hive database using function ID
2. **Create Timestamp** - Current Unix timestamp in seconds
3. **Build Data** - Format: `"<timestamp>:<payload>"`
4. **Generate Signature** - HMAC-SHA256(secretKey, data)
5. **Encode** - Base64 encode the signature
6. **Send Headers** - Include `X-Signature` and `X-Timestamp`

### Signature Algorithm

```dart
dataToSign = "<timestamp>:<jsonPayload>"
signature = base64(HMAC-SHA256(secretKey, dataToSign))
```

### Request Headers

```dart
X-Signature: <base64-encoded-signature>
X-Timestamp: <unix-timestamp-in-seconds>
Content-Type: application/json
```

### Example Request

```dart
curl -X POST https://api.containerpub.com/invoke/<function-id> \
  -H "X-Signature: abc123def456..." \
  -H "X-Timestamp: 1702816200" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

## Invoking with Signatures

### Command Syntax

```dart
dart_cloud invoke <function-id> [options]
```

### Options

| Option   | Description                          |
| -------- | ------------------------------------ |
| `--data` | JSON data to pass to the function    |
| `--sign` | Sign the request with stored API key |

### Examples

**Invoke without signature:**

```dart
dart_cloud invoke <function-id>
```

**Invoke with data (no signature):**

```dart
dart_cloud invoke <function-id> --data '{"name": "John", "age": 30}'
```

**Invoke with signature:**

```dart
dart_cloud invoke <function-id> --sign
```

**Invoke with data and signature:**

```dart
dart_cloud invoke <function-id> --data '{"name": "John"}' --sign
```

### What Happens During Signed Invocation

1. **Validation** - CLI checks if function has an API key configured
2. **Key Retrieval** - Loads secret key from Hive database
3. **Signature Creation** - Generates HMAC-SHA256 signature
4. **Request Sending** - Sends with `X-Signature` and `X-Timestamp` headers
5. **Backend Validation** - Platform verifies signature and timestamp
6. **Function Execution** - If valid, function executes normally

### Error Handling

**Missing API Key:**

```dart
Error: No API key configured for this function
Run: dart_cloud apikey generate
```

**Invalid Signature:**

```dart
Error: Invalid signature
The request signature does not match
```

**Expired Timestamp:**

```dart
Error: Request timestamp too old
Timestamp must be within 5 minutes of server time
```

## Managing API Keys

### View API Key Info

```dart
dart_cloud apikey info
dart_cloud apikey info --function-id <uuid>
```

**Output:**

```dart
API Key Information:
  UUID: abc123xyz789
  Validity: 1 day
  Created: 2025-12-16T10:30:00Z
  Expires: 2025-12-17T10:30:00Z
  Status: Active
```

### List All Keys

```dart
dart_cloud apikey list
dart_cloud apikey list --function-id <uuid>
```

### Extend Expiration

Roll an API key to extend its expiration by its validity period:

```dart
dart_cloud apikey roll
dart_cloud apikey roll --key-id <api-key-uuid>
```

**Example:**

If your key has `1d` validity and expires in 2 hours, rolling it will extend expiration by 1 day.

### Revoke API Key

```dart
dart_cloud apikey revoke
dart_cloud apikey revoke --key-id <api-key-uuid>
```

After revocation:

- Secret key removed from Hive database
- Backend invalidates the key
- Signed requests will fail

## Security Best Practices

### 1. Key Rotation

Regularly generate new keys and revoke old ones:

```dart
# Generate new key
dart_cloud apikey generate --validity 1w --name "New Production Key"

# Revoke old key
dart_cloud apikey revoke --key-id <old-key-uuid>
```

### 2. Validity Periods

Use appropriate validity periods:

- **Development**: `1h` or `1d` (short-lived for testing)
- **Production**: `1w` or `1m` (longer-lived but still manageable)
- **Long-term**: `forever` (only if necessary, requires careful management)

### 3. Key Storage

- **Never** commit secret keys to version control
- **Never** share secret keys via email or chat
- **Store** in secure environment variables or secret managers
- **Rotate** regularly (at least monthly)

### 4. Timestamp Validation

The platform validates that request timestamps are within 5 minutes of server time. This prevents:

- **Replay Attacks** - Old requests cannot be replayed
- **Clock Skew** - Allows for minor time differences between systems
- **Request Forgery** - Attackers cannot use old signatures

### 5. Multiple Keys

For different environments, generate separate keys:

```dart
# Development key
dart_cloud apikey generate --validity 1d --name "Dev Key"

# Staging key
dart_cloud apikey generate --validity 1w --name "Staging Key"

# Production key
dart_cloud apikey generate --validity 1m --name "Production Key"
```

## Troubleshooting

### "No API key configured for this function"

**Solution:** Generate an API key first:

```dart
dart_cloud apikey generate
```

### "Invalid signature"

**Possible causes:**

1. **Wrong secret key** - Ensure you're using the correct function ID
2. **Key was revoked** - Generate a new key
3. **Data was modified** - Ensure payload hasn't changed
4. **Clock skew** - Sync system time with server

**Solution:**

```dart
# Verify key exists
dart_cloud apikey info

# Generate new key if needed
dart_cloud apikey generate
```

### "Request timestamp too old"

**Cause:** Request timestamp is more than 5 minutes old

**Solution:**

1. Sync system clock with NTP
2. Ensure server time is accurate
3. Retry the request

### "Key not found in Hive database"

**Cause:** Secret key was not stored properly or was deleted

**Solution:**

```dart
# Generate new key
dart_cloud apikey generate

# Verify it's stored
dart_cloud apikey info
```

## Function-Side Validation

Your function receives requests with signatures already validated by the platform. The validation includes:

- **Signature Verification** - HMAC-SHA256 signature is valid
- **Timestamp Validation** - Timestamp is within 5 minutes
- **Key Validity** - API key hasn't expired or been revoked

If validation fails, the request is rejected before reaching your function.

### Accessing Request Metadata

In your function, you can access request metadata:

```dart
@cloudFunction
class SecureFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    // Request is already validated by platform
    // Signature headers are removed before reaching function

    final body = request.body as Map<String, dynamic>;
    return CloudResponse.json({
      'message': 'Request was securely signed',
      'received_data': body,
    });
  }
}
```

## Examples

### Example 1: Secure API Endpoint

```dart
// Generate key for production
dart_cloud apikey generate --validity 1m --name "API Key"

// Invoke with signature
dart_cloud invoke <function-id> \
  --data '{"action": "process", "id": 123}' \
  --sign
```

### Example 2: Automated Invocation

```dart
#!/bin/bash
# Script to invoke function with signature

FUNCTION_ID="abc123xyz789"
DATA='{"timestamp": "'$(date +%s)'", "action": "sync"}'

dart_cloud invoke $FUNCTION_ID \
  --data "$DATA" \
  --sign
```

### Example 3: Key Rotation

```dart
#!/bin/bash
# Rotate API keys monthly

FUNCTION_ID="abc123xyz789"

# Get current key
CURRENT_KEY=$(dart_cloud apikey info --function-id $FUNCTION_ID | grep UUID)

# Generate new key
dart_cloud apikey generate --function-id $FUNCTION_ID --validity 1m

# Wait for deployment to use new key
sleep 60

# Revoke old key
dart_cloud apikey revoke --key-id $CURRENT_KEY
```

## See Also

- [dart_cloud_cli Reference](./dart-cloud-cli.md) - Complete CLI documentation
- [Backend API Keys](../backend/api-keys.md) - Backend implementation details
- [Backend API Reference](../backend/api-reference.md) - API endpoint documentation
