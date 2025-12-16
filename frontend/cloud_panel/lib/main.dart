import 'package:cloud_panel/providers/common_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:forui/forui.dart';
import 'providers/auth_provider.dart';
import 'router.dart';

void main() async {
  usePathUrlStrategy();
  runApp(
    const ProviderScope(
      child: InitApp(),
    ),
  );
}

class InitApp extends StatelessWidget {
  const InitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return IntializeApp(
      theme: FThemes.zinc.light,
      builder: (theme) => MyApp(
        theme: FThemes.zinc.light,
      ),
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({
    super.key,
    required this.theme,
  });
  final FThemeData theme;
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final _appRouter = AppRouter(ref);

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        _appRouter.replaceAll(
          [
            const DashboardRoute(),
          ],
        );
      } else {
        _appRouter.replaceAll(
          [
            const LoginRoute(),
          ],
        );
      }
    });

    return MaterialApp.router(
      title: 'Cloud Panel',
      builder: (context, child) => FTheme(
        data: widget.theme,
        child: child!,
      ),
      routerConfig: _appRouter.config(),
    );
  }
}

class IntializeApp extends ConsumerWidget {
  const IntializeApp({
    super.key,
    this.theme,
    required this.builder,
  });
  final FThemeData? theme;
  final Widget Function(FThemeData theme) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInitialized = ref.watch(initializeAppProvider);
    final themeData = theme ?? FThemes.zinc.light;
    if (isInitialized.isLoading) {
      return FTheme(
        data: themeData,
        child: const FScaffold(
          child: Center(
            child: FCircularProgress(),
          ),
        ),
      );
    }
    return builder(themeData);
  }
}
