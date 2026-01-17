import 'dart:convert';
import 'package:database/database.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_cloud_backend/services/email_verification_service.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dart_cloud_backend/configuration/config.dart';

/// Handler for email verification endpoints
class EmailVerificationHandler {
  static final EmailVerificationService _emailService = EmailVerificationService();

  /// Send email verification OTP
  static Future<Response> sendVerificationOtp(Request request) async {
    try {
      // Get user from JWT token
      final token = request.headers['authorization']?.split('Bearer ').last;
      if (token == null) {
        return Response.unauthorized(
          jsonEncode({'error': 'No token provided'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final jwt = JWT.verify(token, SecretKey(Config.jwtSecret));
      final userUuid = jwt.payload['userId'] as String;

      // Get user details
      final user = await DatabaseManagers.users.findOne(
        where: {'uuid': userUuid},
      );

      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if email is already verified
      if (user.isEmailVerified) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Email is already verified'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Initialize email service if needed
      _emailService.initialize();

      // Send OTP
      final sent = await _emailService.sendEmailVerificationOtp(
        userUuid: userUuid,
        email: user.email,
      );

      if (sent) {
        return Response.ok(
          jsonEncode({'message': 'Verification OTP sent to your email'}),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to send verification OTP'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      print('Error sending verification OTP: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to send verification OTP'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Verify email OTP
  static Future<Response> verifyOtp(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final otp = body['otp'] as String?;

      if (otp == null || otp.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'OTP is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get user from JWT token
      final token = request.headers['authorization']?.split('Bearer ').last;
      if (token == null) {
        return Response.unauthorized(
          jsonEncode({'error': 'No token provided'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final jwt = JWT.verify(token, SecretKey(Config.jwtSecret));
      final userUuid = jwt.payload['userId'] as String;

      // Verify OTP
      final isValid = await _emailService.verifyEmailOtp(
        userUuid: userUuid,
        otp: otp,
      );

      if (isValid) {
        return Response.ok(
          jsonEncode({'message': 'Email verified successfully'}),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid or expired OTP'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to verify OTP'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Resend email verification OTP
  static Future<Response> resendVerificationOtp(Request request) async {
    try {
      // Get user from JWT token
      final token = request.headers['authorization']?.split('Bearer ').last;
      if (token == null) {
        return Response.unauthorized(
          jsonEncode({'error': 'No token provided'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final jwt = JWT.verify(token, SecretKey(Config.jwtSecret));
      final userUuid = jwt.payload['userId'] as String;

      // Get user details
      final user = await DatabaseManagers.users.findOne(
        where: {'uuid': userUuid},
      );

      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if email is already verified
      if (user.isEmailVerified) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Email is already verified'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Initialize email service if needed
      _emailService.initialize();

      // Resend OTP
      final sent = await _emailService.resendEmailVerificationOtp(
        userUuid: userUuid,
        email: user.email,
      );

      if (sent) {
        return Response.ok(
          jsonEncode({'message': 'Verification OTP resent to your email'}),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to resend verification OTP'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      print('Error resending verification OTP: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to resend verification OTP'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Check email verification status
  static Future<Response> checkVerificationStatus(Request request) async {
    try {
      // Get user from JWT token
      final token = request.headers['authorization']?.split('Bearer ').last;
      if (token == null) {
        return Response.unauthorized(
          jsonEncode({'error': 'No token provided'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final jwt = JWT.verify(token, SecretKey(Config.jwtSecret));
      final userUuid = jwt.payload['userId'] as String;

      // Check verification status
      final isVerified = await _emailService.isEmailVerified(userUuid);

      return Response.ok(
        jsonEncode({
          'isEmailVerified': isVerified,
          'message': isVerified ? 'Email is verified' : 'Email is not verified',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error checking verification status: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to check verification status'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
