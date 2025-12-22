import 'dart:convert';
import 'package:dart_cloud_backend/utils/commons.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import 'package:database/database.dart';
import 'package:dart_cloud_backend/handlers/logs_utils/functions_utils.dart';

/// Handles function initialization operations
///
/// This handler creates a new function record with status 'init'
/// and generates a UUID for the function before any deployment.
class InitHandler {
  static const _uuid = Uuid();

  /// Initialize a new function
  ///
  /// Creates a function record in the database with:
  /// - Generated UUID
  /// - Function name from request body
  /// - Status: 'init'
  /// - User ID from authenticated request
  ///
  /// Request format:
  /// ```json
  /// {
  ///   "name": "my_function"
  /// }
  /// ```
  ///
  /// Response:
  /// - 201: Function initialized successfully
  /// - 400: Invalid request (missing name or function already exists)
  /// - 500: Initialization failed
  static Future<Response> init(Request request) async {
    try {
      // Extract user ID from authenticated request context
      // final authUser = await AuthUtils.getAuthenticatedUser(request);
      // if (authUser == null) {
      //   return Response.notFound(
      //     jsonEncode({'error': 'Unauthorized'}),
      //     headers: {'Content-Type': 'application/json'},
      //   );
      // }
      final userId = request.context['userId'] as int;
      // Parse request body
      final bodyString = await request.readAsString();
      if (bodyString.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Request body is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(bodyString) as Map<String, dynamic>;
      final functionName = body['name'] as String?;
      final skipSigning = body['skip_signing'] as bool? ?? false;

      if (functionName == null || functionName.trim().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Function name is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if function with this name already exists for this user
      final existingFunction = await DatabaseManagers.functions.findOne(
        where: {
          FunctionEntityExtension.userIdNameField: userId,
          FunctionEntityExtension.nameField: functionName,
        },
      );

      if (existingFunction != null) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'Function with this name already exists',
            'function_id': existingFunction.uuid,
            'status': existingFunction.status,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Generate unique UUID for the function
      final functionUUID = _uuid.v4();

      // Create function record with 'init' status
      final result = await DatabaseManagers.functions.insert(
        FunctionEntity(
          name: functionName,
          uuid: functionUUID,
          userId: userId,
          status: DeploymentStatus.init.name,
          skipSigning: skipSigning,
        ).toDBMap(),
      );

      if (result == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to initialize function'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Log function initialization
      await FunctionUtils.logDeploymentFunction(
        functionUUID,
        'info',
        'Function initialized: $functionName',
      );

      return Response(
        201,
        body: jsonEncode({
          'message': 'Function initialized successfully',
          'id': functionUUID,
          'name': functionName,
          'status': DeploymentStatus.init.name,
          'skip_signing': skipSigning,
          'created_at': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to initialize function: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
