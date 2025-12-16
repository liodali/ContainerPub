import 'package:hive_ce/hive.dart';

class AuthService {
  static AuthService? _authService;
  const AuthService._();

  static AuthService get authService {
    _authService ??= AuthService._();
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
      return _authBox?.get('token') as String?;
    } catch (e) {
      // Ignore error for now
      return null;
    }
  }

  Future<void> loginSuccess(String token) async {
    await _authBox?.put('token', token);
  }

  Future<void> logout() async {
    await _authBox?.delete('token');
  }
}
