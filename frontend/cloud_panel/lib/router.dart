import 'package:auto_route/auto_route.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/dashboard_page.dart';
import 'ui/views/overview_view.dart';
import 'ui/views/functions_view.dart';
import 'ui/views/settings_view.dart';
import 'ui/pages/function_details_page.dart';

class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(
      page: DashboardRoute.page,
      path: '/dashboard',
      initial: true,
      children: [
        AutoRoute(page: OverviewRoute.page, path: 'overview', initial: true),
        AutoRoute(page: FunctionsRoute.page, path: 'functions'),
        AutoRoute(page: SettingsRoute.page, path: 'settings'),
      ],
    ),
    AutoRoute(page: FunctionDetailsRoute.page, path: '/functions/:name'),
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
  static final PageInfo page = PageInfo(
    name,
    builder: (router) => const LoginPage(),
  );
}

class DashboardRoute extends PageRouteInfo<void> {
  const DashboardRoute({List<PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (router) => const DashboardPage(),
  );
}

class OverviewRoute extends PageRouteInfo<void> {
  const OverviewRoute({List<PageRouteInfo>? children})
    : super(OverviewRoute.name, initialChildren: children);

  static const String name = 'OverviewRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (router) => const OverviewView(),
  );
}

class FunctionsRoute extends PageRouteInfo<void> {
  const FunctionsRoute({List<PageRouteInfo>? children})
    : super(FunctionsRoute.name, initialChildren: children);

  static const String name = 'FunctionsRoute';
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

class FunctionDetailsRoute extends PageRouteInfo<FunctionDetailsRouteArgs> {
  FunctionDetailsRoute({
    required String uuid,
    required String name,
    List<PageRouteInfo>? children,
  }) : super(
         FunctionDetailsRoute.name,
         args: FunctionDetailsRouteArgs(uuid: uuid, name: name),
         initialChildren: children,
         rawPathParams: {'name': name},
       );

  static const String name = 'FunctionDetailsRoute';
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
