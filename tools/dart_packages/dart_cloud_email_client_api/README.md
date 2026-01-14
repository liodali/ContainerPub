# Forward Email API Client for Dart

A comprehensive Dart client for the [Forward Email API](https://forwardemail.net) built with Dio. This package provides a clean, type-safe interface for sending emails and managing email operations.

## Features

- 🚀 **Modern HTTP Client**: Built with Dio for robust HTTP requests
- 🔐 **Simple Authentication**: Basic Auth with API key support
- 📧 **Email Operations**: List sent emails and create new emails
- 🎨 **Email Templates**: Built-in templates for common email types
  - Password verification codes
  - Welcome emails
  - Password reset emails
- 📱 **Responsive Templates**: Professional HTML emails with text fallbacks
- 🛡️ **Type Safety**: Full Dart type safety with comprehensive models
- 🧪 **Well Tested**: Complete unit test coverage
- 📦 **Lightweight**: Minimal dependencies

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  dart_cloud_email_client_api: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Getting Started

1. **Get your API Key** from [Forward Email](https://forwardemail.net)
2. **Initialize the client** with your API key
3. **Start sending emails!**

## Usage

### Basic Email Sending

```dart
import 'package:dart_cloud_email_client_api/dart_cloud_email_client_api.dart';

void main() async {
  final client = ForwardEmailClient(apiKey: 'YOUR_API_KEY');

  try {
    // Send a simple email with plain text
    final response = await client.createEmail(
      CreateEmailRequest(
        from: 'sender@yourdomain.com',
        to: ['recipient@example.com'],
        subject: 'Hello from Forward Email API',
        bodyTxt: 'This is a plain text email.',
        messageId: 'custom-message-id-123',
      ),
    );

    print('Email sent: ${response.message}');

    // Or send with HTML
    final htmlResponse = await client.createEmail(
      CreateEmailRequest(
        from: 'sender@yourdomain.com',
        to: ['recipient@example.com'],
        subject: 'Hello from Forward Email API',
        bodyHtml: '<p>This is an <strong>HTML email</strong>.</p>',
        messageId: 'custom-message-id-456',
      ),
    );

    print('HTML email sent: ${htmlResponse.message}');
  } on ForwardEmailException catch (e) {
    print('Error: ${e.message} (status: ${e.statusCode})');
  } finally {
    client.close();
  }
}
```

**Important**: You must provide either `bodyTxt` (plain text) OR `bodyHtml` (HTML), not both. Alternatively, you can provide `raw` for a custom RFC822 formatted email.

### Using Email Templates

```dart
void main() async {
  final client = ForwardEmailClient(apiKey: 'YOUR_API_KEY');

  // Configure template data
  final templateData = TemplateData(
    logo: 'https://yourcompany.com/logo.png',
    companyName: 'Your Company',
    year: '2025',
    supportEmail: 'support@yourcompany.com',
  );

  // Send password verification code
  final passwordTemplate = PasswordCodeTemplate(
    data: templateData,
    code: '123456',
    userName: 'John Doe',
    expiryMinutes: 10,
  );

  await client.createEmail(
    CreateEmailRequest.fromTemplate(
      from: 'noreply@yourcompany.com',
      to: ['user@example.com'],
      subject: 'Your Verification Code',
      template: passwordTemplate,
      messageId: 'verification-123',
    ),
  );

  // Send welcome email
  final welcomeTemplate = WelcomeTemplate(
    data: templateData,
    userName: 'Jane Smith',
    actionUrl: 'https://yourapp.com/dashboard',
    actionText: 'Get Started',
  );

  await client.createEmail(
    CreateEmailRequest.fromTemplate(
      from: 'welcome@yourcompany.com',
      to: ['newuser@example.com'],
      subject: 'Welcome to Your Company!',
      template: welcomeTemplate,
    ),
  );

  client.close();
}
```

### Listing Sent Emails

```dart
void main() async {
  final client = ForwardEmailClient(apiKey: 'YOUR_API_KEY');

  try {
    // List emails with pagination and filtering
    final emails = await client.listEmails(
      ListEmailsParams(
        limit: '10',
        sort: '-created_at',
        domain: 'yourdomain.com',
      ),
    );

    print('Found ${emails.length} emails:');
    for (final email in emails) {
      print('- ${email.subject} (${email.status}) sent to ${email.accepted?.join(', ')}');
    }
  } on ForwardEmailException catch (e) {
    print('Error: ${e.message}');
  } finally {
    client.close();
  }
}
```

### Advanced Email Options

```dart
final advancedEmail = CreateEmailRequest(
  from: 'sender@yourdomain.com',
  to: ['primary@example.com'],
  cc: ['cc@example.com'],
  bcc: ['bcc@example.com'],
  subject: 'Advanced Email',
  bodyHtml: '<p>HTML content with <strong>formatting</strong></p>',
  sender: 'actual-sender@yourdomain.com',
  replyTo: 'replies@yourdomain.com',
  priority: EmailPriority.high,
  requireTLS: true,
  messageId: 'custom-message-id',
  date: DateTime.now(),
);

final response = await client.createEmail(advancedEmail);
```

**Note**: Choose either `bodyTxt` or `bodyHtml`, not both. Use `bodyTxt` for plain text emails and `bodyHtml` for HTML-formatted emails.

## API Reference

### ForwardEmailClient

The main client class for interacting with the Forward Email API.

#### Constructor

```dart
ForwardEmailClient({
  required String apiKey,
  String? baseUrl,  // Defaults to 'https://api.forwardemail.net'
  Dio? dio,        // Custom Dio instance for testing/configuration
})
```

#### Methods

- `Future<List<Email>> listEmails([ListEmailsParams? params])` - List sent emails
- `Future<CreateEmailResponse> createEmail(CreateEmailRequest request)` - Send an email
- `void close()` - Close the underlying Dio client

### Models

#### Email

Represents a sent email from the Forward Email API.

#### CreateEmailRequest

Request model for sending emails. Use the `fromTemplate()` factory for template-based emails.

#### ListEmailsParams

Query parameters for the `listEmails()` method.

### Templates

#### EmailTemplate

Abstract base class for email templates.

#### PasswordCodeTemplate

Template for sending verification codes.

#### WelcomeTemplate

Template for welcome/onboarding emails.

#### ResetPasswordTemplate

Template for password reset emails.

## Error Handling

The package throws `ForwardEmailException` for API errors:

```dart
try {
  await client.createEmail(request);
} on ForwardEmailException catch (e) {
  print('API Error: ${e.message}');
  print('Status Code: ${e.statusCode}');
  print('Response Data: ${e.data}');
}
```

## Testing

The package includes comprehensive unit tests. Run them with:

```bash
dart test
```

## Example

See the `/example` directory for a complete working example.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

- 📧 Email: support@forwardemail.net
- 📖 Documentation: https://forwardemail.net/docs
- 🐛 Issues: [GitHub Issues](https://github.com/your-repo/issues)
