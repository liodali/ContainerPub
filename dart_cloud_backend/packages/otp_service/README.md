# OTP Service

A secure OTP (One-Time Password) service for email verification with time-based uniqueness and HMAC-SHA256 hashing.

## Features

- **Secure OTP Generation**: 6-digit numeric OTPs with time-based uniqueness
- **HMAC-SHA256 Hashing**: Cryptographically secure OTP storage
- **Salt-based Security**: Unique salt per OTP using `timestamp:email` format
- **Expiry Management**: 24-hour validity period
- **Verification**: Constant-time hash comparison
- **Type-safe Results**: Structured `OtpResult` for complete OTP data

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  otp_service:
    path: ../packages/otp_service
```

## Usage

### Generate OTP with Hash

```dart
import 'package:otp_service/otp_service.dart';

// Generate complete OTP result
final result = OtpService.generateOtpWithHash(
  email: 'user@example.com',
);

print('OTP: ${result.otp}');        // e.g., "123456"
print('Hash: ${result.hash}');      // SHA-256 hash
print('Salt: ${result.salt}');      // timestamp:email
print('Created: ${result.createdAt}');

// Store hash and salt in database (NOT the OTP!)
// Send OTP to user via email
```

### Verify OTP

```dart
// User submits OTP
final userOtp = '123456';

// Retrieve stored hash and salt from database
final storedHash = '...';
final storedSalt = '...';

// Verify OTP
final isValid = OtpService.verifyOtp(
  otp: userOtp,
  storedHash: storedHash,
  storedSalt: storedSalt,
);

if (isValid) {
  print('OTP verified successfully');
} else {
  print('Invalid OTP');
}
```

### Check Expiry

```dart
// Retrieve OTP creation timestamp from database
final createdAt = DateTime.parse('2024-01-15T12:30:45Z');

final isExpired = OtpService.isOtpExpired(createdAt);

if (isExpired) {
  print('OTP has expired (>24 hours old)');
}
```

### Individual Operations

```dart
// Generate OTP only
final otp = OtpService.generateOtp();  // "123456"

// Generate salt
final salt = OtpService.generateSalt(
  email: 'user@example.com',
  timestamp: DateTime.now(),
);

