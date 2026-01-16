import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:email_service/email_service.dart';
import 'package:dart_cloud_email_client_api/dart_cloud_email_client_api.dart';

class MockForwardEmailClient extends Mock implements ForwardEmailClient {}

class MockEmailService extends Mock implements EmailServiceInterface {}

class FakeCreateEmailRequest extends Fake implements CreateEmailRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCreateEmailRequest());
  });

  group('EmailConfig', () {
    test('should create EmailConfig with required fields', () {
      const config = EmailConfig(
        apiKey: 'test-api-key',
        fromAddress: 'noreply@example.com',
      );

      expect(config.apiKey, equals('test-api-key'));
      expect(config.fromAddress, equals('noreply@example.com'));
      expect(config.logo, isNull);
      expect(config.companyName, isNull);
      expect(config.supportEmail, isNull);
    });

    test('should create EmailConfig with all fields', () {
      const config = EmailConfig(
        apiKey: 'test-api-key',
        fromAddress: 'noreply@example.com',
        logo: 'https://example.com/logo.png',
        companyName: 'Test Company',
        supportEmail: 'support@example.com',
      );

      expect(config.apiKey, equals('test-api-key'));
      expect(config.fromAddress, equals('noreply@example.com'));
      expect(config.logo, equals('https://example.com/logo.png'));
      expect(config.companyName, equals('Test Company'));
      expect(config.supportEmail, equals('support@example.com'));
    });

    test('copyWith should create new instance with updated fields', () {
      const config = EmailConfig(
        apiKey: 'test-api-key',
        fromAddress: 'noreply@example.com',
      );

      final updated = config.copyWith(
        companyName: 'New Company',
        supportEmail: 'support@example.com',
      );

      expect(updated.apiKey, equals('test-api-key'));
      expect(updated.fromAddress, equals('noreply@example.com'));
      expect(updated.companyName, equals('New Company'));
      expect(updated.supportEmail, equals('support@example.com'));
    });

    test('copyWith should keep original values when not specified', () {
      const config = EmailConfig(
        apiKey: 'test-api-key',
        fromAddress: 'noreply@example.com',
        companyName: 'Original Company',
      );

      final updated = config.copyWith(supportEmail: 'support@example.com');

      expect(updated.apiKey, equals('test-api-key'));
      expect(updated.fromAddress, equals('noreply@example.com'));
      expect(updated.companyName, equals('Original Company'));
      expect(updated.supportEmail, equals('support@example.com'));
    });

    test('should implement equality correctly', () {
      const config1 = EmailConfig(
        apiKey: 'test-api-key',
        fromAddress: 'noreply@example.com',
        companyName: 'Test Company',
      );

      const config2 = EmailConfig(
        apiKey: 'test-api-key',
        fromAddress: 'noreply@example.com',
        companyName: 'Test Company',
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should not be equal for different values', () {
      const config1 = EmailConfig(
        apiKey: 'test-api-key',
        fromAddress: 'noreply@example.com',
      );

      const config2 = EmailConfig(
        apiKey: 'different-key',
        fromAddress: 'noreply@example.com',
      );

      expect(config1, isNot(equals(config2)));
    });

    test('toString should contain relevant information', () {
      const config = EmailConfig(
        apiKey: 'test-api-key',
        fromAddress: 'noreply@example.com',
        companyName: 'Test Company',
      );

      final str = config.toString();
      expect(str, contains('noreply@example.com'));
      expect(str, contains('Test Company'));
    });
  });

  group('EmailService - Initialization', () {
    late EmailService service;

    setUp(() {
      service = EmailService();
    });

    tearDown(() {
      service.close();
    });

    test('should not be initialized by default', () {
      expect(service.isInitialized, isFalse);
    });

    test('should be initialized after calling initialize()', () {
      const config = EmailConfig(
        apiKey: 'test-api-key',
        fromAddress: 'noreply@example.com',
      );

      service.initialize(config);

      expect(service.isInitialized, isTrue);
    });

    test('should allow re-initialization with new config', () {
      const config1 = EmailConfig(
        apiKey: 'test-api-key-1',
        fromAddress: 'noreply1@example.com',
      );

      const config2 = EmailConfig(
        apiKey: 'test-api-key-2',
        fromAddress: 'noreply2@example.com',
      );

      service.initialize(config1);
      expect(service.isInitialized, isTrue);

      service.initialize(config2);
      expect(service.isInitialized, isTrue);
    });

    test('should not be initialized after close()', () {
      const config = EmailConfig(
        apiKey: 'test-api-key',
        fromAddress: 'noreply@example.com',
      );

      service.initialize(config);
      expect(service.isInitialized, isTrue);

      service.close();
      expect(service.isInitialized, isFalse);
    });
  });

  group('EmailService - sendOtpEmail', () {
    late EmailService service;

    setUp(() {
      service = EmailService();
    });

    tearDown(() {
      service.close();
    });

    test('should throw exception when not initialized', () async {
      expect(
        () => service.sendOtpEmail(
          email: 'user@example.com',
          otp: '123456',
        ),
        throwsA(isA<EmailServiceException>()),
      );
    });

    test('should throw exception with correct message when not initialized',
        () async {
      try {
        await service.sendOtpEmail(
          email: 'user@example.com',
          otp: '123456',
        );
        fail('Should have thrown EmailServiceException');
      } on EmailServiceException catch (e) {
        expect(e.message, contains('not initialized'));
        expect(e.message, contains('initialize()'));
      }
    });
  });

  group('EmailService - Mock Tests', () {
    late MockEmailService mockService;

    setUp(() {
      mockService = MockEmailService();
    });

    test('mock service should handle successful email sending', () async {
      const config = EmailConfig(
        apiKey: 'test-api-key',
        fromAddress: 'noreply@example.com',
        companyName: 'Test Company',
      );

      when(() => mockService.initialize(config)).thenReturn(null);
      when(
        () => mockService.sendOtpEmail(
          email: 'user@example.com',
          otp: '123456',
          userName: 'Test User',
        ),
      ).thenAnswer((_) async => true);

      mockService.initialize(config);

      final result = await mockService.sendOtpEmail(
        email: 'user@example.com',
        otp: '123456',
        userName: 'Test User',
      );

      expect(result, isTrue);
      verify(() => mockService.initialize(config)).called(1);
      verify(
        () => mockService.sendOtpEmail(
          email: 'user@example.com',
          otp: '123456',
          userName: 'Test User',
        ),
      ).called(1);
    });

    test('mock service should handle email sending without userName', () async {
      when(
        () => mockService.sendOtpEmail(
          email: 'user@example.com',
          otp: '123456',
        ),
      ).thenAnswer((_) async => true);

      final result = await mockService.sendOtpEmail(
        email: 'user@example.com',
        otp: '123456',
      );

      expect(result, isTrue);
      verify(
        () => mockService.sendOtpEmail(
          email: 'user@example.com',
          otp: '123456',
        ),
      ).called(1);
    });

    test('mock service should handle email sending failure', () async {
      when(
        () => mockService.sendOtpEmail(
          email: 'invalid@example.com',
          otp: '123456',
        ),
      ).thenThrow(
        EmailServiceException('Failed to send email'),
      );

      expect(
        () => mockService.sendOtpEmail(
          email: 'invalid@example.com',
          otp: '123456',
        ),
        throwsA(isA<EmailServiceException>()),
      );
    });

    test('mock service should verify close() is called', () {
      when(() => mockService.close()).thenReturn(null);

      mockService.close();

      verify(() => mockService.close()).called(1);
    });

    test('mock service should handle multiple email sends', () async {
      when(
        () => mockService.sendOtpEmail(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          userName: any(named: 'userName'),
        ),
      ).thenAnswer((_) async => true);

      await mockService.sendOtpEmail(
        email: 'user1@example.com',
        otp: '111111',
        userName: 'User 1',
      );

      await mockService.sendOtpEmail(
        email: 'user2@example.com',
        otp: '222222',
        userName: 'User 2',
      );

      await mockService.sendOtpEmail(
        email: 'user3@example.com',
        otp: '333333',
        userName: 'User 3',
      );

      verify(
        () => mockService.sendOtpEmail(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          userName: any(named: 'userName'),
        ),
      ).called(3);
    });
  });

  group('EmailServiceException', () {
    test('should create exception with message', () {
      final exception = EmailServiceException('Test error');

      expect(exception.message, equals('Test error'));
      expect(exception.originalError, isNull);
    });

    test('should create exception with message and original error', () {
      final originalError = Exception('Original error');
      final exception = EmailServiceException('Test error', originalError);

      expect(exception.message, equals('Test error'));
      expect(exception.originalError, equals(originalError));
    });

    test('toString should contain message', () {
      final exception = EmailServiceException('Test error');

      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('EmailServiceException'));
    });
  });

  group('EmailService - Integration Scenarios', () {
    test('complete email sending flow with mock', () async {
      final mockService = MockEmailService();

      const config = EmailConfig(
        apiKey: 'test-api-key',
        fromAddress: 'noreply@example.com',
        companyName: 'Test Company',
        logo: 'https://example.com/logo.png',
        supportEmail: 'support@example.com',
      );

      when(() => mockService.initialize(config)).thenReturn(null);
      when(
        () => mockService.sendOtpEmail(
          email: 'newuser@example.com',
          otp: '123456',
          userName: 'New User',
        ),
      ).thenAnswer((_) async => true);
      when(() => mockService.close()).thenReturn(null);

      mockService.initialize(config);

      final result = await mockService.sendOtpEmail(
        email: 'newuser@example.com',
        otp: '123456',
        userName: 'New User',
      );

      expect(result, isTrue);

      mockService.close();

      verify(() => mockService.initialize(config)).called(1);
      verify(
        () => mockService.sendOtpEmail(
          email: 'newuser@example.com',
          otp: '123456',
          userName: 'New User',
        ),
      ).called(1);
      verify(() => mockService.close()).called(1);
    });

    test('should handle re-initialization scenario', () {
      final mockService = MockEmailService();

      const config1 = EmailConfig(
        apiKey: 'key-1',
        fromAddress: 'noreply1@example.com',
      );

      const config2 = EmailConfig(
        apiKey: 'key-2',
        fromAddress: 'noreply2@example.com',
      );

      when(() => mockService.initialize(any())).thenReturn(null);

      mockService.initialize(config1);
      mockService.initialize(config2);

      verify(() => mockService.initialize(config1)).called(1);
      verify(() => mockService.initialize(config2)).called(1);
    });

    test('should handle error recovery scenario', () async {
      final mockService = MockEmailService();

      when(
        () => mockService.sendOtpEmail(
          email: 'user@example.com',
          otp: '123456',
        ),
      ).thenThrow(EmailServiceException('Network error'));

      when(
        () => mockService.sendOtpEmail(
          email: 'user@example.com',
          otp: '654321',
        ),
      ).thenAnswer((_) async => true);

      expect(
        () => mockService.sendOtpEmail(
          email: 'user@example.com',
          otp: '123456',
        ),
        throwsA(isA<EmailServiceException>()),
      );

      final result = await mockService.sendOtpEmail(
        email: 'user@example.com',
        otp: '654321',
      );

      expect(result, isTrue);
    });
  });

  group('EmailService - Edge Cases', () {
    test('should handle empty email gracefully with mock', () async {
      final mockService = MockEmailService();

      when(
        () => mockService.sendOtpEmail(
          email: '',
          otp: '123456',
        ),
      ).thenThrow(EmailServiceException('Invalid email address'));

      expect(
        () => mockService.sendOtpEmail(
          email: '',
          otp: '123456',
        ),
        throwsA(isA<EmailServiceException>()),
      );
    });

    test('should handle empty OTP gracefully with mock', () async {
      final mockService = MockEmailService();

      when(
        () => mockService.sendOtpEmail(
          email: 'user@example.com',
          otp: '',
        ),
      ).thenThrow(EmailServiceException('Invalid OTP'));

      expect(
        () => mockService.sendOtpEmail(
          email: 'user@example.com',
          otp: '',
        ),
        throwsA(isA<EmailServiceException>()),
      );
    });

    test('should handle very long userName with mock', () async {
      final mockService = MockEmailService();
      final longName = 'A' * 1000;

      when(
        () => mockService.sendOtpEmail(
          email: 'user@example.com',
          otp: '123456',
          userName: longName,
        ),
      ).thenAnswer((_) async => true);

      final result = await mockService.sendOtpEmail(
        email: 'user@example.com',
        otp: '123456',
        userName: longName,
      );

      expect(result, isTrue);
    });
  });
}
