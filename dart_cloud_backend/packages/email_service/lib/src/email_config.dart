class EmailConfig {
  final String apiKey;
  final String fromAddress;
  final String? logo;
  final String? companyName;
  final String? supportEmail;

  const EmailConfig({
    required this.apiKey,
    required this.fromAddress,
    this.logo,
    this.companyName,
    this.supportEmail,
  });

  EmailConfig copyWith({
    String? apiKey,
    String? fromAddress,
    String? logo,
    String? companyName,
    String? supportEmail,
  }) {
    return EmailConfig(
      apiKey: apiKey ?? this.apiKey,
      fromAddress: fromAddress ?? this.fromAddress,
      logo: logo ?? this.logo,
      companyName: companyName ?? this.companyName,
      supportEmail: supportEmail ?? this.supportEmail,
    );
  }

  @override
  String toString() {
    return 'EmailConfig(fromAddress: $fromAddress, companyName: $companyName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EmailConfig &&
        other.apiKey == apiKey &&
        other.fromAddress == fromAddress &&
        other.logo == logo &&
        other.companyName == companyName &&
        other.supportEmail == supportEmail;
  }

  @override
  int get hashCode {
    return apiKey.hashCode ^
        fromAddress.hashCode ^
        logo.hashCode ^
        companyName.hashCode ^
        supportEmail.hashCode;
  }
}
