import 'package:cloud_panel/providers/common_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:cloud_panel/providers/theme_provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'router.dart';
import 'common/web_url_platform/platform_url.dart';

void main() async {
  PlatformUrl.useWebUrlStrategy();
  await Hive.initFlutter();
  runApp(
    const ProviderScope(
      child: InitApp(),
    ),
  );
}

class InitApp extends ConsumerWidget {
  const InitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(fThemeDataProvider);
    return IntializeApp(
      theme: theme,
      builder: (theme) => MyApp(
        theme: theme,
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
    final isInitialized = ref.watch(authProvider).isAuthenticated;
    final locale = ref.watch(localeProvider);
    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated == true) {
        _appRouter.replaceAll(
          [
            const DashboardRoute(),
          ],
        );
      } else if (next.isAuthenticated == false) {
        _appRouter.replaceAll(
          [
            const LoginRoute(),
          ],
        );
      }
    });
    if (isInitialized == null) {
      return FTheme(
        data: widget.theme,
        child: FScaffold(
          child: Center(
            child: FCircularProgress(),
          ),
        ),
      );
    }
    return MaterialApp.router(
      title: 'Cloud Panel',
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => FTheme(
        data: widget.theme,
        child: FToaster(child: child!),
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
