import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:database/database.dart';
import 'package:dart_cloud_backend/services/api_key_service.dart';

/// Middleware for verifying API key signatures on function invocations
///
/// This middleware:
/// 1. Extracts the function UUID from the request URL
/// 2. Checks if the function has an active API key
/// 3. If yes, verifies the X-Signature and X-Timestamp headers
/// 4. Passes signature verification info to the handler via context
Middleware get signatureMiddleware {
  return (Handler handler) {
    return (Request request) async {
      // Extract function UUID from URL path
      // Expected path: /api/functions/<uuid>/invoke
      final pathSegments = request.url.pathSegments;
      String? functionUuid;

      // Find the UUID in the path (it's after 'functions' and before 'invoke')
      for (var i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'functions' && i + 1 < pathSegments.length) {
          functionUuid = pathSegments[i + 1];
          break;
        }
      }

      if (functionUuid == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid request path'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if function exists
      final functionEntity = await DatabaseManagers.functions.findOne(
        where: {
          'uuid': functionUuid,
          'status': 'active',
        },
      );

      if (functionEntity == null) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      } // API key is required - verify signature

      if (functionEntity.skipSigning) {
        return handler(
          request.change(
            context: {
              ...request.context,
              'functionUuid': functionUuid,
              'functionEntity': functionEntity,
              'signatureVerified': false,
            },
          ),
        );
      }
      final signature = request.headers['x-signature'];
      final apiKey = request.headers['x-api-key'];
      final timestampStr = request.headers['x-timestamp'];

      if (signature == null || timestampStr == null || apiKey == null) {
        return Response.forbidden(
          jsonEncode({
            'error': 'This function requires API key signature',
            'message': 'Include X-Signature and X-Timestamp headers',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final apiKeyEntity = await DatabaseManagers.apiKeys.findOne(
        where: {
          'uuid': apiKey,
          'function_uuid': functionUuid,
        },
      );
      if (apiKeyEntity != null && !apiKeyEntity.isValid) {
        return Response.forbidden(
          jsonEncode({
            'error':
                'this function cannot be invoked! check your developer portal or contact support',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid timestamp format'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Read body for signature verification
      // Note: We need to read the body here, but shelf only allows reading once
      // So we'll store it in context for the handler to use
      final bodyString = await request.readAsString();
      Map<String, dynamic> body = {};

      if (bodyString.isNotEmpty) {
        try {
          body = jsonDecode(bodyString) as Map<String, dynamic>;
        } catch (e) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Invalid JSON body'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      // Get the payload for verification (body content)
      final payload = body['body'] != null ? jsonEncode(body['body']) : '';

      final isValid = await ApiKeyService.instance.verifySignature(
        functionUuid: functionUuid,
        keyUUID: apiKey,
        signature: signature,
        payload: payload,
        timestamp: timestamp,
      );

      if (!isValid) {
        return Response.forbidden(
          jsonEncode({
            'error': 'Invalid signature',
            'message': 'Signature verification failed. Check your API key and timestamp.',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Signature verified - add info to context and pass body
      body['raw'] = bodyString;
      body['signature_verified'] = true;
      body['signature_timestamp'] = timestamp;

      return handler(
        request.change(
          context: {
            ...request.context,
            'functionUuid': functionUuid,
            'functionEntity': functionEntity,
            'signatureVerified': true,
            'signatureTimestamp': timestamp,
            'parsedBody': body,
            'rawBody': bodyString,
          },
        ),
      );
    };
  };
}
