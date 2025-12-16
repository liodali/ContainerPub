import 'package:cloud_panel/services/auth_service.dart';
import 'package:flutter/widgets.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      final token = await ref.read(authServiceProvider).token;

      if (token != null) {
        state = state.copyWith(
          isAuthenticated: true,
          token: token,
        );
      }
    } catch (e, trace) {
      // Ignore error for now
      debugPrint('Error loading token: $e');
      debugPrint('Error loading token: $trace');
    }
  }

  Future<void> loginSuccess(String token) async {
    await ref.read(authServiceProvider).loginSuccess(token);
    state = state.copyWith(isAuthenticated: true, token: token);
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = state.copyWith(isAuthenticated: false, token: null);
  }
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService.authService,
);
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
