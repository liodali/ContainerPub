import 'dart:math';

/// A utility class for generating random alphanumeric strings optimized for server use.
class NameGenerator {
  static const String _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  static const int _charsLength = 62;

  const NameGenerator._(this._value);

  /// Creates a [NameGenerator] containing a random alphanumeric string [length] characters long.
  factory NameGenerator([int length = 32]) {
    assert(length > 0, 'Length must be positive');
    return NameGenerator._(_generate(length, _defaultRandom));
  }

  /// Creates a [NameGenerator] using cryptographically secure randomness.
  factory NameGenerator.secure([int length = 32]) {
    assert(length > 0, 'Length must be positive');
    return NameGenerator._(_generate(length, Random.secure()));
  }

  /// Creates a short 16-character nonce, useful for keys/tokens.
  factory NameGenerator.key() => NameGenerator(16);

  /// Creates a secure short 16-character nonce.
  factory NameGenerator.secureKey() => NameGenerator.secure(16);

  final String _value;

  /// Returns the length of this nonce.
  int get length => _value.length;

  /// Returns the string value of this nonce.
  String get value => _value;

  /// Fast NameGenerator generation using optimized character selection.
  static String _generate(int length, Random random) {
    // Use StringBuffer for efficient string building
    final buffer = StringBuffer();

    for (int i = 0; i < length; i++) {
      buffer.writeCharCode(_chars.codeUnitAt(random.nextInt(_charsLength)));
    }

    return buffer.toString();
  }

  /// Static method for generating NameGenerator strings directly.
  static String generate([int length = 32, Random? random]) {
    assert(length > 0, 'Length must be positive');
    return _generate(length, random ?? _defaultRandom);
  }

  /// Static method for generating secure nonce strings directly.
  static String generateSecure([int length = 32]) {
    assert(length > 0, 'Length must be positive');
    return _generate(length, Random.secure());
  }

  /// Efficiently generates multiple nonces in a batch.
  static List<String> generateBatch(int count, [int length = 32]) {
    assert(count > 0, 'Count must be positive');
    assert(length > 0, 'Length must be positive');

    final random = _defaultRandom;
    return List.generate(
      count,
      (_) => _generate(length, random),
      growable: false,
    );
  }

  /// Efficiently generates multiple secure nonces in a batch.
  static List<String> generateSecureBatch(int count, [int length = 32]) {
    assert(count > 0, 'Count must be positive');
    assert(length > 0, 'Length must be positive');

    final random = Random.secure();
    return List.generate(
      count,
      (_) => _generate(length, random),
      growable: false,
    );
  }

  @override
  bool operator ==(Object other) =>
      (other is NameGenerator && _value == other._value) ||
      (other is String && _value == other);

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => _value;

  /// Cached random instance for better performance in non-secure scenarios.
  static final Random _defaultRandom = Random();
}
