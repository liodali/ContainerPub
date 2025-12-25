import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'guards/auth_guard.dart';
import 'providers/auth_provider.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/dashboard_page.dart';
import 'ui/views/overview_view.dart';
import 'ui/views/functions_view.dart';
import 'ui/views/containers_view.dart';
import 'ui/views/webhooks_view.dart';
import 'ui/views/settings_view.dart';
import 'ui/pages/function_details_page.dart';

class AppRouter extends RootStackRouter {
  final WidgetRef ref;

  AppRouter(this.ref);

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: LoginRoute.page, path: LoginRoute.path),
    AutoRoute(
      page: DashboardRoute.page,
      path: DashboardRoute.path,
      initial: true,
      guards: [AuthGuard(() => ref.read(authProvider).isAuthenticated == true)],
      children: [
        AutoRoute(
          page: OverviewRoute.page,
          path: OverviewRoute.path,
          initial: true,
        ),
        AutoRoute(
          page: FunctionContentRoute.page,
          path: FunctionContentRoute.path,
          children: [
            // 3. The default page for this sub-router
            AutoRoute(
              path: FunctionContentRoute.path,
              page: FunctionsRoute.page,
              initial: true,
            ),
            AutoRoute(
              page: FunctionDetailsRoute.page,
              path: FunctionDetailsRoute.path,
            ),
          ],
        ),
        AutoRoute(
          page: ContainersRoute.page,
          path: 'containers',
        ),
        AutoRoute(
          page: WebhooksRoute.page,
          path: 'webhooks',
        ),
        AutoRoute(
          page: SettingsRoute.page,
          path: 'settings',
        ),
      ],
    ),
  ];
}

class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({
    List<PageRouteInfo>? children,
  }) : super(
         LoginRoute.name,
         initialChildren: children,
       );

  static const String name = 'LoginRoute';
  static const String path = '/login';
  static final PageInfo page = PageInfo(
    name,
    builder: (router) => const LoginPage(),
  );
}

class DashboardRoute extends PageRouteInfo<void> {
  const DashboardRoute({List<PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';
  static const String path = '/dashboard';
  static final PageInfo page = PageInfo(
    name,
    builder: (router) => const DashboardPage(),
  );
}

class OverviewRoute extends PageRouteInfo<void> {
  const OverviewRoute({List<PageRouteInfo>? children})
    : super(OverviewRoute.name, initialChildren: children);

  static const String name = 'OverviewRoute';
  static const String path = 'overview';
  static final PageInfo page = PageInfo(
    name,
    builder: (router) => const OverviewView(),
  );
}

class FunctionsRoute extends PageRouteInfo<void> {
  const FunctionsRoute({List<PageRouteInfo>? children})
    : super(FunctionsRoute.name, initialChildren: children);

  static const String name = 'FunctionsRoute';
  static const String path = 'functions';
  static final PageInfo page = PageInfo(
    name,
    builder: (router) => const FunctionsView(),
  );
}

class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (router) => const SettingsView(),
  );
}

class FunctionContentRoute extends PageRouteInfo<void> {
  const FunctionContentRoute({List<PageRouteInfo>? children})
    : super(FunctionContentRoute.name, initialChildren: children);

  static const String name = 'FunctionContentRoute';
  static const String path = '';
  static final PageInfo page = PageInfo(
    name,
    builder: (router) => const AutoRouter(),
  );
}

class FunctionDetailsRoute extends PageRouteInfo<FunctionDetailsRouteArgs> {
  FunctionDetailsRoute({
    required String uuid,
    required String name,
    List<PageRouteInfo>? children,
  }) : super(
         FunctionDetailsRoute.name,
         args: FunctionDetailsRouteArgs(
           uuid: uuid,
           name: name,
         ),
         initialChildren: children,
         rawPathParams: {'name': name},
       );

  static const String name = 'FunctionDetailsRoute';
  static const String path = ':name';
  static final PageInfo page = PageInfo(
    name,
    builder: (router) {
      if (router.args == null) {
        throw ArgumentError('args must be provided');
      }
      final args = router.args as FunctionDetailsRouteArgs;
      return FunctionDetailsPage(
        uuid: args.uuid,
        name: args.name,
      );
    },
  );
}

class FunctionDetailsRouteArgs {
  final String uuid;
  final String name;

  const FunctionDetailsRouteArgs({
    required this.uuid,
    required this.name,
  });
}

class ContainersRoute extends PageRouteInfo<void> {
  const ContainersRoute({List<PageRouteInfo>? children})
    : super(ContainersRoute.name, initialChildren: children);

  static const String name = 'ContainersRoute';
  static const String path = 'containers';
  static final PageInfo page = PageInfo(
    name,
    builder: (router) => const ContainersView(),
  );
}

class WebhooksRoute extends PageRouteInfo<void> {
  const WebhooksRoute({List<PageRouteInfo>? children})
    : super(WebhooksRoute.name, initialChildren: children);

  static const String name = 'WebhooksRoute';
  static const String path = 'webhooks';
  static final PageInfo page = PageInfo(
    name,
    builder: (router) => const WebhooksView(),
  );
}
