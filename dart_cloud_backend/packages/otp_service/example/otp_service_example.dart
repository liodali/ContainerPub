import 'package:otp_service/otp_service.dart';

void main() {
  print('=== OTP Service Example ===\n');

  const email = 'user@example.com';

  print('1. Generate OTP with hash and salt');
  final result = OtpService.generateOtpWithHash(email: email);
  print('   OTP: ${result.otp}');
  print('   Hash: ${result.hash}');
  print('   Salt: ${result.salt}');
  print('   Created: ${result.createdAt}\n');

  print('2. Verify correct OTP');
  final isValidCorrect = OtpService.verifyOtp(
    otp: result.otp,
    storedHash: result.hash,
    storedSalt: result.salt,
  );
  print('   Result: ${isValidCorrect ? "✓ Valid" : "✗ Invalid"}\n');

  print('3. Verify incorrect OTP');
  final isValidIncorrect = OtpService.verifyOtp(
    otp: '000000',
    storedHash: result.hash,
    storedSalt: result.salt,
  );
  print('   Result: ${isValidIncorrect ? "✓ Valid" : "✗ Invalid"}\n');

  print('4. Check if OTP is expired (fresh OTP)');
  final isExpiredFresh = OtpService.isOtpExpired(result.createdAt);
  print('   Result: ${isExpiredFresh ? "Expired" : "✓ Valid"}\n');

  print('5. Check if old OTP is expired (25 hours old)');
  final oldTimestamp = DateTime.now().subtract(const Duration(hours: 25));
  final isExpiredOld = OtpService.isOtpExpired(oldTimestamp);
  print('   Result: ${isExpiredOld ? "✓ Expired" : "Valid"}\n');

  print('6. Generate multiple unique OTPs');
  final otps = <String>{};
  for (var i = 0; i < 10; i++) {
    otps.add(OtpService.generateOtp());
  }
  print('   Generated ${otps.length} unique OTPs from 10 attempts\n');

  print('7. Individual operations');
  final otp = OtpService.generateOtp();
  final salt = OtpService.generateSalt(
    email: email,
    timestamp: DateTime.now(),
  );
  final hash = OtpService.hashOtp(otp: otp, salt: salt);
  print('   OTP: $otp');
  print('   Salt: $salt');
  print('   Hash: $hash\n');

  print('=== Complete Email Verification Flow ===\n');

  print('Step 1: User registers');
  const userEmail = 'newuser@example.com';
  final otpResult = OtpService.generateOtpWithHash(email: userEmail);
  print('   Generated OTP: ${otpResult.otp}');
  print('   Store hash in DB: ${otpResult.hash.substring(0, 20)}...');
  print('   Store salt in DB: ${otpResult.salt}');
  print('   Send OTP to user via email\n');

  print('Step 2: User submits OTP');
  final userSubmittedOtp = otpResult.otp;
  print('   User entered: $userSubmittedOtp\n');

  print('Step 3: Verify OTP');
  final isExpired = OtpService.isOtpExpired(otpResult.createdAt);
  if (isExpired) {
    print('   ✗ OTP expired');
  } else {
    final isValid = OtpService.verifyOtp(
      otp: userSubmittedOtp,
      storedHash: otpResult.hash,
      storedSalt: otpResult.salt,
    );
    if (isValid) {
      print('   ✓ OTP verified successfully');
      print('   Mark email as verified in database');
      print('   Delete OTP from database');
    } else {
      print('   ✗ Invalid OTP');
    }
  }

  print('\n=== Constants ===');
  print('OTP Length: ${OtpService.otpLength}');
  print('OTP Validity: ${OtpService.otpValidity.inHours} hours');
}
