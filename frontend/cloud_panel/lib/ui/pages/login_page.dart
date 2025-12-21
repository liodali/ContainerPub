import 'package:cloud_panel/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';

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
      await ref
          .read(authProvider.notifier)
          .login(
            _emailController.text,
            _passwordController.text,
            onError: (e) => setState(() => _error = e.toString()),
          );
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
                      'CP',
                      style: TextStyle(
                        color: context.theme.colors.primaryForeground,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ContainerPub',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                FCard(
                  title: Text(AppLocalizations.of(context)!.login),
                  subtitle: Text(AppLocalizations.of(context)!.welcomeBack),
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
                        label: Text(AppLocalizations.of(context)!.email),
                        hint: AppLocalizations.of(context)!.enterEmail,
                      ),
                      const SizedBox(height: 16),
                      FTextField(
                        controller: _passwordController,
                        label: Text(AppLocalizations.of(context)!.password),
                        obscureText: true,
                        hint: AppLocalizations.of(context)!.enterPassword,
                      ),
                      const SizedBox(height: 24),
                      FButton(
                        onPress: _isLoading ? null : _login,
                        child: _isLoading
                            ? Text(AppLocalizations.of(context)!.loggingIn)
                            : Text(AppLocalizations.of(context)!.login),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(AppLocalizations.of(context)!.or),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FButton(
                        style: FButtonStyle.outline(),
                        onPress: () {},
                        child: Text(
                          AppLocalizations.of(context)!.continueWithGoogle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FButton(
                        style: FButtonStyle.outline(),
                        onPress: () {},
                        child: Text(
                          AppLocalizations.of(context)!.continueWithGitHub,
                        ),
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
