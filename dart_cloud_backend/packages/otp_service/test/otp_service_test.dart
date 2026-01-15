import 'package:test/test.dart';
import 'package:otp_service/otp_service.dart';

void main() {
  group('OtpService - OTP Generation', () {
    test('generateOtp should return 6-digit numeric string', () {
      final otp = OtpService.generateOtp();

      expect(otp, hasLength(6));
      expect(int.tryParse(otp), isNotNull);
      expect(int.parse(otp), greaterThanOrEqualTo(0));
      expect(int.parse(otp), lessThan(1000000));
    });

    test('generateOtp should generate unique OTPs', () {
      final otps = <String>{};

      for (var i = 0; i < 100; i++) {
        final otp = OtpService.generateOtp();
        otps.add(otp);
      }

      expect(otps.length, greaterThan(90));
    });

    test('generateOtp should pad with leading zeros', () {
      final otps = <String>[];

      for (var i = 0; i < 1000; i++) {
        final otp = OtpService.generateOtp();
        otps.add(otp);
      }

      final paddedOtps = otps.where((otp) => otp.startsWith('0'));
      expect(paddedOtps, isNotEmpty);
    });
  });

  group('OtpService - Salt Generation', () {
    test('generateSalt should combine timestamp and email', () {
      final email = 'test@example.com';
      final timestamp = DateTime(2024, 1, 15, 0, 0, 0);

      final salt = OtpService.generateSalt(
        email: email,
        timestamp: timestamp,
      );

      expect(salt, contains(':'));
      expect(salt, contains(email));
      expect(salt, contains(timestamp.microsecondsSinceEpoch.toString()));
    });

    test('generateSalt should produce different salts for different timestamps',
        () {
      final email = 'test@example.com';
      final timestamp1 = DateTime(2024, 1, 15, 12, 30, 45);
      final timestamp2 = DateTime(2024, 1, 15, 12, 30, 46);

      final salt1 =
          OtpService.generateSalt(email: email, timestamp: timestamp1);
      final salt2 =
          OtpService.generateSalt(email: email, timestamp: timestamp2);

      expect(salt1, isNot(equals(salt2)));
    });

    test('generateSalt should produce different salts for different emails',
        () {
      final timestamp = DateTime(2024, 1, 15, 12, 30, 45);
      final email1 = 'user1@example.com';
      final email2 = 'user2@example.com';

      final salt1 =
          OtpService.generateSalt(email: email1, timestamp: timestamp);
      final salt2 =
          OtpService.generateSalt(email: email2, timestamp: timestamp);

      expect(salt1, isNot(equals(salt2)));
    });

    test('generateSalt should have correct format', () {
      final email = 'test@example.com';
      final timestamp = DateTime.now();

      final salt = OtpService.generateSalt(email: email, timestamp: timestamp);
      final parts = salt.split(':');

      expect(parts, hasLength(2));
      expect(int.tryParse(parts[0]), isNotNull);
      expect(parts[1], equals(email));
    });
  });

  group('OtpService - OTP Hashing', () {
    test('hashOtp should produce consistent hash for same inputs', () {
      const otp = '123456';
      const salt = '1705324245000000:test@example.com';

      final hash1 = OtpService.hashOtp(otp: otp, salt: salt);
      final hash2 = OtpService.hashOtp(otp: otp, salt: salt);

      expect(hash1, equals(hash2));
    });

    test('hashOtp should produce different hashes for different OTPs', () {
      const salt = '1705324245000000:test@example.com';

      final hash1 = OtpService.hashOtp(otp: '123456', salt: salt);
      final hash2 = OtpService.hashOtp(otp: '654321', salt: salt);

      expect(hash1, isNot(equals(hash2)));
    });

    test('hashOtp should produce different hashes for different salts', () {
      const otp = '123456';

      final hash1 = OtpService.hashOtp(
        otp: otp,
        salt: '1705324245000000:user1@example.com',
      );
      final hash2 = OtpService.hashOtp(
        otp: otp,
        salt: '1705324245000000:user2@example.com',
      );

      expect(hash1, isNot(equals(hash2)));
    });

    test('hashOtp should produce valid SHA-256 hash format', () {
      const otp = '123456';
      const salt = '1705324245000000:test@example.com';

      final hash = OtpService.hashOtp(otp: otp, salt: salt);

      expect(hash, hasLength(64));
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash), isTrue);
    });
  });

  group('OtpService - OTP Verification', () {
    test('verifyOtp should return true for correct OTP', () {
      const otp = '123456';
      const salt = '1705324245000000:test@example.com';
      final hash = OtpService.hashOtp(otp: otp, salt: salt);

      final isValid = OtpService.verifyOtp(
        otp: otp,
        storedHash: hash,
        storedSalt: salt,
      );

      expect(isValid, isTrue);
    });

    test('verifyOtp should return false for incorrect OTP', () {
      const correctOtp = '123456';
      const incorrectOtp = '654321';
      const salt = '1705324245000000:test@example.com';
      final hash = OtpService.hashOtp(otp: correctOtp, salt: salt);

      final isValid = OtpService.verifyOtp(
        otp: incorrectOtp,
        storedHash: hash,
        storedSalt: salt,
      );

      expect(isValid, isFalse);
    });

    test('verifyOtp should return false for incorrect salt', () {
      const otp = '123456';
      const correctSalt = '1705324245000000:test@example.com';
      const incorrectSalt = '1705324245000000:other@example.com';
      final hash = OtpService.hashOtp(otp: otp, salt: correctSalt);

      final isValid = OtpService.verifyOtp(
        otp: otp,
        storedHash: hash,
        storedSalt: incorrectSalt,
      );

      expect(isValid, isFalse);
    });

    test('verifyOtp should be case-sensitive for hash', () {
      const otp = '123456';
      const salt = '1705324245000000:test@example.com';
      final hash = OtpService.hashOtp(otp: otp, salt: salt);
      final uppercaseHash = hash.toUpperCase();

      final isValid = OtpService.verifyOtp(
        otp: otp,
        storedHash: uppercaseHash,
        storedSalt: salt,
      );

      expect(isValid, isFalse);
    });
  });

  group('OtpService - OTP Expiry', () {
    test('isOtpExpired should return false for recent OTP', () {
      final createdAt = DateTime.now().subtract(const Duration(hours: 1));

      final isExpired = OtpService.isOtpExpired(createdAt);

      expect(isExpired, isFalse);
    });

    test('isOtpExpired should return false for OTP at 23 hours 59 minutes', () {
      final createdAt = DateTime.now().subtract(
        const Duration(hours: 23, minutes: 59),
      );

      final isExpired = OtpService.isOtpExpired(createdAt);

      expect(isExpired, isFalse);
    });

    test('isOtpExpired should return true for OTP older than 24 hours', () {
      final createdAt = DateTime.now().subtract(
        const Duration(hours: 24, minutes: 1),
      );

      final isExpired = OtpService.isOtpExpired(createdAt);

      expect(isExpired, isTrue);
    });

    test('isOtpExpired should return true for OTP exactly 24 hours old', () {
      final createdAt = DateTime.now().subtract(const Duration(hours: 24));

      final isExpired = OtpService.isOtpExpired(createdAt);

      expect(isExpired, isTrue);
    });

    test('isOtpExpired should return true for very old OTP', () {
      final createdAt = DateTime.now().subtract(const Duration(days: 30));

      final isExpired = OtpService.isOtpExpired(createdAt);

      expect(isExpired, isTrue);
    });
  });

  group('OtpService - generateOtpWithHash', () {
    test('generateOtpWithHash should return complete OtpResult', () {
      const email = 'test@example.com';

      final result = OtpService.generateOtpWithHash(email: email);

      expect(result.otp, hasLength(6));
      expect(int.tryParse(result.otp), isNotNull);
      expect(result.hash, hasLength(64));
      expect(result.salt, contains(email));
      expect(result.createdAt, isNotNull);
    });

    test('generateOtpWithHash should use provided timestamp', () {
      const email = 'test@example.com';
      final timestamp = DateTime(2024, 1, 15, 12, 30, 45);

      final result = OtpService.generateOtpWithHash(
        email: email,
        timestamp: timestamp,
      );

      expect(result.createdAt, equals(timestamp));
      expect(
          result.salt, contains(timestamp.microsecondsSinceEpoch.toString()));
    });

    test(
        'generateOtpWithHash should use current time when timestamp not provided',
        () {
      const email = 'test@example.com';
      final before = DateTime.now();

      final result = OtpService.generateOtpWithHash(email: email);

      final after = DateTime.now();

      expect(
        result.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        result.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('generateOtpWithHash result should be verifiable', () {
      const email = 'test@example.com';

      final result = OtpService.generateOtpWithHash(email: email);

      final isValid = OtpService.verifyOtp(
        otp: result.otp,
        storedHash: result.hash,
        storedSalt: result.salt,
      );

      expect(isValid, isTrue);
    });

    test('generateOtpWithHash should generate unique results', () {
      const email = 'test@example.com';

      final result1 = OtpService.generateOtpWithHash(email: email);
      final result2 = OtpService.generateOtpWithHash(email: email);

      expect(result1.otp, isNot(equals(result2.otp)));
      expect(result1.hash, isNot(equals(result2.hash)));
      expect(result1.salt, isNot(equals(result2.salt)));
    });
  });

  group('OtpService - Integration Tests', () {
    test('complete OTP lifecycle should work correctly', () {
      const email = 'user@example.com';

      final result = OtpService.generateOtpWithHash(email: email);

      final isValidOtp = OtpService.verifyOtp(
        otp: result.otp,
        storedHash: result.hash,
        storedSalt: result.salt,
      );
      expect(isValidOtp, isTrue);

      final isExpired = OtpService.isOtpExpired(result.createdAt);
      expect(isExpired, isFalse);

      final isInvalidOtp = OtpService.verifyOtp(
        otp: '000000',
        storedHash: result.hash,
        storedSalt: result.salt,
      );
      expect(isInvalidOtp, isFalse);
    });

    test('expired OTP should still verify correctly but be marked expired', () {
      const email = 'user@example.com';
      final oldTimestamp = DateTime.now().subtract(const Duration(hours: 25));

      final result = OtpService.generateOtpWithHash(
        email: email,
        timestamp: oldTimestamp,
      );

      final isValidOtp = OtpService.verifyOtp(
        otp: result.otp,
        storedHash: result.hash,
        storedSalt: result.salt,
      );
      expect(isValidOtp, isTrue);

      final isExpired = OtpService.isOtpExpired(result.createdAt);
      expect(isExpired, isTrue);
    });

    test('same OTP for different users should have different hashes', () {
      final timestamp = DateTime.now();
      const email1 = 'user1@example.com';
      const email2 = 'user2@example.com';

      final result1 = OtpService.generateOtpWithHash(
        email: email1,
        timestamp: timestamp,
      );
      final result2 = OtpService.generateOtpWithHash(
        email: email2,
        timestamp: timestamp,
      );

      if (result1.otp == result2.otp) {
        expect(result1.hash, isNot(equals(result2.hash)));
        expect(result1.salt, isNot(equals(result2.salt)));
      }
    });
  });

  group('OtpService - Constants', () {
    test('otpLength should be 6', () {
      expect(OtpService.otpLength, equals(6));
    });

    test('otpValidity should be 24 hours', () {
      expect(OtpService.otpValidity, equals(const Duration(hours: 24)));
    });
  });

  group('OtpResult', () {
    test('should create OtpResult with all fields', () {
      final createdAt = DateTime.now();
      final result = OtpResult(
        otp: '123456',
        hash: 'abc123',
        salt: 'salt123',
        createdAt: createdAt,
      );

      expect(result.otp, equals('123456'));
      expect(result.hash, equals('abc123'));
      expect(result.salt, equals('salt123'));
      expect(result.createdAt, equals(createdAt));
    });

    test('should implement equality correctly', () {
      final createdAt = DateTime.now();
      final result1 = OtpResult(
        otp: '123456',
        hash: 'abc123',
        salt: 'salt123',
        createdAt: createdAt,
      );
      final result2 = OtpResult(
        otp: '123456',
        hash: 'abc123',
        salt: 'salt123',
        createdAt: createdAt,
      );

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test('should not be equal for different values', () {
      final createdAt = DateTime.now();
      final result1 = OtpResult(
        otp: '123456',
        hash: 'abc123',
        salt: 'salt123',
        createdAt: createdAt,
      );
      final result2 = OtpResult(
        otp: '654321',
        hash: 'abc123',
        salt: 'salt123',
        createdAt: createdAt,
      );

      expect(result1, isNot(equals(result2)));
    });

    test('toString should contain all fields', () {
      final createdAt = DateTime.now();
      final result = OtpResult(
        otp: '123456',
        hash: 'abc123',
        salt: 'salt123',
        createdAt: createdAt,
      );

      final str = result.toString();
      expect(str, contains('123456'));
      expect(str, contains('abc123'));
      expect(str, contains('salt123'));
    });
  });
}
