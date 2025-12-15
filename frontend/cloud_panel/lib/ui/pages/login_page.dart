import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/auth_provider.dart';
import '../../providers/api_client_provider.dart';

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
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      // FScaffold likely takes child or body
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: FCard(
            title: const Text('Login'),
            subtitle: const Text('Welcome back to Cloud Panel'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.red), // Fallback color
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
                // FDivider might not take label/child directly like this
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
        ),
      ),
    );
  }
}
