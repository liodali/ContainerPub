import 'dart:io';

import 'package:dart_cloud_cli/common/extension.dart';
import 'package:dotenv/dotenv.dart';
import 'package:hive_ce/hive.dart';

mixin AuthCache {
  static Box? _authBox;

  static Box get authBox {
    if (_authBox == null) {
      throw Exception('AuthCache not initialized');
    }
    return _authBox!;
  }

  Future<void> saveAuth({
    required String token,
    required String refreshToken,
  }) async {
    await authBox.put('token', token.encode);
    await authBox.put('refreshToken', refreshToken.encode);
  }

  Future<Map<String, String>> getAuthToken() async {
    final String token = await authBox.get('token');
    final String refreshToken = await authBox.get('refreshToken');
    return {'token': token.decode, 'refreshToken': refreshToken.decode};
  }

  Future<String?> getToken() async {
    final String? token = await authBox.get('token');
    return token?.decode;
  }

  Future<String?> getRefreshToken() async {
    final String? refreshToken = await authBox.get('refreshToken');
    return refreshToken?.decode;
  }

  Future<void> clearAuth() async {
    await authBox.clear();
  }

  static Future<void> init() async {
    String homeDir = "./";
    bool isDevLocal = _loadEnvs();
    homeDir = !isDevLocal ? _getHomeDir() : "./.dart_tool";
    Hive.init(
      '$homeDir/.containerpub/cache',
    );
    _authBox = await Hive.openBox('auth');
  }

  static Future<void> close() async {
    await _authBox?.close();
    await Hive.close();
  }

  static bool _loadEnvs() {
    if (!File('.env').existsSync()) {
      return false;
    }
    final dotEnv = DotEnv()..load(['.env']);
    return dotEnv.getOrElse('isDevLocal', () => 'false') == 'true';
  }

  static String _getHomeDir() {
    String homeDir = "./";
    if (Platform.isWindows) {
      // Windows uses USERPROFILE
      homeDir = Platform.environment['USERPROFILE']!;
    } else if (Platform.isLinux || Platform.isMacOS) {
      // Linux and macOS use HOME
      homeDir = Platform.environment['HOME']!;
    }
    return homeDir;
  }
}
