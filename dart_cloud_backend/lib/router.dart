import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_cloud_backend/handlers/auth_handler.dart';
import 'package:dart_cloud_backend/handlers/function_handler.dart';
import 'package:dart_cloud_backend/middleware/auth_middleware.dart';

Router createRouter() {
  final router = Router();

  // Health check
  router.get('/health', (Request request) {
    return Response.ok('OK');
  });

  // Auth routes
  router.post('/api/auth/login', AuthHandler.login);
  router.post('/api/auth/register', AuthHandler.register);

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
        .addHandler((req) => FunctionHandler.get(req, req.params['id']!,),),
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

  // 404 handler
  router.all('/<ignored|.*>', (Request request) {
    return Response.notFound('Route not found');
  });

  return router;
}
