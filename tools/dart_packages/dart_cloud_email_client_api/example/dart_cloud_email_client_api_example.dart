import 'package:dart_cloud_email_client_api/dart_cloud_email_client_api.dart';

void main() async {
  final client = ForwardEmailClient(
    apiKey: 'YOUR_API_KEY',
  );

  try {
    final emails = await client.listEmails(
      ListEmailsParams(
        limit: '10',
        sort: '-created_at',
      ),
    );

    print('Found ${emails.length} emails:');
    for (final email in emails) {
      print('  - ${email.subject} (${email.status})');
    }

    final templateData = TemplateData(
      logo: 'https://example.com/logo.png',
      companyName: 'My Company',
      year: '2025',
      supportEmail: 'support@example.com',
    );

    final passwordTemplate = PasswordCodeTemplate(
      data: templateData,
      code: '123456',
      userName: 'John Doe',
      expiryMinutes: 10,
    );

    final response = await client.createEmail(
      CreateEmailRequest.fromTemplate(
        from: 'sender@yourdomain.com',
        to: ['recipient@example.com'],
        subject: 'Your Verification Code',
        template: passwordTemplate,
        messageId: 'unique-message-id-123',
      ),
    );

    print('Email sent: ${response.message}');

    final simpleResponse = await client.createEmail(
      CreateEmailRequest(
        from: 'sender@yourdomain.com',
        to: ['recipient@example.com'],
        subject: 'Hello from Forward Email API',
        bodyTxt: 'This is a test email sent via the Forward Email API.',
        bodyHtml:
            '<p>This is a <strong>test email</strong> sent via the Forward Email API.</p>',
        messageId: 'custom-message-id-456',
      ),
    );

    print('Simple email sent: ${simpleResponse.message}');
  } on ForwardEmailException catch (e) {
    print('Error: ${e.message} (status: ${e.statusCode})');
  } finally {
    client.close();
  }
}
