# Email Service

A service for sending OTP verification emails using the Forward Email API with support for configuration management and testing.

## Features

- **OTP Email Sending**: Send verification codes via email using professional templates
- **Configuration Management**: Centralized email configuration with `EmailConfig`
- **Interface-based Design**: Easy to mock and test with `EmailServiceInterface`
- **Error Handling**: Custom `EmailServiceException` for better error management
- **Template Support**: Uses `PasswordCodeTemplate` from `dart_cloud_email_client_api`
- **Testable**: Comprehensive mock tests included

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  email_service:
    path: ../packages/email_service
```

## Usage

### Basic Setup

```dart
import 'package:email_service/email_service.dart';

void main() {
  final service = EmailService();

  // Configure the service
  final config = EmailConfig(
    apiKey: 'your-forward-email-api-key',
    fromAddress: 'noreply@yourdomain.com',
    companyName: 'Your Company',
    logo: 'https://yourdomain.com/logo.png',
    supportEmail: 'support@yourdomain.com',
  );

  // Initialize
  service.initialize(config);

  // Send OTP email
  await service.sendOtpEmail(
    email: 'user@example.com',
    otp: '123456',
    userName: 'John Doe',
  );

  // Clean up
  service.close();
}
```

### Send OTP Email

```dart
final service = EmailService();

final config = EmailConfig(
  apiKey: 'your-api-key',
  fromAddress: 'noreply@example.com',
  companyName: 'Dart Cloud',
);

service.initialize(config);

try {
  final success = await service.sendOtpEmail(
    email: 'user@example.com',
    otp: '123456',
    userName: 'User Name', // Optional
  );

  if (success) {
    print('OTP email sent successfully');
  }
} on EmailServiceException catch (e) {
  print('Failed to send email: ${e.message}');
}
```

### Configuration Options

```dart
// Minimal configuration
const config = EmailConfig(
  apiKey: 'your-api-key',
  fromAddress: 'noreply@example.com',
);

// Full configuration
const config = EmailConfig(
  apiKey: 'your-api-key',
  fromAddress: 'noreply@example.com',
  logo: 'https://example.com/logo.png',
  companyName: 'Your Company',
  supportEmail: 'support@example.com',
);

// Update configuration
final updatedConfig = config.copyWith(
  companyName: 'New Company Name',
);
```

### Check Initialization Status

```dart
final service = EmailService();

print(service.isInitialized); // false

service.initialize(config);

print(service.isInitialized); // true

service.close();

print(service.isInitialized); // false
```

## Email Template

The service uses `PasswordCodeTemplate` which generates:

**HTML Email:**

- Professional layout with company branding
- Styled code box for OTP display
- Company logo (if provided)
- Support contact information
- Responsive design

**Plain Text Email:**

- Clean text format for email clients without HTML support
- All essential information included

**Template Data:**

- **Code**: 6-digit OTP
- **User Name**: Personalized greeting (optional)
- **Expiry**: 24 hours (1440 minutes)
- **Company Info**: Logo, name, support email

## Error Handling

```dart
try {
  await service.sendOtpEmail(
    email: 'user@example.com',
    otp: '123456',
  );
} on EmailServiceException catch (e) {
  print('Error: ${e.message}');

  // Access original error if needed
  if (e.originalError != null) {
    print('Original error: ${e.originalError}');
  }
}
```

### Common Errors

1. **Not Initialized**: Call `initialize()` before sending emails
2. **Invalid API Key**: Check your Forward Email API key
3. **Network Error**: Check internet connection
4. **Invalid Email**: Verify recipient email address

## Testing

### Unit Tests

The package includes comprehensive unit tests with mock support:

```bash
cd dart_cloud_backend/packages/email_service
dart test
```

### Mock Testing

```dart
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:email_service/email_service.dart';

class MockEmailService extends Mock implements EmailServiceInterface {}

void main() {
  test('should send OTP email', () async {
    final mockService = MockEmailService();

    when(
      () => mockService.sendOtpEmail(
        email: 'user@example.com',
        otp: '123456',
        userName: 'Test User',
      ),
    ).thenAnswer((_) async => true);

    final result = await mockService.sendOtpEmail(
      email: 'user@example.com',
      otp: '123456',
      userName: 'Test User',
    );

    expect(result, isTrue);
  });
}
```

## Integration with OTP Service

```dart
import 'package:otp_service/otp_service.dart';
import 'package:email_service/email_service.dart';

