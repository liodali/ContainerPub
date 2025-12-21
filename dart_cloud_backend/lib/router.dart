import 'package:dart_cloud_backend/routers/api_key_routes.dart';
import 'package:dart_cloud_backend/routers/functions_routes.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_cloud_backend/handlers/auth_handler.dart';
import 'package:dart_cloud_backend/handlers/statistics_handler.dart';
import 'package:dart_cloud_backend/middleware/auth_middleware.dart';

Router createRouter() {
  final router = Router();
  // Health check
  router.get('/health', (Request request) {
    return Response.ok('OK');
  });
  router.authRoutes();
  router.userRoutes();
  router.apiKeyRoutes();
  // Function routes (protected)
  router.functionRoutes();
  // User Overview Statistics routes (protected) - aggregated across all user's functions
  router.get(
    '/api/stats/overview',
    Pipeline()
        .addMiddleware(authMiddleware)
        .addHandler(
          StatisticsHandler.getOverviewStats,
        ),
  );

  router.get(
    '/api/stats/overview/hourly',
    Pipeline()
        .addMiddleware(authMiddleware)
        .addHandler(StatisticsHandler.getOverviewHourlyStats),
  );

  router.get(
    '/api/stats/overview/daily',
    Pipeline()
        .addMiddleware(authMiddleware)
        .addHandler(StatisticsHandler.getOverviewDailyStats),
  );

  // 404 handler
  router.all('/<ignored|.*>', (Request request) {
    return Response.notFound('Route not found');
  });

  return router;
}

extension ExtAuthRouter on Router {
  void authRoutes() {
    // Auth routes
    post('/api/auth/login', AuthHandler.login);
    post('/api/auth/register', AuthHandler.register);
    post('/api/auth/logout', AuthHandler.logout);
    post('/api/auth/refresh', AuthHandler.refreshToken);
  }
}

extension ExtUserRouter on Router {
  void userRoutes() {
    post('/api/user/onboarding', AuthHandler.onboarding);
    get('/api/user/<id>/organization/', AuthHandler.getOrganizationbyUser);
    patch('/api/user/<id>/organization/', AuthHandler.patchOrganizationbyUser);
    post('/api/user/organization', AuthHandler.createOrganization);
    post('/api/user/upgrade', AuthHandler.upgrade);
    post('/api/user/add-member', AuthHandler.addMember);
  }
}
