import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:openbao_api/openbao_api.dart' as api;

class TokenStorage {
  static TokenStorage? _instance;
  late final api.TokenStorage _apiStorage;

  TokenStorage._();

  static TokenStorage get instance {
    _instance ??= TokenStorage._();
    return _instance!;
  }

  Future<void> initialize() async {
    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (homeDir == null) {
      throw Exception('Could not determine home directory');
    }

    final hiveDir = p.join(homeDir, '.dart_cloud_deploy', 'hive');
    _apiStorage = api.TokenStorage(storagePath: hiveDir);
    await _apiStorage.initialize();
  }

  Future<void> storeToken(
    String environment,
    String token, {
    Duration ttl = const Duration(hours: 1),
  }) async {
    await initialize();
    await _apiStorage.storeToken(environment, token, ttl: ttl);
  }

  Future<String?> getToken(String environment) async {
    await initialize();
    return _apiStorage.getToken(environment);
  }

  Future<bool> hasValidToken(String environment) async {
    await initialize();
    return _apiStorage.hasValidToken(environment);
  }

  Future<void> deleteToken(String environment) async {
    await initialize();
    await _apiStorage.deleteToken(environment);
  }

  Future<List<String>> listEnvironments() async {
    await initialize();
    return _apiStorage.listKeys();
  }

  Future<void> clearAll() async {
    await initialize();
    await _apiStorage.clearAll();
  }

  Future<void> close() async {
    await _apiStorage.close();
  }

  // Expose the underlying API storage for OpenBaoClient
  api.TokenStorage get apiStorage => _apiStorage;
}
