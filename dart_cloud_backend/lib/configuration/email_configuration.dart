import 'dart:io';
import 'package:dotenv/dotenv.dart';

class EmailConfiguration {
  static late String emailApiKey;
  static late String emailFromAddress;
  static late String emailLogo;
  static late String emailCompanyName;
  static late String emailSupportEmail;

  static Future<void> load(DotEnv env) async {
    emailApiKey = env['EMAIL_API_KEY'] ?? Platform.environment['EMAIL_API_KEY'] ?? '';
    emailFromAddress =
        env['EMAIL_FROM_ADDRESS'] ??
        Platform.environment['EMAIL_FROM_ADDRESS'] ??
        'noreply@dartcloud.dev';
    emailLogo =
        env['EMAIL_LOGO'] ??
        Platform.environment['EMAIL_LOGO'] ??
        'https://dartcloud.dev/logo.png';
    emailCompanyName =
        env['EMAIL_COMPANY_NAME'] ??
        Platform.environment['EMAIL_COMPANY_NAME'] ??
        'DartCloud';
    emailSupportEmail =
        env['EMAIL_SUPPORT_EMAIL'] ??
        Platform.environment['EMAIL_SUPPORT_EMAIL'] ??
        'support@dartcloud.dev';
  }

  static void loadFake() {
    emailApiKey = '';
    emailFromAddress = 'noreply@dartcloud.dev';
    emailLogo = 'https://dartcloud.dev/logo.png';
    emailCompanyName = 'DartCloud';
    emailSupportEmail = 'support@dartcloud.dev';
  }
}
