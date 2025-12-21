import 'package:dart_cloud_backend/handlers/api_key_handler.dart';
import 'package:dart_cloud_backend/middleware/auth_middleware.dart';
import 'package:dart_cloud_backend/middleware/input_validation_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

extension APIKeyRoutes on Router {
  void apiKeyRoutes() {
    // API Key routes (protected)
    post(
      '/api/apikey/generate',
      Pipeline().addMiddleware(authMiddleware).addHandler(ApiKeyHandler.generateApiKey),
    );
    get(
      '/api/apikey/<function_id>',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addMiddleware(
            validateUuid(
              key: 'function_id',
              source: ValidationSource.url,
            ),
          )
          .addHandler(
            (req) => ApiKeyHandler.getApiKeyInfo(req, req.params['function_id']!),
          ),
    );
    put(
      '/api/apikey/<api_key_uuid>/roll',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addMiddleware(
            validateUuid(
              key: 'api_key_uuid',
              source: ValidationSource.url,
            ),
          )
          .addHandler(
            (req) => ApiKeyHandler.rollApiKey(req, req.params['api_key_uuid']!),
          ),
    );
    put(
      '/api/apikey/<api_key_uuid>/update',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addMiddleware(
            validateUuid(
              key: 'api_key_uuid',
              source: ValidationSource.url,
            ),
          )
          .addHandler(
            (req) => ApiKeyHandler.updateApiKey(req, req.params['api_key_uuid']!),
          ),
    );
    delete(
      '/api/apikey/<api_key_uuid>/revoke',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addMiddleware(
            validateUuid(
              key: 'api_key_uuid',
              source: ValidationSource.url,
            ),
          )
          .addHandler(
            (req) => ApiKeyHandler.revokeApiKey(req, req.params['api_key_uuid']!),
          ),
    );
    delete(
      '/api/apikey/<api_key_uuid>',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addMiddleware(
            validateUuid(
              key: 'api_key_uuid',
              source: ValidationSource.url,
            ),
          )
          .addHandler(
            (req) => ApiKeyHandler.deleteApiKey(req, req.params['api_key_uuid']!),
          ),
    );
    get(
      '/api/apikey/<function_id>/list',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addMiddleware(
            validateUuid(
              key: 'function_id',
              source: ValidationSource.url,
            ),
          )
          .addHandler(
            (req) => ApiKeyHandler.listApiKeys(req, req.params['function_id']!),
          ),
    );
    put(
      '/api/apikey/<api_key_uuid>/enable',
      Pipeline()
          .addMiddleware(authMiddleware)
          .addMiddleware(
            validateUuid(
              key: 'api_key_uuid',
              source: ValidationSource.url,
            ),
          )
          .addHandler(
            (req) => ApiKeyHandler.enableApiKey(req, req.params['api_key_uuid']!),
          ),
    );
  }
}
