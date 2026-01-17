---
title: Email Verification System
description: Complete email OTP verification implementation for ContainerPub
---

# Email Verification System

ContainerPub implements a comprehensive email OTP (One-Time Password) verification system to ensure user email authenticity after registration and first login.

## Overview

The email verification system provides:

- **OTP Generation** - Secure 6-digit codes with configurable expiry
- **Rate Limiting** - Prevent brute force and spam attempts
- **Resend Functionality** - Allow users to request new codes
- **Status Tracking** - Track verification status per user
- **Email Integration** - Automated email delivery via configured provider
- **Cooldown Management** - Prevent rapid resend requests

## Architecture

### Components

1. **EmailVerificationService** - Core business logic
2. **EmailVerificationMiddleware** - Rate limiting and request validation
3. **EmailVerificationLimiter** - Cooldown and attempt tracking
4. **Database Layer** - User verification status storage
5. **Email Provider** - External email delivery service

### Data Flow

```dart
User Registration/Login
    ↓
Check Email Verification Status
    ↓
If Not Verified:
    ├→ Generate OTP
    ├→ Store in Database
    ├→ Send via Email
    └→ Return Status
    ↓
User Submits OTP
    ↓
Validate OTP
    ├→ Check Expiry
    ├→ Check Attempts
    └→ Verify Code
    ↓
Mark Email as Verified
    ↓
Return Success
```

## API Endpoints

### Send Verification OTP

```dart
POST /api/email-verification/send
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request:**

```dart
{}
```

**Response (Success):**

```dart
{
  "message": "OTP sent to your email",
  "email": "user@example.com",
  "expiresIn": 300
}
```

**Response (Already Verified):**

```dart
{
  "message": "Email already verified",
  "isVerified": true
}
```

**Error Responses:**

- `429 Too Many Requests` - Rate limited (cooldown active)
- `401 Unauthorized` - Invalid or expired token
- `500 Internal Server Error` - Email service failure

### Verify OTP Code

```dart
POST /api/email-verification/verify
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "otp": "123456"
}
```

**Response (Success):**

```dart
{
  "message": "Email verified successfully",
  "isVerified": true
}
```

**Response (Invalid OTP):**

```dart
{
  "error": "Invalid OTP code",
  "attemptsRemaining": 2
}
```

**Error Responses:**

- `400 Bad Request` - Invalid OTP format or expired
- `401 Unauthorized` - Invalid token
- `429 Too Many Requests` - Too many failed attempts

### Resend Verification OTP

```dart
POST /api/email-verification/resend
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request:**

```dart
{}
```

**Response:**

```dart
{
  "message": "OTP resent to your email",
  "expiresIn": 300,
  "cooldownRemaining": 0
}
```

**Error Responses:**

- `429 Too Many Requests` - Resend cooldown active
- `401 Unauthorized` - Invalid token

### Check Verification Status

```dart
GET /api/email-verification/status
Authorization: Bearer <access_token>
```

**Response:**

```dart
{
  "isVerified": false,
  "email": "user@example.com",
  "lastOtpSentAt": "2024-01-17T10:30:00Z",
  "otpExpiresAt": "2024-01-17T10:35:00Z"
}
```

## Rate Limiting Strategy

### OTP Send Limits

- **Initial Send**: Allowed immediately after login
- **Resend Cooldown**: 60 seconds between resend requests
- **Max Resends**: 5 per hour per user
- **Daily Limit**: 10 OTP sends per day

### Verification Attempt Limits

- **Max Attempts**: 5 failed attempts per OTP
- **Lockout Duration**: 15 minutes after max attempts
- **Cooldown Between Attempts**: 2 seconds

### Implementation

```dart
class EmailVerificationLimiter {
  // Track OTP send attempts
  Future<bool> canSendOtp(String userId) async {
    final key = 'otp_send_$userId';
    final attempts = await _getAttempts(key);

    if (attempts >= 5) {
      final lastAttempt = await _getLastAttemptTime(key);
      final hourAgo = DateTime.now().subtract(Duration(hours: 1));

      if (lastAttempt.isAfter(hourAgo)) {
        return false; // Rate limited
      }
    }

    return true;
  }

  // Track verification attempts
  Future<bool> canVerifyOtp(String userId, String otpId) async {
    final key = 'verify_attempts_$otpId';
    final attempts = await _getAttempts(key);

    if (attempts >= 5) {
      return false; // Too many attempts
    }

    return true;
  }

  // Get cooldown time remaining
  Future<int> getResendCooldown(String userId) async {
    final key = 'otp_resend_$userId';
    final lastSent = await _getLastAttemptTime(key);
    final cooldownEnd = lastSent.add(Duration(seconds: 60));

    final remaining = cooldownEnd.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}
```

## OTP Generation & Storage

### OTP Code Generation

