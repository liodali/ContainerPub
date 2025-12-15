import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

class AuthState {
  final bool isAuthenticated;
  final String? token;

  AuthState({
    this.isAuthenticated = false,
    this.token,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _loadToken();
    return AuthState();
  }

  Future<void> _loadToken() async {
    try {
      final box = await Hive.openBox('auth');
      final token = box.get('token') as String?;
      if (token != null) {
        state = state.copyWith(isAuthenticated: true, token: token);
      }
    } catch (e) {
      // Ignore error for now
    }
  }

  Future<void> loginSuccess(String token) async {
    final box = await Hive.openBox('auth');
    await box.put('token', token);
    state = state.copyWith(isAuthenticated: true, token: token);
  }

  Future<void> logout() async {
    final box = await Hive.openBox('auth');
    await box.delete('token');
    state = state.copyWith(isAuthenticated: false, token: null);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
