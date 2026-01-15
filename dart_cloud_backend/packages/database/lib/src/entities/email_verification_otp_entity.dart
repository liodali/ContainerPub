import '../entity.dart';

/// Email verification OTP entity representing the email_verification_otps table
class EmailVerificationOtpEntity extends Entity {
  final int? id;
  final String userUuid;
  final String otpHash;
  final String salt;
  final DateTime? createdAt;

  EmailVerificationOtpEntity({
    this.id,
    required this.userUuid,
    required this.otpHash,
    required this.salt,
    this.createdAt,
  });

  @override
  String get tableName => 'email_verification_otps';

  @override
  Map<String, dynamic> toMap() {
    return {
      'user_uuid': userUuid,
      'otp_hash': otpHash,
      'salt': salt,
    };
  }

  @override
  Map<String, dynamic> toDBMap() {
    return {
      if (id != null) 'id': id,
      'user_uuid': userUuid,
      'otp_hash': otpHash,
      'salt': salt,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  static EmailVerificationOtpEntity fromMap(Map<String, dynamic> map) {
    return EmailVerificationOtpEntity(
      id: map['id'] as int?,
      userUuid: map['user_uuid'] as String,
      otpHash: map['otp_hash'] as String,
      salt: map['salt'] as String,
      createdAt: map['created_at'] as DateTime?,
    );
  }

  EmailVerificationOtpEntity copyWith({
    int? id,
    String? userUuid,
    String? otpHash,
    String? salt,
    DateTime? createdAt,
  }) {
    return EmailVerificationOtpEntity(
      id: id ?? this.id,
      userUuid: userUuid ?? this.userUuid,
      otpHash: otpHash ?? this.otpHash,
      salt: salt ?? this.salt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
