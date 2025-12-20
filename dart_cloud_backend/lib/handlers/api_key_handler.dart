import 'dart:convert';
import 'dart:math';
import 'package:characters/characters.dart';
import 'package:dart_cloud_backend/handlers/logs_utils/log_utils.dart';
import 'package:dart_cloud_backend/utils/commons.dart';
import 'package:name_generator/name_generator.dart';
import 'package:shelf/shelf.dart';
import 'package:database/database.dart';
import 'package:dart_cloud_backend/services/api_key_service.dart';

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
      final randomName = (NameGenerator(16).value.characters.toList()..shuffle()).join();
      final apiKeyPair = await ApiKeyService.instance.generateApiKey(
        functionUuid: functionId,
        validity: validity,
        name: name ?? randomName,
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
      final userId = request.context['userId'] as int;
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
        where: {
          FunctionEntityExtension.uuidNameField: apiKey.functionUuid,
          FunctionEntityExtension.userIdNameField: userId,
        },
      );

      if (function == null) {
        return Response.notFound(
          jsonEncode({'error': 'Cannot Revoke this API key'}),
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
    } catch (e, trace) {
      LogsUtils.log(LogLevels.error.name, 'revokeApiKey', {
        'error': e,
        'trace': trace,
      });
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to revoke API key: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> deleteApiKey(Request request, String apiKeyUuid) async {
    try {
      final userId = request.context['userId'] as int;
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
        where: {
          FunctionEntityExtension.uuidNameField: apiKey.functionUuid,
          FunctionEntityExtension.userIdNameField: userId,
        },
      );

      if (function == null) {
        return Response.notFound(
          jsonEncode({'error': 'Cannot Revoke this API key'}),
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
      final success = await ApiKeyService.instance.deleteApiKey(apiKeyUuid);

      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to delete API key'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'message': 'API key revoked successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      LogsUtils.log(LogLevels.error.name, 'deleteApiKey', {
        'error': e,
        'trace': trace,
      });
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete API key: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/auth/apikey/<function_id>/list
  /// List all API keys for a function (history)
  static Future<Response> listApiKeys(Request request, String uuid) async {
    try {
      // Verify function exists
      final userId = request.context['userId'] as int;

      final function = await DatabaseManagers.functions.findOne(
        where: {
          FunctionEntityExtension.uuidNameField: uuid,
          FunctionEntityExtension.userIdNameField: userId,
        },
      );

      if (function == null) {
        return Response.notFound(
          jsonEncode({'error': 'API Keys not found for this function'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get user ID from request context

      // Get all API keys
      final apiKeys = await ApiKeyService.instance.listApiKeys(uuid);

      return Response.ok(
        jsonEncode({
          'api_keys': apiKeys.map((k) => ApiKeyInfo.fromEntity(k).toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      LogsUtils.log(LogLevels.error.name, 'listApiKeys', {
        'error': e,
        'trace': trace,
      });
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to list API keys'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> rollApiKey(Request request, String uuid) async {
    try {
      // Verify function exists
      final userId = request.context['userId'] as int;

      final apiKey = await ApiKeyService.instance.getApiKey(uuid);
      if (apiKey == null) {
        return Response.notFound(
          jsonEncode({'error': 'API Key not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      final function = await DatabaseManagers.functions.findOne(
        where: {
          FunctionEntityExtension.uuidNameField: apiKey.functionUuid,
          FunctionEntityExtension.userIdNameField: userId,
        },
      );

      if (function == null) {
        return Response.notFound(
          jsonEncode({'error': 'API Key not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      final durationAdded = switch (apiKey.validityEnum) {
        ApiKeyValidity.oneHour => const Duration(hours: 1),
        ApiKeyValidity.oneDay => const Duration(days: 1),
        ApiKeyValidity.oneWeek => const Duration(days: 7),
        ApiKeyValidity.oneMonth => const Duration(days: 30),
        ApiKeyValidity.forever => null,
      };

      await ApiKeyService.instance.updateApiKey(
        uuid,
        expiresAt: durationAdded == null ? null : apiKey.expiresAt?.add(durationAdded),
      );

      return Response.ok(
        jsonEncode({
          'message': 'API key updated successfully',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      LogsUtils.log(LogLevels.error.name, 'rollApiKey', {
        'error': e,
        'trace': trace,
      });
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to list API keys'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> updateApiKey(Request request, String uuid) async {
    try {
      // Verify function exists
      final userId = request.context['userId'] as int;

      final function = await DatabaseManagers.functions.findOne(
        where: {
          FunctionEntityExtension.uuidNameField: uuid,
          FunctionEntityExtension.userIdNameField: userId,
        },
      );

      if (function == null) {
        return Response.notFound(
          jsonEncode({'error': 'API Keys not found for this function'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      await ApiKeyService.instance.updateApiKey(
        uuid,
        name: body['name'] as String?,
      );

      return Response.ok(
        jsonEncode({
          'message': 'API key updated successfully',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      LogsUtils.log(LogLevels.error.name, 'updateApiKey', {
        'error': e,
        'trace': trace,
      });
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to list API keys'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
