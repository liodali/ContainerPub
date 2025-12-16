import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_panel/providers/common_provider.dart';
import 'package:flutter/widgets.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool? isAuthenticated;
  AuthState({this.isAuthenticated});

  AuthState copyWith({
    bool? isAuthenticated,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated,
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
        );
      }
    } catch (e, trace) {
      // Ignore error for now
      debugPrint('Error loading token: $e');
      debugPrint('Error loading token: $trace');
    }
    state = state.copyWith(
      isAuthenticated: false,
    );
  }

  Future<void> login(
    String email,
    String password, {
    Function(Object e)? onError,
  }) async {
    try {
      await ref.read(authServiceProvider).login(email, password);

      state = state.copyWith(
        isAuthenticated: true,
      );
    } catch (e, trace) {
      // Ignore error for now
      debugPrint('Error loading token: $e');
      debugPrint('Error loading token: $trace');
      onError?.call(e);
      state = state.copyWith(
        isAuthenticated: false,
      );
    }
  }

  Future<void> logout() async {
    await ref.read(tokenServiceProvider).logout();
    state = state.copyWith(
      isAuthenticated: false,
    );
  }
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    ref.read(apiAuthClientProvider),
    ref.read(tokenServiceProvider),
  ),
);
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
    onLogout: () => ref.read(authProvider.notifier).logout(),
  ),
);
final tokenServiceProvider = Provider<TokenService>(
  (ref) => TokenService.tokenService,
);
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
