import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

class Config {
  static const String defaultServerUrl = 'http://localhost:8080';
  static String? _authToken;
  static String _serverUrl = defaultServerUrl;

  static String get serverUrl => _serverUrl;
  static String? get authToken => _authToken;

  static File get configFile {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) {
      throw Exception('Could not determine home directory');
    }
    final configDir = Directory(path.join(home, '.dart_cloud'));
    if (!configDir.existsSync()) {
      configDir.createSync(recursive: true);
    }
    return File(path.join(configDir.path, 'config.json'));
  }

  static Future<void> load() async {
    final file = configFile;
    if (await file.exists()) {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      _authToken = data['authToken'] as String?;
      _serverUrl = data['serverUrl'] as String? ?? defaultServerUrl;
    }
  }

  static Future<void> save({String? authToken, String? serverUrl}) async {
    if (authToken != null) _authToken = authToken;
    if (serverUrl != null) _serverUrl = serverUrl;

    final data = {
      'authToken': _authToken,
      'serverUrl': _serverUrl,
    };

    await configFile.writeAsString(jsonEncode(data));
  }

  static Future<void> clear() async {
    _authToken = null;
    _serverUrl = defaultServerUrl;
    final file = configFile;
    if (await file.exists()) {
      await file.delete();
    }
  }

  static bool get isAuthenticated => _authToken != null;
}
