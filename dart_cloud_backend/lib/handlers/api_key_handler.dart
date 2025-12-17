import 'dart:convert';
import 'dart:math';
import 'package:random_name_generator/random_name_generator.dart';
import 'package:shelf/shelf.dart';
import 'package:database/database.dart';
import 'package:dart_cloud_backend/services/api_key_service.dart';

final RandomNames randomNames = RandomNames(Zone.us);
final Random randomNumbers = Random.secure();

class ApiKeyHandler {
  /// POST /api/auth/apikey/generate
  /// Generate a new API key for a function
  /// Body: { "function_id": "uuid", "validity": "1h|1d|1w|1m|forever", "name": "optional" }
  static Future<Response> generateApiKey(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final functionId = body['function_id'] as String?;
      final validityStr = body['validity'] as String?;
      final name = body['name'] as String?;

      if (functionId == null || validityStr == null) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'function_id and validity are required',
            'valid_validity_options': ['1h', '1d', '1w', '1m', 'forever'],
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Validate validity
      final validity = ApiKeyValidity.fromString(validityStr);
      final userId = request.context['userId'] as int;

      // Verify function exists
      final function = await DatabaseManagers.functions.findOne(
        where: {
          FunctionEntityExtension.uuidNameField: functionId,
          FunctionEntityExtension.userIdNameField: userId,
        },
      );

      if (function == null) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Generate the API key pair
      final apiKeyPair = await ApiKeyService.instance.generateApiKey(
        functionUuid: functionId,
        validity: validity,
        name: name ?? '${randomNames.name()}${randomNumbers.nextInt(1000) + 100}',
      );

      return Response.ok(
        jsonEncode({
          'message': 'API key generated successfully',
          'warning': 'Store the secret_key securely - it will not be shown again!',
          'api_key': apiKeyPair.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      print(e);
      print(trace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to generate API key'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/auth/apikey/<function_id>
  /// Get API key info for a function (without private key)
  static Future<Response> getApiKeyInfo(Request request, String functionId) async {
    try {
      final userId = request.context['userId'] as int;
      // Verify function exists
      final function = await DatabaseManagers.functions.findOne(
        where: {'uuid': functionId, FunctionEntityExtension.userIdNameField: userId},
      );

      if (function == null) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      // Verify user owns the function
      final user = await DatabaseManagers.users.findOne(
        where: {'id': userId},
      );

      if (user == null || function.userId != user.id) {
        return Response.forbidden(
          jsonEncode({
            'error': 'We cannot load the API key for this function',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get active API key
      final apiKey = await ApiKeyService.instance.getActiveApiKey(functionId);

      if (apiKey == null) {
        return Response.ok(
          jsonEncode({
            'has_api_key': false,
            'message': 'No active API key for this function',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'has_api_key': true,
          'api_key': ApiKeyInfo.fromEntity(apiKey).toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get API key info: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// DELETE /api/auth/apikey/<api_key_uuid>
  /// Revoke an API key
  static Future<Response> revokeApiKey(Request request, String apiKeyUuid) async {
    try {
      // Get the API key
      final apiKey = await DatabaseManagers.apiKeys.findOne(
        where: {'uuid': apiKeyUuid},
      );

      if (apiKey == null) {
        return Response.notFound(
          jsonEncode({'error': 'API key not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get function to verify ownership
      final function = await DatabaseManagers.functions.findOne(
        where: {'uuid': apiKey.functionUuid},
      );

      if (function == null) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get user ID from request context
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Authentication required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verify user owns the function
      final user = await DatabaseManagers.users.findOne(
        where: {'uuid': userId},
      );

      if (user == null || function.userId != user.id) {
        return Response.forbidden(
          jsonEncode({'error': 'You do not have permission to revoke this API key'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Revoke the key
      final success = await ApiKeyService.instance.revokeApiKey(apiKeyUuid);

      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to revoke API key'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'message': 'API key revoked successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to revoke API key: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/auth/apikey/<function_id>/list
  /// List all API keys for a function (history)
  static Future<Response> listApiKeys(Request request, String functionId) async {
    try {
      // Verify function exists
      final function = await DatabaseManagers.functions.findOne(
        where: {'uuid': functionId},
      );

      if (function == null) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get user ID from request context
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Authentication required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verify user owns the function
      final user = await DatabaseManagers.users.findOne(
        where: {'uuid': userId},
      );

      if (user == null || function.userId != user.id) {
        return Response.forbidden(
          jsonEncode({
            'error': 'You do not have permission to view API keys for this function',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get all API keys
      final apiKeys = await ApiKeyService.instance.listApiKeys(functionId);

      return Response.ok(
        jsonEncode({
          'api_keys': apiKeys.map((k) => ApiKeyInfo.fromEntity(k).toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to list API keys: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
