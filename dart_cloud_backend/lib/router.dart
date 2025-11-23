import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_cloud_backend/handlers/auth_handler.dart';
import 'package:dart_cloud_backend/handlers/function_handler.dart';
import 'package:dart_cloud_backend/middleware/auth_middleware.dart';

Router createRouter() {
  final router = Router();

  router.userRoutes();
  // Health check
  router.get('/health', (Request request) {
    return Response.ok('OK');
  });


  // Function routes (protected)
  router.post(
    '/api/functions/deploy',
    Pipeline().addMiddleware(authMiddleware).addHandler(FunctionHandler.deploy),
  );

  router.get(
    '/api/functions',
    Pipeline().addMiddleware(authMiddleware).addHandler(FunctionHandler.list),
  );

  router.get(
    '/api/functions/<id>',
    Pipeline()
        .addMiddleware(authMiddleware)
        .addHandler(
          (req) => FunctionHandler.get(
            req,
            req.params['id']!,
          ),
        ),
  );

  router.get(
    '/api/functions/<id>/logs',
    Pipeline()
        .addMiddleware(authMiddleware)
        .addHandler((req) => FunctionHandler.getLogs(req, req.params['id']!)),
  );

  router.delete(
    '/api/functions/<id>',
    Pipeline()
        .addMiddleware(authMiddleware)
        .addHandler((req) => FunctionHandler.delete(req, req.params['id']!)),
  );

  router.post(
    '/api/functions/<id>/invoke',
    Pipeline()
        .addMiddleware(authMiddleware)
        .addHandler((req) => FunctionHandler.invoke(req, req.params['id']!)),
  );

  router.get(
    '/api/functions/<id>/deployments',
    Pipeline()
        .addMiddleware(authMiddleware)
        .addHandler((req) => FunctionHandler.getDeployments(req, req.params['id']!)),
  );

  router.post(
    '/api/functions/<id>/rollback',
    Pipeline()
        .addMiddleware(authMiddleware)
        .addHandler((req) => FunctionHandler.rollback(req, req.params['id']!)),
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
