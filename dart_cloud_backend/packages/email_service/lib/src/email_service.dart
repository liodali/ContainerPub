import 'package:dart_cloud_email_client_api/dart_cloud_email_client_api.dart';
import 'email_config.dart';
import 'email_service_interface.dart';

class EmailServiceException implements Exception {
  final String message;
  final dynamic originalError;

  EmailServiceException(this.message, [this.originalError]);

  @override
  String toString() => 'EmailServiceException: $message';
}

class EmailService implements EmailServiceInterface {
  ForwardEmailClient? _client;
  EmailConfig? _config;

  bool get isInitialized => _client != null && _config != null;

  @override
  void initialize(EmailConfig config) {
    _config = config;
    _client = ForwardEmailClient(apiKey: config.apiKey);
  }

  @override
  Future<bool> sendOtpEmail({
    required String email,
    required String otp,
    String? userName,
  }) async {
    if (!isInitialized) {
      throw EmailServiceException(
        'EmailService not initialized. Call initialize() first.',
      );
    }

    try {
      final templateData = TemplateData(
        logo: _config!.logo,
        companyName: _config!.companyName,
        year: DateTime.now().year.toString(),
        supportEmail: _config!.supportEmail,
      );

      final template = PasswordCodeTemplate(
        data: templateData,
        code: otp,
        userName: userName ?? 'User',
        expiryMinutes: 1440,
      );

      await _client!.createEmail(
        CreateEmailRequest.fromTemplate(
          from: _config!.fromAddress,
          to: [email],
          subject: 'Verify your email address',
          template: template,
        ),
      );

      return true;
    } on ForwardEmailException catch (e) {
      throw EmailServiceException(
        'Failed to send OTP email: ${e.message}',
        e,
      );
    } catch (e) {
      throw EmailServiceException(
        'Unexpected error sending OTP email',
        e,
      );
    }
  }

  @override
  void close() {
    _client?.close();
    _client = null;
    _config = null;
  }
}
