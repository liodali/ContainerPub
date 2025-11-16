import 'dart:io';
import 'dart:convert';
import 'package:dart_cloud_cli/services/cache.dart';
import 'package:path/path.dart' as path;

class Config with AuthCache {
  static const String defaultServerUrl = 'http://localhost:8080';
  static String? _token;
  static String? _refreshToken;
  static String _serverUrl = defaultServerUrl;

  static String get serverUrl => _serverUrl;
  static String? get token => _token;
  static String? get refreshToken => _refreshToken;

  Config._();
  static Config? _instance;
  factory Config() {
    _instance ??= Config._();
    return _instance!;
  }

  static Config get instance => Config();

  static File get configFile {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) {
      print('Could not determine home directory');
      exit(1);
    }
    final configDir = Directory(path.join(home, '.dart_cloud'));
    if (!configDir.existsSync()) {
      configDir.createSync(recursive: true);
    }
    return File(path.join(configDir.path, 'config.json'));
  }

  Future<void> loadConfig() async {
    final file = configFile;
    if (await file.exists()) {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      _serverUrl = data['serverUrl'] as String? ?? defaultServerUrl;
    }
    _token = (await getToken()) ?? null;
    _refreshToken = await getRefreshToken() ?? null;
  }

  Future<void> save({
    String? token,
    String? refreshToken,
    String? serverUrl,
  }) async {
    if (token != null) _token = token;
    if (refreshToken != null) _refreshToken = refreshToken;
    if (serverUrl != null) _serverUrl = serverUrl;

    final data = {
      'serverUrl': _serverUrl,
    };

    await saveAuth(token: token!, refreshToken: refreshToken!);

    await configFile.writeAsString(jsonEncode(data));
  }

  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
    _serverUrl = defaultServerUrl;
    final file = configFile;
    if (await file.exists()) {
      await file.delete();
    }
    await clearAuth();
  }

  bool get isAuthenticated => _token != null;
}