// Hash OTP
final hash = OtpService.hashOtp(
  otp: otp,
  salt: salt,
);
```

## Security Model

### OTP Generation

- Uses `DateTime.now().microsecondsSinceEpoch` for time-based uniqueness
- Combines timestamp with secure random number
- Ensures 6-digit format with leading zero padding

### Salt Generation

- Format: `{microsecondsSinceEpoch}:{email}`
- Example: `1705324245123456:user@example.com`
- Unique per OTP even if same code generated

### Hashing

- Algorithm: HMAC-SHA256
- Key: Salt (timestamp:email)
- Message: OTP code
- Output: 64-character hex string

### Verification Flow

1. User submits OTP
2. Retrieve stored `hash` and `salt` from database
3. Compute hash of submitted OTP using stored salt
4. Compare computed hash with stored hash
5. Check expiry (24 hours from creation)

### Storage Requirements

**Database Schema:**

```sql
CREATE TABLE email_verification_otps (
  id SERIAL PRIMARY KEY,
  user_uuid UUID UNIQUE NOT NULL,
  otp_hash VARCHAR(255) UNIQUE NOT NULL,
  salt VARCHAR(500) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

**What to Store:**

- `otp_hash`: Result of `OtpService.hashOtp()`
- `salt`: Result of `OtpService.generateSalt()`
- `created_at`: Timestamp for expiry checking

**What NOT to Store:**

- ❌ Plain-text OTP (only send to user, never store)

## Constants

```dart
OtpService.otpLength    // 6
OtpService.otpValidity  // Duration(hours: 24)
```

## API Reference

### `OtpService`

#### `generateOtp() → String`

Generates a 6-digit numeric OTP with time-based uniqueness.

**Returns:** String (e.g., "123456")

#### `generateSalt({required String email, required DateTime timestamp}) → String`

Generates salt from timestamp and email.

**Parameters:**

- `email`: User's email address
- `timestamp`: OTP creation timestamp

**Returns:** String in format `{microseconds}:{email}`

#### `hashOtp({required String otp, required String salt}) → String`

Creates HMAC-SHA256 hash of OTP using salt.

**Parameters:**

- `otp`: 6-digit OTP code
- `salt`: Salt string

**Returns:** 64-character hex hash

#### `verifyOtp({required String otp, required String storedHash, required String storedSalt}) → bool`

Verifies OTP against stored hash using stored salt.

**Parameters:**

- `otp`: User-submitted OTP
- `storedHash`: Hash from database
- `storedSalt`: Salt from database

**Returns:** `true` if OTP matches, `false` otherwise

#### `isOtpExpired(DateTime createdAt) → bool`

Checks if OTP is expired (>24 hours old).

**Parameters:**

- `createdAt`: OTP creation timestamp

**Returns:** `true` if expired, `false` otherwise

#### `generateOtpWithHash({required String email, DateTime? timestamp}) → OtpResult`

Generates complete OTP result with hash and salt.

**Parameters:**

- `email`: User's email address
- `timestamp`: Optional timestamp (defaults to `DateTime.now()`)

**Returns:** `OtpResult` containing `otp`, `hash`, `salt`, `createdAt`

### `OtpResult`

Data class containing complete OTP information.

**Fields:**

- `otp`: String - The 6-digit OTP code
- `hash`: String - HMAC-SHA256 hash
- `salt`: String - Salt used for hashing
- `createdAt`: DateTime - Creation timestamp

## Testing

The package includes comprehensive unit tests covering:

- OTP generation (uniqueness, format, padding)
- Salt generation (format, uniqueness)
- Hashing (consistency, uniqueness, format)
- Verification (correct/incorrect OTP, salt validation)
- Expiry checking (various time ranges)
- Integration scenarios
- Edge cases

Run tests:

```bash
cd dart_cloud_backend/packages/otp_service
dart test
```

## Example: Complete Email Verification Flow

```dart
// 1. User Registration
final result = OtpService.generateOtpWithHash(
  email: 'user@example.com',
);

// 2. Store in database
await database.execute(
  'INSERT INTO email_verification_otps (user_uuid, otp_hash, salt, created_at) '
  'VALUES (?, ?, ?, ?)',
  [userUuid, result.hash, result.salt, result.createdAt],
);

// 3. Send OTP via email (NOT stored in DB)
await emailService.sendOtpEmail(
  email: 'user@example.com',
  otp: result.otp,
);

// 4. User submits OTP for verification
final userOtp = '123456';

// 5. Retrieve from database
final row = await database.query(
  'SELECT otp_hash, salt, created_at FROM email_verification_otps '
  'WHERE user_uuid = ?',
  [userUuid],
);

// 6. Check expiry
if (OtpService.isOtpExpired(row['created_at'])) {
  return Response.json({'error': 'OTP expired'}, status: 410);
}

// 7. Verify OTP
final isValid = OtpService.verifyOtp(
  otp: userOtp,
  storedHash: row['otp_hash'],
  storedSalt: row['salt'],
);

if (!isValid) {
  return Response.json({'error': 'Invalid OTP'}, status: 422);
}

// 8. Mark email as verified
await database.execute(
  'UPDATE users SET is_email_verified = true WHERE uuid = ?',
  [userUuid],
);

// 9. Delete used OTP
await database.execute(
  'DELETE FROM email_verification_otps WHERE user_uuid = ?',
  [userUuid],
);
```

## Security Best Practices

1. **Never Store Plain-text OTP**: Only store hash and salt
2. **Use HTTPS**: Always transmit OTPs over secure connections
3. **Rate Limiting**: Implement rate limiting on verification attempts
4. **Single Use**: Delete OTP after successful verification
5. **Expiry**: Always check expiry before verification
6. **Email Enumeration**: Use generic messages for resend endpoints
7. **Constant-time Comparison**: Built into hash comparison

## License

Part of the ContainerPub/Dart Cloud project.
