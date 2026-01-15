import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'otp_result.dart';

class OtpService {
  static const int otpLength = 6;
  static const Duration otpValidity = Duration(hours: 24);

  OtpService._();

  static String generateOtp() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random.secure();

    final seed = timestamp + random.nextInt(999999);
    final otp = (seed % 1000000).toString().padLeft(6, '0');

    return otp;
  }

  static String generateSalt({
    required String email,
    required DateTime timestamp,
  }) {
    return '${timestamp.microsecondsSinceEpoch}:$email';
  }

  static String hashOtp({
    required String otp,
    required String salt,
  }) {
    final hmac = Hmac(sha256, utf8.encode(salt));
    final digest = hmac.convert(utf8.encode(otp));
    return digest.toString();
  }

  static bool verifyOtp({
    required String otp,
    required String storedHash,
    required String storedSalt,
  }) {
    final computedHash = hashOtp(
      otp: otp,
      salt: storedSalt,
    );
    return computedHash == storedHash;
  }

  static bool isOtpExpired(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference > otpValidity;
  }

  static OtpResult generateOtpWithHash({
    required String email,
    DateTime? timestamp,
  }) {
    final createdAt = timestamp ?? DateTime.now();
    final otp = generateOtp();
    final salt = generateSalt(email: email, timestamp: createdAt);
    final hash = hashOtp(otp: otp, salt: salt);

    return OtpResult(
      otp: otp,
      hash: hash,
      salt: salt,
      createdAt: createdAt,
    );
  }
}
