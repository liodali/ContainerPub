import 'package:database/database.dart';
import 'package:otp_service/otp_service.dart';
import 'package:email_service/email_service.dart';
import 'package:dart_cloud_backend/configuration/config.dart';

/// Email verification service for handling OTP generation, sending, and verification
class EmailVerificationService {
  static final EmailVerificationService _instance = EmailVerificationService._internal();
  factory EmailVerificationService() => _instance;
  EmailVerificationService._internal();

  final EmailService _emailService = EmailService();

  /// Initialize the email service with configuration
  void initialize() {
    final emailConfig = EmailConfig(
      apiKey: Config.emailApiKey,
      fromAddress: Config.emailFromAddress,
      logo: Config.emailLogo,
      companyName: Config.emailCompanyName,
      supportEmail: Config.emailSupportEmail,
    );
    _emailService.initialize(emailConfig);
  }

  /// Generate and send OTP for email verification
  /// Returns [true] if OTP was sent successfully, [false] otherwise
  Future<bool> sendEmailVerificationOtp({
    required String userUuid,
    required String email,
    String? userName,
  }) async {
    try {
      // Generate OTP with hash
      final otpResult = OtpService.generateOtpWithHash(email: email);

      // Store OTP in database
      final emailVerificationOtp = EmailVerificationOtpEntity(
        userUuid: userUuid,
        otpHash: otpResult.hash,
        salt: otpResult.salt,
        createdAt: otpResult.createdAt,
      );

      await DatabaseManagers.emailVerificationOtps.insert(
        emailVerificationOtp.toDBMap(),
      );

      // Send OTP email
      final emailSent = await _emailService.sendOtpEmail(
        email: email,
        otp: otpResult.otp,
        userName: userName,
      );

      return emailSent;
    } catch (e) {
      print('Error sending email verification OTP: $e');
      return false;
    }
  }

  /// Verify email OTP
  /// Returns [true] if OTP is valid, [false] otherwise
  Future<bool> verifyEmailOtp({
    required String userUuid,
    required String otp,
  }) async {
    try {
      // Get stored OTP for user
      final storedOtp = await DatabaseManagers.emailVerificationOtps.findOne(
        where: {'user_uuid': userUuid},
      );

      if (storedOtp == null) {
        return false;
      }

      // Check if OTP is expired
      if (OtpService.isOtpExpired(storedOtp.createdAt!)) {
        // Clean up expired OTP
        await DatabaseManagers.emailVerificationOtps.delete(
          where: {'user_uuid': userUuid},
        );
        return false;
      }

      // Verify OTP
      final isValid = OtpService.verifyOtp(
        otp: otp,
        storedHash: storedOtp.otpHash,
        storedSalt: storedOtp.salt,
      );

      if (isValid) {
        // Mark user email as verified
        await DatabaseManagers.users.update(
          {'is_email_verified': true},
          where: {'uuid': userUuid},
        );

        // Clean up used OTP
        await DatabaseManagers.emailVerificationOtps.delete(
          where: {'user_uuid': userUuid},
        );
      }

      return isValid;
    } catch (e) {
      print('Error verifying email OTP: $e');
      return false;
    }
  }

  /// Check if user's email is verified
  Future<bool> isEmailVerified(String userUuid) async {
    try {
      final user = await DatabaseManagers.users.findOne(
        where: {'uuid': userUuid},
      );

      return user?.isEmailVerified ?? false;
    } catch (e) {
      print('Error checking email verification status: $e');
      return false;
    }
  }

  /// Resend email verification OTP
  /// Returns [true] if OTP was resent successfully, [false] otherwise
  Future<bool> resendEmailVerificationOtp({
    required String userUuid,
    required String email,
    String? userName,
  }) async {
    try {
      // Clean up any existing OTP for this user
      await DatabaseManagers.emailVerificationOtps.delete(
        where: {'user_uuid': userUuid},
      );

      // Send new OTP
      return await sendEmailVerificationOtp(
        userUuid: userUuid,
        email: email,
        userName: userName,
      );
    } catch (e) {
      print('Error resending email verification OTP: $e');
      return false;
    }
  }

  /// Clean up expired OTPs (maintenance method)
  Future<void> cleanupExpiredOtps() async {
    try {
      // This would require a custom query to find expired OTPs
      // For now, we'll use the entity system with a timestamp filter
      final expiredTime = DateTime.now().subtract(OtpService.otpValidity);

      // Get all OTPs and filter expired ones (not optimal but works with current entity system)
      final allOtps = await DatabaseManagers.emailVerificationOtps.findAll();

      for (final otp in allOtps) {
        if (otp.createdAt != null && otp.createdAt!.isBefore(expiredTime)) {
          await DatabaseManagers.emailVerificationOtps.delete(
            where: {'user_uuid': otp.userUuid},
          );
        }
      }
    } catch (e) {
      print('Error cleaning up expired OTPs: $e');
    }
  }

  /// Close the email service
  void close() {
    _emailService.close();
  }
}