```dart
class OtpGenerator {
  /// Generate 6-digit OTP code
  static String generate() {
    final random = Random.secure();
    final values = List<int>.generate(6, (i) => random.nextInt(10));
    return values.join();
  }
}
```

### Database Storage

**Table: `email_verification_otps`**

| Column        | Type       | Description                            |
| ------------- | ---------- | -------------------------------------- |
| `id`          | UUID       | Primary key                            |
| `user_id`     | UUID       | Foreign key to users                   |
| `otp_code`    | VARCHAR(6) | Hashed OTP code                        |
| `attempts`    | INT        | Failed verification attempts           |
| `created_at`  | TIMESTAMP  | Creation time                          |
| `expires_at`  | TIMESTAMP  | OTP expiry (5 minutes)                 |
| `verified_at` | TIMESTAMP  | Verification time (null if unverified) |

**Table: `email_verifications`**

| Column             | Type      | Description                  |
| ------------------ | --------- | ---------------------------- |
| `user_id`          | UUID      | Primary key (foreign key)    |
| `email`            | VARCHAR   | User's email address         |
| `is_verified`      | BOOLEAN   | Verification status          |
| `verified_at`      | TIMESTAMP | Verification completion time |
| `last_otp_sent_at` | TIMESTAMP | Last OTP send time           |

### OTP Hashing

