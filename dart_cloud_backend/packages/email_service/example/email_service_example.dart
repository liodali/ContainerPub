import 'package:email_service/email_service.dart';

void main() async {
  print('=== Email Service Example ===\n');

  print('1. Create EmailConfig');
  const config = EmailConfig(
    apiKey: 'your-forward-email-api-key',
    fromAddress: 'noreply@example.com',
    companyName: 'Dart Cloud',
    logo: 'https://example.com/logo.png',
    supportEmail: 'support@example.com',
  );
  print('   Config created: ${config.fromAddress}\n');

  print('2. Initialize EmailService');
  final service = EmailService();
  print('   Is initialized: ${service.isInitialized}');
  service.initialize(config);
  print('   Is initialized: ${service.isInitialized}\n');

  print('3. Send OTP Email (simulated)');
  print('   Note: This would send a real email if API key is valid');
  print('   Email: user@example.com');
  print('   OTP: 123456');
  print('   User Name: John Doe\n');

  print('4. Update Configuration');
  final updatedConfig = config.copyWith(
    companyName: 'Updated Company Name',
  );
  print('   Original: ${config.companyName}');
  print('   Updated: ${updatedConfig.companyName}\n');

  print('5. Close Service');
  service.close();
  print('   Is initialized: ${service.isInitialized}\n');

  print('=== Complete Registration Flow Example ===\n');

  print('Scenario: User registers with email verification');
  const userEmail = 'newuser@example.com';
  const otp = '654321';

  print('Step 1: User submits registration form');
  print('   Email: $userEmail\n');

  print('Step 2: Initialize email service');
  final emailService = EmailService();
  emailService.initialize(config);
  print('   Service initialized\n');

  print('Step 3: Generate OTP (using OTP Service)');
  print('   Generated OTP: $otp');
  print('   Store hash and salt in database\n');

  print('Step 4: Send verification email');
  print('   Sending to: $userEmail');
  print('   OTP: $otp');
  print('   Template: PasswordCodeTemplate');
  print('   Expiry: 24 hours (1440 minutes)\n');

  print('Step 5: Email sent successfully');
  print('   User will receive professional email with:');
  print('   - Company logo and branding');
  print('   - Styled OTP code box');
  print('   - Expiry information');
  print('   - Support contact\n');

  print('Step 6: Clean up');
  emailService.close();
  print('   Service closed\n');

  print('=== Error Handling Example ===\n');

  print('Example 1: Service not initialized');
  final uninitializedService = EmailService();
  try {
    await uninitializedService.sendOtpEmail(
      email: 'user@example.com',
      otp: '123456',
    );
  } on EmailServiceException catch (e) {
    print('   ✓ Caught exception: ${e.message}\n');
  }

  print('Example 2: Configuration management');
  const config1 = EmailConfig(
    apiKey: 'key-1',
    fromAddress: 'noreply1@example.com',
  );
  const config2 = EmailConfig(
    apiKey: 'key-2',
    fromAddress: 'noreply2@example.com',
  );
  print('   Config 1: ${config1.fromAddress}');
  print('   Config 2: ${config2.fromAddress}');
  print('   Are equal: ${config1 == config2}\n');

  print('=== Mock Testing Example ===\n');
  print('For testing, use MockEmailService:');
  print('''
  class MockEmailService extends Mock implements EmailServiceInterface {}
  
  test('should send OTP email', () async {
    final mockService = MockEmailService();
    
    when(() => mockService.sendOtpEmail(
      email: 'user@example.com',
      otp: '123456',
    )).thenAnswer((_) async => true);
    
    final result = await mockService.sendOtpEmail(
      email: 'user@example.com',
      otp: '123456',
    );
    
    expect(result, isTrue);
  });
  ''');

  print('\n=== Integration with OTP Service ===\n');
  print('''
  // Generate OTP
  final otpResult = OtpService.generateOtpWithHash(email: email);
  
  // Store in database
  await database.storeOtp(
    hash: otpResult.hash,
    salt: otpResult.salt,
    createdAt: otpResult.createdAt,
  );
  
  // Send email
  await emailService.sendOtpEmail(
    email: email,
    otp: otpResult.otp,
  );
  ''');

  print('\n=== Best Practices ===\n');
  print('1. Initialize service once at application startup');
  print('2. Reuse the same service instance');
  print('3. Always call close() when done');
  print('4. Use try-catch for error handling');
  print('5. Store API keys in environment variables');
  print('6. Use mocks for unit tests');
  print('7. Implement rate limiting');
}
