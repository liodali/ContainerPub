import 'package:auto_route/auto_route.dart';
import 'package:cloud_panel/guards/auth_guard.dart';
import 'package:cloud_panel/router.dart';
import 'package:flutter_test/flutter_test.dart';

class MockNavigationResolver implements NavigationResolver {
  bool? nextCalledWith;

  @override
  void next([bool continueNavigation = true]) {
    nextCalledWith = continueNavigation;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStackRouter implements StackRouter {
  List<PageRouteInfo>? pushedRoutes;

  @override
  Future<void> replaceAll(List<PageRouteInfo> routes,
      {OnNavigationFailure? onFailure, bool updateExistingRoutes = true}) async {
    pushedRoutes = routes;
  }

  @override
  Future<T?> push<T extends Object?>(PageRouteInfo route,
      {OnNavigationFailure? onFailure}) async {
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthGuard', () {
    late MockNavigationResolver resolver;
    late MockStackRouter router;

    setUp(() {
      resolver = MockNavigationResolver();
      router = MockStackRouter();
    });

    test('should allow navigation when authenticated', () {
      // Arrange
      final guard = AuthGuard(() => true);

      // Act
      guard.onNavigation(resolver, router);

      // Assert
      expect(resolver.nextCalledWith, isTrue);
      expect(router.pushedRoutes, isNull);
    });

    test('should block navigation and redirect to login when unauthenticated', () {
      // Arrange
      final guard = AuthGuard(() => false);

      // Act
      guard.onNavigation(resolver, router);

      // Assert
      expect(resolver.nextCalledWith, isFalse);
      expect(router.pushedRoutes, isNotNull);
      expect(router.pushedRoutes!.length, 1);
      expect(router.pushedRoutes!.first, isA<LoginRoute>());
    });
  });
}
