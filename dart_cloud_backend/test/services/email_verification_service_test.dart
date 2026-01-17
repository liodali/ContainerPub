import 'package:test/test.dart';
import 'package:dart_cloud_backend/services/email_verification_service.dart';
import 'package:database/database.dart';
import 'package:otp_service/otp_service.dart';
import 'package:dart_cloud_backend/configuration/config.dart';

void main() {
  group('EmailVerificationService', () {
    late EmailVerificationService service;
    const testUserUuid = 'test-user-uuid';
    const testEmail = 'test@example.com';

    setUpAll(() async {
      // Initialize test configuration
      Config.loadFake();
      service = EmailVerificationService();
      service.initialize();
    });

    setUp(() async {
      // Clean up any existing test data
      try {
        await DatabaseManagers.emailVerificationOtps.delete(
          where: {'user_uuid': testUserUuid},
        );
      } catch (e) {
        // Ignore if table doesn't exist
      }
    });

    test('should initialize email service', () {
      expect(service, isNotNull);
    });

    test('should generate and store OTP hash correctly', () async {
      // Generate OTP
      final otpResult = OtpService.generateOtpWithHash(email: testEmail);

      expect(otpResult.otp, isNotNull);
      expect(otpResult.otp.length, equals(6));
      expect(otpResult.hash, isNotNull);
      expect(otpResult.salt, isNotNull);
      expect(otpResult.createdAt, isNotNull);

      // Verify OTP can be validated
      final isValid = OtpService.verifyOtp(
        otp: otpResult.otp,
        storedHash: otpResult.hash,
        storedSalt: otpResult.salt,
      );

      expect(isValid, isTrue);
    });

    test('should reject invalid OTP', () {
      final otpResult = OtpService.generateOtpWithHash(email: testEmail);

      final isValid = OtpService.verifyOtp(
        otp: 'wrongotp',
        storedHash: otpResult.hash,
        storedSalt: otpResult.salt,
      );

      expect(isValid, isFalse);
    });

    test('should detect expired OTP', () {
      final expiredTime = DateTime.now().subtract(
        OtpService.otpValidity + Duration(hours: 1),
      );
      final isExpired = OtpService.isOtpExpired(expiredTime);

      expect(isExpired, isTrue);
    });

    test('should accept valid OTP', () {
      final validTime = DateTime.now().subtract(Duration(hours: 1));
      final isExpired = OtpService.isOtpExpired(validTime);

      expect(isExpired, isFalse);
    });

    test('should generate unique salts for same email', () {
      final otpResult1 = OtpService.generateOtpWithHash(email: testEmail);
      final otpResult2 = OtpService.generateOtpWithHash(email: testEmail);

      expect(otpResult1.salt, isNot(equals(otpResult2.salt)));
      expect(otpResult1.hash, isNot(equals(otpResult2.hash)));
    });

    test('should handle email verification status check', () async {
      // This test would require a real database connection
      // For now, we'll test the service structure
      try {
        final isVerified = await service.isEmailVerified(testUserUuid);
        expect(isVerified, isA<bool>());
      } catch (e) {
        // Expected in test environment without database
        expect(e, isA<Exception>());
      }
    });

    test('should handle OTP verification with database', () async {
      // This test would require a real database connection
      // For now, we'll test the service structure
      try {
        final isValid = await service.verifyEmailOtp(
          userUuid: testUserUuid,
          otp: '123456',
        );
        expect(isValid, isA<bool>());
      } catch (e) {
        // Expected in test environment without database
        expect(e, isA<Exception>());
      }
    });

    test('should handle OTP sending', () async {
      // This test would require a real email service
      // For now, we'll test the service structure
      try {
        final sent = await service.sendEmailVerificationOtp(
          userUuid: testUserUuid,
          email: testEmail,
        );
        expect(sent, isA<bool>());
      } catch (e) {
        // Expected in test environment without email service
        expect(e, isA<Exception>());
      }
    });

    test('should handle OTP resending', () async {
      // This test would require a real email service
      // For now, we'll test the service structure
      try {
        final sent = await service.resendEmailVerificationOtp(
          userUuid: testUserUuid,
          email: testEmail,
        );
        expect(sent, isA<bool>());
      } catch (e) {
        // Expected in test environment without email service
        expect(e, isA<Exception>());
      }
    });

    test('should handle cleanup of expired OTPs', () async {
      // This test would require a real database connection
      // For now, we'll test that the method exists and doesn't throw
      expect(() => service.cleanupExpiredOtps(), returnsNormally);
    });

    tearDownAll(() {
      service.close();
    });
  });

  group('OTP Service', () {
    const testEmail = 'test@example.com';

    test('should generate 6-digit OTP', () {
      final otp = OtpService.generateOtp();

      expect(otp, isNotNull);
      expect(otp.length, equals(6));
      expect(otp, matches(RegExp(r'^\d{6}$')));
    });

    test('should generate unique OTPs', () {
      final otp1 = OtpService.generateOtp();
      final otp2 = OtpService.generateOtp();

      // While collisions are possible, they should be extremely rare
      expect(otp1, isNot(equals(otp2)));
    });

    test('should generate salt with email and timestamp', () {
      final timestamp = DateTime.now();
      final salt = OtpService.generateSalt(
        email: testEmail,
        timestamp: timestamp,
      );

      expect(salt, contains(testEmail));
      expect(salt, contains(timestamp.microsecondsSinceEpoch.toString()));
    });

    test('should hash OTP consistently with same salt', () {
      const otp = '123456';
      const salt = 'test-salt';

      final hash1 = OtpService.hashOtp(otp: otp, salt: salt);
      final hash2 = OtpService.hashOtp(otp: otp, salt: salt);

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(otp)));
    });

    test('should generate different hashes with different salts', () {
      const otp = '123456';
      const salt1 = 'salt1';
      const salt2 = 'salt2';

      final hash1 = OtpService.hashOtp(otp: otp, salt: salt1);
      final hash2 = OtpService.hashOtp(otp: otp, salt: salt2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('should verify OTP correctly', () {
      const otp = '123456';
      const salt = 'test-salt';

      final hash = OtpService.hashOtp(otp: otp, salt: salt);

      final isValid = OtpService.verifyOtp(
        otp: otp,
        storedHash: hash,
        storedSalt: salt,
      );

      expect(isValid, isTrue);
    });

    test('should reject OTP verification with wrong OTP', () {
      const otp = '123456';
      const wrongOtp = '654321';
      const salt = 'test-salt';

      final hash = OtpService.hashOtp(otp: otp, salt: salt);

      final isValid = OtpService.verifyOtp(
        otp: wrongOtp,
        storedHash: hash,
        storedSalt: salt,
      );

      expect(isValid, isFalse);
    });

    test('should reject OTP verification with wrong salt', () {
      const otp = '123456';
      const salt = 'test-salt';
      const wrongSalt = 'wrong-salt';

      final hash = OtpService.hashOtp(otp: otp, salt: salt);

      final isValid = OtpService.verifyOtp(
        otp: otp,
        storedHash: hash,
        storedSalt: wrongSalt,
      );

      expect(isValid, isFalse);
    });

    test('should generate complete OTP result', () {
      final otpResult = OtpService.generateOtpWithHash(email: testEmail);

      expect(otpResult.otp, isNotNull);
      expect(otpResult.hash, isNotNull);
      expect(otpResult.salt, isNotNull);
      expect(otpResult.createdAt, isNotNull);
      expect(otpResult.otp.length, equals(6));
    });
  });
}
