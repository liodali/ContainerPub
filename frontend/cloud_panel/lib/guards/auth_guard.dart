import 'package:auto_route/auto_route.dart';
import 'package:cloud_panel/router.dart';

class AuthGuard extends AutoRouteGuard {
  final bool Function() isAuthenticated;

  AuthGuard(this.isAuthenticated);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (isAuthenticated()) {
      resolver.next(true);
    } else {
      // Redirect to login
      resolver.next(false);
      router.replaceAll([const LoginRoute()]);
    }
  }
}
