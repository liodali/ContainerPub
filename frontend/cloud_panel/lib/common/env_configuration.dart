class EnvConfiguration {
  final String apiBaseUrl;

  const EnvConfiguration._(this.apiBaseUrl);

  static EnvConfiguration? _instance;

  factory EnvConfiguration(String apiBaseUrl) {
    _instance ??= EnvConfiguration._(apiBaseUrl);
    return _instance!;
  }

  static EnvConfiguration fromMap(Map<String, String> map) {
    return EnvConfiguration(map['apiBaseUrl']!);
  }

  static EnvConfiguration fromPlatformEnv() {
    return EnvConfiguration(const String.fromEnvironment('API_BASE_URL'));
  }
}
