/// Validity duration options for API keys
enum ApiKeyValidity {
  oneHour('1h'),
  oneDay('1d'),
  oneWeek('1w'),
  oneMonth('1m'),
  forever('forever');

  final String value;

  const ApiKeyValidity(this.value);

  /// Get all valid validity options as strings
  static List<String> get validOptions => values.map((v) => v.value).toList();

  /// Parse string to ApiKeyValidity enum
  static ApiKeyValidity fromString(String value) {
    return ApiKeyValidity.values.firstWhere(
      (v) => v.value == value,
      orElse: () => ApiKeyValidity.forever,
    );
  }

  /// Check if a string is a valid validity value
  static bool isValid(String value) {
    return validOptions.contains(value);
  }
}
