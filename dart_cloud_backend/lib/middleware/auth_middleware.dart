import 'dart:convert';
import 'package:dart_cloud_backend/handlers/function_handler/auth_utils.dart';
import 'package:dart_cloud_backend/services/token_service.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dart_cloud_backend/configuration/config.dart';

Middleware get authMiddleware {
  return (Handler handler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.forbidden(
          jsonEncode({'error': 'Missing or invalid authorization header'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = authHeader.substring(7);

      try {
        final jwt = JWT.verify(token, SecretKey(Config.jwtSecret));
        final userUUID = jwt.payload['userId'] as String;

        // Check if token is valid in user's whitelist
        final isValid = await TokenService.instance.isTokenValid(token, userUUID);
        if (!isValid) {
          return Response.forbidden(
            jsonEncode({'error': 'Invalid or expired token'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        final authUser = await AuthUtils.getAuthenticatedUserFromJWT(userUUID);
        if (authUser == null) {
          return Response.notFound(
            jsonEncode({'error': 'Unauthorized'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        // Add userId to request context
        return handler(
          request.change(
            context: {
              'userUUID': userUUID,
              'userId': authUser.id,
            },
          ),
        );
      } catch (e) {
        return Response.forbidden(
          jsonEncode({'error': 'Invalid or expired token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    };
  };
}
