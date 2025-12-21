import 'package:dart_cloud_backend/handlers/function_handler.dart';
import 'package:dart_cloud_backend/handlers/statistics_handler.dart';
import 'package:dart_cloud_backend/middleware/auth_middleware.dart';
import 'package:dart_cloud_backend/middleware/function_ownership_middleware.dart';
import 'package:dart_cloud_backend/middleware/signature_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

extension FunctionRouter on Router {
  void functionRoutes() {
    post(
      '/api/functions/init',
      Pipeline().addMiddleware(authMiddleware).addHandler(FunctionHandler.init),
    );

    post(
      '/api/functions/deploy',
      Pipeline().addMiddleware(authMiddleware).addHandler(FunctionHandler.deploy),
    );

    get(
      '/api/functions',
      Pipeline().addMiddleware(authMiddleware).addHandler(FunctionHandler.list),
    );

    get(
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

    get(
      '/api/functions/<id>/logs',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addHandler((req) => FunctionHandler.getLogs(req, req.params['id']!)),
    );

    delete(
      '/api/functions/<id>',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addHandler((req) => FunctionHandler.delete(req, req.params['id']!)),
    );

    post(
      '/api/functions/<id>/invoke',
      Pipeline()
          .addMiddleware(signatureMiddleware)
          .addHandler((req) => FunctionHandler.invoke(req, req.params['id']!)),
    );

    get(
      '/api/functions/<id>/deployments',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addHandler(
            (req) => FunctionHandler.getDeployments(req, req.params['id']!),
          ),
    );

    post(
      '/api/functions/<id>/rollback',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addHandler(
            (req) => FunctionHandler.rollback(req, req.params['id']!),
          ),
    );
    // Per-function Statistics routes (protected)
    get(
      '/api/functions/<id>/stats',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addMiddleware(functionOwnershipMiddleware('id'))
          .addHandler((req) => StatisticsHandler.getStats(req, req.params['id']!)),
    );

    get(
      '/api/functions/<id>/stats/hourly',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addMiddleware(functionOwnershipMiddleware('id'))
          .addHandler((req) => StatisticsHandler.getHourlyStats(req, req.params['id']!)),
    );

    get(
      '/api/functions/<id>/stats/daily',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addMiddleware(functionOwnershipMiddleware('id'))
          .addHandler((req) => StatisticsHandler.getDailyStats(req, req.params['id']!)),
    );
  }
}
