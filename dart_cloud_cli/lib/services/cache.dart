import 'package:dart_cloud_cli/common/extension.dart';
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
    final token = await authBox.get('token');
    final refreshToken = await authBox.get('refreshToken');
    return {'token': token.decode, 'refreshToken': refreshToken.decode};
  }

  Future<String?> getToken() async {
    final token = await authBox.get('token');
    return token?.decode;
  }

  Future<String?> getRefreshToken() async {
    final refreshToken = await authBox.get('refreshToken');
    return refreshToken?.decode;
  }

  Future<void> clearAuth() async {
    await authBox.clear();
  }

  static Future<void> init() async {
    Hive.init(
      '~/.containerpub/cache',
    );
    _authBox = await Hive.openBox('auth');
  }
}
