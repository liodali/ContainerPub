import 'package:dart_cloud_cli/common/extension.dart';
import 'package:dart_cloud_cli/services/hive_service.dart';
import 'package:hive_ce/hive.dart';

mixin AuthCache {
  static LazyBox? _authBox;

  static LazyBox get authBox {
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
    _authBox = await HiveService.initBox<String>('auth', subPath: 'cache');
  }

  static Future<void> close() async {
    await HiveService.closeBox(_authBox);
  }
}
