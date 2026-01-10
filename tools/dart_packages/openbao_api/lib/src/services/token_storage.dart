import 'dart:convert';
import 'dart:io';
import 'package:hive_ce/hive.dart';

class TokenData {
  final String token;
  final DateTime expiresAt;

  TokenData({required this.token, required this.expiresAt});

  Map<String, dynamic> toJson() => {
    'token': token,
    'expires_at': expiresAt.toIso8601String(),
  };

  factory TokenData.fromJson(Map<String, dynamic> json) {
    return TokenData(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

/// A storage service for OpenBao tokens using Hive.
class TokenStorage {
  static const String _boxName = 'openbao_tokens';
  LazyBox<String>? _box;
  final String _storagePath;

  TokenStorage({
    required String storagePath,
  }) : _storagePath = storagePath;

  /// Initialize the storage.
  /// This must be called before using any other methods.
  Future<void> initialize() async {
    if (_box != null && _box!.isOpen) {
      return;
    }

    final dir = Directory(_storagePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    Hive.init(_storagePath);
    _box = await Hive.openLazyBox<String>(_boxName);
  }

  /// Store a token for a specific environment/key.
  Future<void> storeToken(
    String key,
    String token, {
    Duration ttl = const Duration(hours: 1),
  }) async {
    await initialize();
    final tokenData = TokenData(
      token: token,
      expiresAt: DateTime.now().add(ttl).subtract(const Duration(minutes: 10)),
    );
    await _box!.put(key, jsonEncode(tokenData.toJson()));
  }

  /// Get a valid token for a specific environment/key.
  /// Returns null if the token is missing or expired.
  Future<String?> getToken(String key) async {
    await initialize();
    final data = await _box!.get(key);
    if (data == null) {
      return null;
    }

    try {
      final tokenData = TokenData.fromJson(
        jsonDecode(data) as Map<String, dynamic>,
      );

      if (tokenData.isValid) {
        return tokenData.token;
      } else {
        // Token expired, delete it
        await deleteToken(key);
        return null;
      }
    } catch (e) {
      // Invalid data format, delete it
      await deleteToken(key);
      return null;
    }
  }

  /// Check if a valid token exists for a specific environment/key.
  Future<bool> hasValidToken(String key) async {
    final token = await getToken(key);
    return token != null;
  }

  /// Delete a token for a specific environment/key.
  Future<void> deleteToken(String key) async {
    await initialize();
    await _box!.delete(key);
  }

  /// List all stored keys (environments).
  Future<List<String>> listKeys() async {
    await initialize();
    final keys = _box!.keys.cast<String>().toList();
    return keys;
  }

  /// Clear all stored tokens.
  Future<void> clearAll() async {
    await initialize();
    await _box!.clear();
  }

  /// Close the storage box.
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
  }
}
