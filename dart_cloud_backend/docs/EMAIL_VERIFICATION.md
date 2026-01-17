# Email OTP Verification System

## Overview

The Email OTP Verification system provides secure email verification for users in the Dart Cloud Backend. It uses One-Time Passwords (OTPs) sent via email to verify user email addresses during registration and account management.

## Architecture

### Components

1. **EmailVerificationService** - Core service handling OTP generation, storage, and verification
2. **EmailVerificationHandler** - HTTP handlers for API endpoints
3. **OTP Service** - Utility for generating and validating OTPs
4. **Email Service** - Integration with email provider (ForwardEmail)
5. **Database Integration** - OTP storage using EmailVerificationOtpEntity

### Security Features

- **HMAC-SHA256 Hashing**: OTPs are hashed using HMAC with unique salts
- **Time-based Expiration**: OTPs expire after 24 hours
- **One-time Use**: OTPs are deleted after successful verification
- **Rate Limiting**: Resend functionality cleans up previous OTPs
- **Secure Storage**: OTPs stored in database with proper indexing

## API Endpoints

### Send Verification OTP

**POST** `/api/email-verification/send`

Sends a verification OTP to the user's email address.

**Headers:**

- `Authorization: Bearer <access_token>`

**Response:**

```json
{
  "message": "Verification OTP sent to your email"
}
```

### Verify OTP

**POST** `/api/email-verification/verify`

Verifies the provided OTP and marks the user's email as verified.

**Headers:**

- `Authorization: Bearer <access_token>`

**Body:**

```json
{
  "otp": "123456"
}
```

**Response:**

```json
{
  "message": "Email verified successfully"
}
```

### Resend Verification OTP

**POST** `/api/email-verification/resend`

Resends a new verification OTP to the user's email address.

**Headers:**

- `Authorization: Bearer <access_token>`

**Response:**

```json
{
  "message": "Verification OTP resent to your email"
}
```

### Check Verification Status

**GET** `/api/email-verification/status`

Checks if the user's email is verified.

**Headers:**

- `Authorization: Bearer <access_token>`

**Response:**

```json
{
  "isEmailVerified": true,
  "message": "Email is verified"
}
```

## Configuration

Add the following environment variables to your `.env` file:

```env
# Email Service Configuration
EMAIL_API_KEY=your_forwardemail_api_key
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
EMAIL_LOGO=https://yourdomain.com/logo.png
EMAIL_COMPANY_NAME=Your Company
EMAIL_SUPPORT_EMAIL=support@yourdomain.com
```

## Database Schema

### Email Verification OTPs Table

```sql
CREATE TABLE email_verification_otps (
  id SERIAL PRIMARY KEY,
  user_uuid UUID UNIQUE NOT NULL REFERENCES users(uuid) ON DELETE CASCADE,
  otp_hash VARCHAR(255) UNIQUE NOT NULL,
  salt VARCHAR(500) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Users Table (Updated)

```sql
ALTER TABLE users ADD COLUMN is_email_verified BOOLEAN NOT NULL DEFAULT false;
```

## Usage Examples

### Send Verification OTP

```bash
curl -X POST http://localhost:8080/api/email-verification/send \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json"
```

### Verify OTP

```bash
curl -X POST http://localhost:8080/api/email-verification/verify \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"otp": "123456"}'
```

### Check Status

```bash
curl -X GET http://localhost:8080/api/email-verification/status \
  -H "Authorization: Bearer <access_token>"
```

## Implementation Details

### OTP Generation

1. Generate 6-digit numeric OTP
2. Create unique salt using email and timestamp
3. Hash OTP using HMAC-SHA256 with the salt
4. Store hash and salt in database
5. Send plain OTP via email

### OTP Verification

1. Retrieve stored OTP hash and salt for user
2. Check if OTP is expired (24 hours)
3. Hash provided OTP with stored salt
4. Compare with stored hash
5. If valid, mark user email as verified
6. Clean up used OTP

### Security Considerations

- OTPs are never stored in plain text
- Each user can only have one active OTP
- OTPs expire after 24 hours
- Failed verification attempts are not tracked (to prevent enumeration)
- Email addresses are validated before OTP generation

## Error Handling

The system returns appropriate HTTP status codes:

- `200 OK` - Success
- `400 Bad Request` - Invalid input or already verified
- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - User not found
- `500 Internal Server Error` - Server error

## Dependencies

- `email_service` - Email sending functionality
- `otp_service` - OTP generation and validation
- `database` - Database integration
- `dart_jsonwebtoken` - JWT token validation
- `bcrypt` - Password hashing (for user management)

## Testing

Run the test suite:

```bash
dart test test/services/email_verification_service_test.dart
```

## Maintenance

### Cleanup Expired OTPs

The system includes a cleanup method to remove expired OTPs:

```dart
await EmailVerificationService().cleanupExpiredOtps();
```

This can be called periodically (e.g., daily cron job) to maintain database performance.

## Integration with Registration

To integrate email verification with user registration:

1. User registers with email and password
2. User is created with `is_email_verified = false`
3. Send verification OTP automatically
4. User verifies email using OTP
5. User account is fully activated

## Troubleshooting

### Common Issues

1. **OTP not received**: Check email configuration and spam folder
2. **OTP expired**: OTPs expire after 24 hours, request a new one
3. **Invalid OTP**: Ensure correct 6-digit code is entered
4. **Email already verified**: Check verification status before sending

### Debug Mode

Enable debug logging by setting the log level:

```dart
Logger.root.level = Level.DEBUG;
```

## Future Enhancements

- Rate limiting for OTP requests
- Multiple email templates
- SMS verification option
- Email verification analytics
- Bulk email verification for admin users
