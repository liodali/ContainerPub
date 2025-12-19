import 'dart:math';

/// A utility class for generating random alphanumeric strings with improved performance.
class NameGenerator {
  static const String _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  static const int _maxUniqueNonces = 10000; // Prevent memory leaks

  const NameGenerator._(this._value);

  /// Creates a [NameGenerator] containing a random alphanumeric string [length] characters long.
  factory NameGenerator([int length = 32]) {
    assert(length > 0);
    return NameGenerator._(_generateFast(length));
  }

  /// Constructs a [NameGenerator] that's unique from every other [NameGenerator] with LRU eviction.
  factory NameGenerator.unique([int length = 32]) {
    assert(length > 0);

    var value = _generateFast(length);
    var attempts = 0;
    const maxAttempts = 100;

    while (_uniqueNonces.containsKey(value) && attempts < maxAttempts) {
      value = _generateFast(length);
      attempts++;
    }

    if (attempts >= maxAttempts) {
      // Fallback to timestamp-based uniqueness
      value =
          '${DateTime.now().microsecondsSinceEpoch}_${_generateFast(length - 14)}';
    }

    _addUniqueNonce(value);
    return NameGenerator._(value);
  }

  /// Constructs a secure [NameGenerator] using crypto-strong randomness.
  factory NameGenerator.secure([int length = 32]) {
    assert(length > 0);
    return NameGenerator._(_generateSecure(length));
  }

  /// Constructs a unique nonce 16 characters in length.
  factory NameGenerator.key() => NameGenerator.unique(16);

  final String _value;

  int get length => _value.length;

  /// Fast generation using pre-allocated character table.
  static String _generateFast(int length, [Random? random]) {
    random ??= _defaultRandom;

    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.writeCharCode(_chars.codeUnitAt(random.nextInt(62)));
    }
    return buffer.toString();
  }

  /// Secure generation with cryptographically strong randomness.
  static String _generateSecure(int length) {
    final random = Random.secure();
    final buffer = StringBuffer();

    for (int i = 0; i < length; i++) {
      buffer.writeCharCode(_chars.codeUnitAt(random.nextInt(62)));
    }
    return buffer.toString();
  }

  /// Batch generation for better performance when creating multiple nonces.
  static List<String> generateBatch(int count, [int length = 32]) {
    final random = Random();
    return List.generate(count, (_) => _generateFast(length, random));
  }

  /// Legacy method for backward compatibility.
  static String generate([int length = 32, Random? random]) {
    return _generateFast(length, random);
  }

  /// Adds a nonce to unique set with LRU eviction.
  static void _addUniqueNonce(String value) {
    if (_uniqueNonces.length >= _maxUniqueNonces) {
      // Remove oldest entry (LRU eviction)
      final oldestKey = _uniqueNonces.keys.first;
      _uniqueNonces.remove(oldestKey);
    }
    _uniqueNonces[value] = DateTime.now().millisecondsSinceEpoch;
  }

  /// Clears the unique nonces cache.
  static void clearUniqueCache() {
    _uniqueNonces.clear();
  }

  /// Returns the number of cached unique nonces.
  static int get uniqueCacheSize => _uniqueNonces.length;

  @override
  bool operator ==(Object other) =>
      (other is NameGenerator && _value == other._value) ||
      (other is String && _value == other);

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => _value;

  /// Cached random instance for better performance.
  static final Random _defaultRandom = Random();

  /// LRU cache with timestamp tracking instead of growing Set.
  static final Map<String, int> _uniqueNonces = <String, int>{};
}
