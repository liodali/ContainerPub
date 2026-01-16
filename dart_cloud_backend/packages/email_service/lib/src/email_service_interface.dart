import 'email_config.dart';

abstract class EmailServiceInterface {
  void initialize(EmailConfig config);

  Future<bool> sendOtpEmail({
    required String email,
    required String otp,
    String? userName,
  });

  void close();
}
