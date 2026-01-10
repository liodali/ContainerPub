import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

class TokenStorage {
  static const String _boxName = 'openbao_tokens';
  static Box<String>? _box;
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
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<void> storeToken(String environment, String token) async {
    await initialize();
    await _box!.put(environment, token);
  }

  Future<String?> getToken(String environment) async {
    await initialize();
    return _box!.get(environment);
  }

  Future<bool> hasToken(String environment) async {
    await initialize();
    return _box!.containsKey(environment);
  }

  Future<void> deleteToken(String environment) async {
    await initialize();
    await _box!.delete(environment);
  }

  Future<List<String>> listEnvironments() async {
    await initialize();
    return _box!.keys.cast<String>().toList();
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