Future<void> sendVerificationEmail(String email) async {
  // Generate OTP
  final otpResult = OtpService.generateOtpWithHash(email: email);

  // Store hash and salt in database
  await database.storeOtp(
    email: email,
    hash: otpResult.hash,
    salt: otpResult.salt,
    createdAt: otpResult.createdAt,
  );

  // Send OTP via email
  final emailService = EmailService();
  emailService.initialize(emailConfig);

  await emailService.sendOtpEmail(
    email: email,
    otp: otpResult.otp,
  );

  emailService.close();
}
```

## API Reference

### `EmailConfig`

Configuration object for email service.

**Constructor:**

```dart
EmailConfig({
  required String apiKey,
  required String fromAddress,
  String? logo,
  String? companyName,
  String? supportEmail,
})
```

**Methods:**

- `copyWith()` - Create a copy with updated fields
- `toString()` - String representation
- `==` - Equality comparison
- `hashCode` - Hash code for collections

### `EmailService`

Main email service implementation.

**Properties:**

- `isInitialized` - Check if service is initialized

**Methods:**

#### `initialize(EmailConfig config)`

Initialize the service with configuration.

**Parameters:**

- `config` - Email configuration

#### `sendOtpEmail({required String email, required String otp, String? userName})`

Send OTP verification email.

**Parameters:**

- `email` - Recipient email address
- `otp` - 6-digit OTP code
- `userName` - Optional user name for personalization

**Returns:** `Future<bool>` - `true` if successful

**Throws:** `EmailServiceException` if sending fails

#### `close()`

Close the service and clean up resources.

### `EmailServiceInterface`

Interface for email service (useful for mocking).

**Methods:**

- `initialize(EmailConfig config)`
- `sendOtpEmail({required String email, required String otp, String? userName})`
- `close()`

### `EmailServiceException`

Custom exception for email service errors.

**Properties:**

- `message` - Error message
- `originalError` - Original error (if any)

## Environment Variables

For production use, store sensitive data in environment variables:

```env
FORWARD_EMAIL_API_KEY=your-forward-email-api-key
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
EMAIL_LOGO=https://yourdomain.com/logo.png
EMAIL_COMPANY_NAME=Your Company
EMAIL_SUPPORT_EMAIL=support@yourdomain.com
```

Load in your application:

```dart
final config = EmailConfig(
  apiKey: Platform.environment['FORWARD_EMAIL_API_KEY']!,
  fromAddress: Platform.environment['EMAIL_FROM_ADDRESS']!,
  logo: Platform.environment['EMAIL_LOGO'],
  companyName: Platform.environment['EMAIL_COMPANY_NAME'],
  supportEmail: Platform.environment['EMAIL_SUPPORT_EMAIL'],
);
```

## Best Practices

1. **Initialize Once**: Initialize the service once at application startup
2. **Reuse Instance**: Reuse the same service instance for multiple emails
3. **Close Properly**: Always call `close()` when done
4. **Error Handling**: Always wrap email sending in try-catch
5. **Configuration**: Store sensitive data in environment variables
6. **Testing**: Use mocks for unit tests to avoid sending real emails
7. **Rate Limiting**: Implement rate limiting to prevent abuse

## Example: Complete Registration Flow

```dart
import 'package:otp_service/otp_service.dart';
import 'package:email_service/email_service.dart';

class RegistrationService {
  final EmailService _emailService;

  RegistrationService(EmailConfig emailConfig)
      : _emailService = EmailService() {
    _emailService.initialize(emailConfig);
  }

  Future<void> registerUser(String email, String password) async {
    // 1. Create user in database
    final userId = await database.createUser(email, password);

    // 2. Generate OTP
    final otpResult = OtpService.generateOtpWithHash(email: email);

    // 3. Store OTP hash in database
    await database.storeOtp(
      userId: userId,
      hash: otpResult.hash,
      salt: otpResult.salt,
      createdAt: otpResult.createdAt,
    );

    // 4. Send verification email
    try {
      await _emailService.sendOtpEmail(
        email: email,
        otp: otpResult.otp,
      );
    } on EmailServiceException catch (e) {
      // Log error but don't fail registration
      print('Failed to send verification email: ${e.message}');
      // Could implement retry logic here
    }
  }

  void dispose() {
    _emailService.close();
  }
}
```

## Dependencies

- `dart_cloud_email_client_api` - Forward Email API client
- `test` - Testing framework (dev)
- `mocktail` - Mocking library (dev)

## License

Part of the ContainerPub/Dart Cloud project.
