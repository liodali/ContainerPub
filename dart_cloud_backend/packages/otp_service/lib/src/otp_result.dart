class OtpResult {
  final String otp;
  final String hash;
  final String salt;
  final DateTime createdAt;

  const OtpResult({
    required this.otp,
    required this.hash,
    required this.salt,
    required this.createdAt,
  });

  @override
  String toString() {
    return 'OtpResult(otp: $otp, hash: $hash, salt: $salt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OtpResult &&
        other.otp == otp &&
        other.hash == hash &&
        other.salt == salt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return otp.hashCode ^ hash.hashCode ^ salt.hashCode ^ createdAt.hashCode;
  }
}
