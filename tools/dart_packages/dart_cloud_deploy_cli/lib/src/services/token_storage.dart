import 'dart:convert';
import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

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

class TokenStorage {
  static const String _boxName = 'openbao_tokens';
  static LazyBox<String>? _box;
  static TokenStorage? _instance;

  TokenStorage._();

  static TokenStorage get instance {
    _instance ??= TokenStorage._();
    return _instance!;
  }

  Future<void> initialize() async {
    if (_box != null && _box!.isOpen) {
      return;
    }

    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (homeDir == null) {
      throw Exception('Could not determine home directory');
    }

    final hiveDir = p.join(homeDir, '.dart_cloud_deploy', 'hive');
    final dir = Directory(hiveDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    Hive.init(hiveDir);
    _box = await Hive.openLazyBox<String>(_boxName);
  }

  Future<void> storeToken(
    String environment,
    String token, {
    Duration ttl = const Duration(hours: 1),
  }) async {
    await initialize();
    final tokenData = TokenData(
      token: token,
      expiresAt: DateTime.now().add(ttl).subtract(Duration(minutes: 10)),
    );
    await _box!.put(environment, jsonEncode(tokenData.toJson()));
  }

  Future<String?> getToken(String environment) async {
    await initialize();
    final data = await _box!.get(environment);
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
        await deleteToken(environment);
        return null;
      }
    } catch (e) {
      // Invalid data format, delete it
      await deleteToken(environment);
      return null;
    }
  }

  Future<bool> hasValidToken(String environment) async {
    final token = await getToken(environment);
    return token != null;
  }

  Future<void> deleteToken(String environment) async {
    await initialize();
    await _box!.delete(environment);
  }

  Future<List<String>> listEnvironments() async {
    await initialize();
    final keys = _box!.keys.cast<String>().toList();
    return keys;
  }

  Future<void> clearAll() async {
    await initialize();
    await _box!.clear();
  }

  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
  }
}