```dart
String _hashOtp(String otp) {
  final bytes = utf8.encode(otp);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

**Why Hash OTPs?**

- Never store plain text codes
- Prevent database breach exposure
- Match hashed code during verification
- One-way transformation

## Email Service Integration

### Email Template

```dart
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <style>
      body {
        font-family: Arial, sans-serif;
      }
      .container {
        max-width: 600px;
        margin: 0 auto;
      }
      .header {
        background: #007bff;
        color: white;
        padding: 20px;
      }
      .content {
        padding: 20px;
      }
      .otp-code {
        font-size: 32px;
        font-weight: bold;
        letter-spacing: 5px;
        text-align: center;
        margin: 20px 0;
      }
      .footer {
        color: #666;
        font-size: 12px;
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <h1>Email Verification</h1>
      </div>
      <div class="content">
        <p>Hi {{userName}},</p>
        <p>Your verification code is:</p>
        <div class="otp-code">{{otpCode}}</div>
        <p>This code expires in 5 minutes.</p>
        <p>If you didn't request this code, please ignore this email.</p>
      </div>
      <div class="footer">
        <p>© 2024 ContainerPub. All rights reserved.</p>
      </div>
    </div>
  </body>
</html>
```

### Email Service Implementation

```dart
class EmailService {
  final String _provider; // 'sendgrid', 'mailgun', etc.
  final String _apiKey;

  EmailService({required String provider, required String apiKey})
    : _provider = provider,
      _apiKey = apiKey;

  Future<void> sendVerificationEmail({
    required String email,
    required String userName,
    required String otpCode,
  }) async {
    final emailContent = _buildEmailContent(userName, otpCode);

    switch (_provider) {
      case 'sendgrid':
        await _sendViaSendGrid(email, emailContent);
        break;
      case 'mailgun':
        await _sendViaMailgun(email, emailContent);
        break;
      default:
        throw Exception('Unknown email provider: $_provider');
    }
  }

  String _buildEmailContent(String userName, String otpCode) {
    // Build HTML email with template
    return '''
      <h1>Email Verification</h1>
      <p>Hi $userName,</p>
      <p>Your verification code is:</p>
      <div style="font-size: 32px; font-weight: bold;">$otpCode</div>
      <p>This code expires in 5 minutes.</p>
    ''';
  }
}
```

## Integration with Authentication

### Login Response Update

The login endpoint now includes email verification status:

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
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "isEmailVerified": false,
  "userEmail": "user@example.com"
}
```

### Auto-Send OTP on First Login

```dart
class AuthHandler {
  Future<Response> login(Request request) async {
    // ... existing login logic ...

    final loginResponse = LoginResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      isEmailVerified: user.isEmailVerified,
      userEmail: user.email,
    );

    // Auto-send OTP if not verified
    if (!user.isEmailVerified) {
      await emailVerificationService.sendOtp(user.id);
    }

    return Response.ok(jsonEncode(loginResponse.toJson()));
  }
}
```

## Error Handling

### Common Error Scenarios

| Scenario           | Status | Response                                                             |
| ------------------ | ------ | -------------------------------------------------------------------- |
| OTP expired        | 400    | `{"error": "OTP expired", "message": "Please request a new code"}`   |
| Invalid OTP format | 400    | `{"error": "Invalid OTP format", "message": "OTP must be 6 digits"}` |
| Too many attempts  | 429    | `{"error": "Too many attempts", "cooldownMinutes": 15}`              |
| Rate limited       | 429    | `{"error": "Rate limited", "retryAfterSeconds": 60}`                 |
| Already verified   | 400    | `{"error": "Email already verified"}`                                |
| User not found     | 404    | `{"error": "User not found"}`                                        |

### Error Response Format

```dart
{
  "error": "error_code",
  "message": "Human-readable message",
  "details": {
    "attemptsRemaining": 2,
    "cooldownSeconds": 45
  }
}
```

## Security Considerations

### OTP Security

1. **6-Digit Codes** - 1 million possible combinations
2. **5-Minute Expiry** - Limits exposure window
3. **Attempt Limiting** - 5 attempts per OTP
4. **Hashed Storage** - Never store plain text
5. **Secure Generation** - Use `Random.secure()`

### Rate Limiting

1. **Per-User Limits** - Prevent individual abuse
2. **Cooldown Timers** - Space out requests
3. **Exponential Backoff** - Increase penalties
4. **IP-Based Limits** - Optional additional layer

### Email Delivery

1. **HTTPS Only** - Secure transmission
2. **Signed Emails** - Optional DKIM/SPF
3. **No Sensitive Data** - Don't include passwords
4. **Audit Logging** - Track all sends

## Monitoring & Logging

### Key Metrics

```dart
class EmailVerificationMetrics {
  // Track OTP sends
  void recordOtpSent(String userId) {
    _metrics.increment('email_verification.otp_sent');
  }

  // Track successful verifications
  void recordVerificationSuccess(String userId) {
    _metrics.increment('email_verification.success');
  }

  // Track failed attempts
  void recordVerificationFailure(String userId) {
    _metrics.increment('email_verification.failure');
  }

  // Track rate limit hits
  void recordRateLimitHit(String userId) {
    _metrics.increment('email_verification.rate_limited');
  }
}
```

### Logging

```dart
// Log OTP send
logger.info('OTP sent to user', {
  'userId': userId,
  'email': email,
  'timestamp': DateTime.now(),
});

// Log verification attempt
logger.info('Verification attempt', {
  'userId': userId,
  'success': true,
  'timestamp': DateTime.now(),
});

// Log rate limit
logger.warn('Rate limit exceeded', {
  'userId': userId,
  'reason': 'too_many_otp_sends',
  'timestamp': DateTime.now(),
});
```

## Testing Strategy

### Unit Tests

```dart
test('OTP generation produces 6-digit code', () {
  final otp = OtpGenerator.generate();
  expect(otp.length, equals(6));
  expect(int.tryParse(otp), isNotNull);
});

test('OTP verification succeeds with correct code', () async {
  final service = EmailVerificationService();
  final userId = 'test-user';

  await service.sendOtp(userId);
  final result = await service.verifyOtp(userId, correctOtp);

  expect(result, isTrue);
});

test('Rate limiting prevents rapid resends', () async {
  final limiter = EmailVerificationLimiter();
  final userId = 'test-user';

  expect(await limiter.canSendOtp(userId), isTrue);
  await limiter.recordOtpSend(userId);
  expect(await limiter.canSendOtp(userId), isFalse);
});
```

### Integration Tests

```dart
test('Complete email verification flow', () async {
  // 1. User logs in
  final loginResponse = await authService.login(email, password);
  expect(loginResponse.isEmailVerified, isFalse);

  // 2. OTP sent automatically
  // (verified via email mock)

  // 3. User verifies OTP
  final verifyResult = await emailVerificationService.verifyOtp(userId, otp);
  expect(verifyResult, isTrue);

  // 4. Status updated
  final status = await emailVerificationService.getStatus(userId);
  expect(status.isVerified, isTrue);
});
```

## Configuration

### Environment Variables

```dart
# Email Service
EMAIL_PROVIDER=sendgrid
EMAIL_API_KEY=your-api-key-here
EMAIL_FROM_ADDRESS=noreply@containerpub.com

# OTP Configuration
OTP_EXPIRY_MINUTES=5
OTP_MAX_ATTEMPTS=5
OTP_RESEND_COOLDOWN_SECONDS=60

# Rate Limiting
MAX_OTP_SENDS_PER_HOUR=5
MAX_OTP_SENDS_PER_DAY=10
VERIFICATION_LOCKOUT_MINUTES=15
```

## Best Practices

### For Developers

1. **Always validate OTP format** - Check 6 digits before API call
2. **Implement proper error handling** - Show user-friendly messages
3. **Use HTTPS** - Secure all communication
4. **Respect rate limits** - Don't retry immediately
5. **Log verification events** - For debugging and auditing

### For Operations

1. **Monitor email delivery** - Track send success rates
2. **Set up alerts** - For high failure rates
3. **Regular backups** - Include verification data
4. **Audit logs** - Keep verification history
5. **Test email service** - Regular health checks

## Next Steps

- [Frontend Integration](./email-verification-frontend) - Implement UI
- [API Reference](./api-reference) - Complete endpoint documentation
- [Authentication System](./authentication) - Auth flow details
