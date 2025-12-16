import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:auto_route/auto_route.dart';
import '../../providers/auth_provider.dart';
import '../../providers/api_client_provider.dart';

@RoutePage()
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final token = await client.login(
        _emailController.text,
        _passwordController.text,
      );
      await ref.read(authProvider.notifier).loginSuccess(token);
      // Navigation is handled by auth state listener in main.dart
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.theme.colors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'D',
                      style: TextStyle(
                        color: context.theme.colors.primaryForeground,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dart Cloud',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                FCard(
                  title: const Text('Login'),
                  subtitle: const Text('Welcome back to Cloud Panel'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                      ],
                      FTextField(
                        controller: _emailController,
                        label: const Text('Email'),
                        hint: 'Enter your email',
                      ),
                      const SizedBox(height: 16),
                      FTextField(
                        controller: _passwordController,
                        label: const Text('Password'),
                        obscureText: true,
                        hint: 'Enter your password',
                      ),
                      const SizedBox(height: 24),
                      FButton(
                        onPress: _isLoading ? null : _login,
                        child: _isLoading
                            ? const Text('Logging in...')
                            : const Text('Login'),
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text("OR"),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FButton(
                        style: FButtonStyle.outline(),
                        onPress: () {},
                        child: const Text('Continue with Google'),
                      ),
                      const SizedBox(height: 12),
                      FButton(
                        style: FButtonStyle.outline(),
                        onPress: () {},
                        child: const Text('Continue with GitHub'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
