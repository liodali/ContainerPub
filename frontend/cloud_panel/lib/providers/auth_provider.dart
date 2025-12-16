import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';

import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_panel/providers/common_provider.dart';
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
      final token = await ref.read(tokenServiceProvider).token;

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

  Future<void> login(
    String email,
    String password, {
    Function(Object e)? onError,
  }) async {
    try {
      final authData = await ref
          .read(apiAuthClientProvider)
          .login(email, password);
      await ref
          .read(tokenServiceProvider)
          .loginSuccess(authData.token, authData.refreshToken);
      state = state.copyWith(isAuthenticated: true, token: authData.token);
    } catch (e, trace) {
      // Ignore error for now
      debugPrint('Error loading token: $e');
      debugPrint('Error loading token: $trace');
      onError?.call(e);
      state = state.copyWith(
        isAuthenticated: false,
        token: null,
      );
    }
  }

  Future<void> logout() async {
    await ref.read(tokenServiceProvider).logout();
    state = state.copyWith(isAuthenticated: false, token: null);
  }
}

final apiAuthClientProvider = Provider<CloudApiAuthClient>(
  (ref) => CloudApiAuthClient(
    dio: ref.read(dioProvider).clone(),
  ),
);
final tokenInterceptorProvider = Provider<TokenAuthInterceptor>(
  (ref) => TokenAuthInterceptor(
    tokenService: ref.read(tokenServiceProvider),
    apiAuthClient: ref.read(apiAuthClientProvider),
    refreshDio: ref.read(dioProvider).clone(),
  ),
);
final tokenServiceProvider = Provider<TokenService>(
  (ref) => TokenService.tokenService,
);
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
