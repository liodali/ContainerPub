import 'package:hive_ce/hive.dart';

class TokenService {
  static TokenService? _authService;
  const TokenService._();

  static TokenService get tokenService {
    _authService ??= TokenService._();
    return _authService!;
  }

  static Box? _authBox;

  Future<void> init() async {
    if (!Hive.isBoxOpen('auth')) {
      _authBox = await Hive.openBox('auth');
    }
  }

  Future<String?> get token async {
    try {
      return await _authBox?.get('token');
    } catch (e) {
      // Ignore error for now
      return null;
    }
  }

  Future<String?> get refreshToken async {
    try {
      return await _authBox?.get('refreshToken');
    } catch (e) {
      // Ignore error for now
      return null;
    }
  }

  Future<void> loginSuccess(String token, String refreshToken) async {
    await _authBox?.put('token', token);
    await _authBox?.put('refreshToken', refreshToken);
  }

  Future<void> logout() async {
    await _authBox?.delete('token');
    await _authBox?.delete('refreshToken');
  }
}
