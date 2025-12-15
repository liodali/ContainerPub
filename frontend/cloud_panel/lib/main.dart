import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'providers/auth_provider.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/dashboard_page.dart';

void main() async {
  await Hive.initFlutter();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Cloud Panel',
      builder: (context, child) => FTheme(
        data: FThemes.zinc.light,
        child: child!,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Simple check. In a real app, you'd want a loading state here
    // to prevent flashing Login page while token loads.
    // Since AuthNotifier loads token async, initial state is null.
    // We can check if we have a token in Hive synchronously if we wanted,
    // but Hive needs async openBox.
    // For now, it will show Login briefly.

    if (authState.isAuthenticated) {
      return const DashboardPage();
    } else {
      return const LoginPage();
    }
  }
}
