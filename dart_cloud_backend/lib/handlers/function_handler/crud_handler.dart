import 'dart:convert';
import 'dart:io';
import 'package:dart_cloud_backend/handlers/logs/log_utils.dart';
import 'package:dart_cloud_backend/services/docker/docker.dart' show DockerService;
import 'package:dart_cloud_backend/services/s3_service.dart' show S3Service;
import 'package:shelf/shelf.dart';
import 'package:path/path.dart' as path;
import 'package:dart_cloud_backend/configuration/config.dart';
import 'package:database/database.dart';

/// Handles CRUD (Create, Read, Update, Delete) operations for functions
///
/// This handler provides basic function management operations:
/// - List all functions for a user
/// - Get details of a specific function
/// - Delete a function and its associated resources
class CrudHandler {
  /// List all functions owned by the authenticated user
  ///
  /// Returns a paginated list of functions with basic metadata.
  /// Functions are ordered by creation date (newest first).
  ///
  /// Response format:
  /// ```json
  /// [
  ///   {
  ///     "id": "uuid",
  ///     "name": "function-name",
  ///     "status": "active",
  ///     "createdAt": "2024-01-01T00:00:00Z"
  ///   }
  /// ]
  /// ```
  static Future<Response> list(Request request) async {
    try {
      // Extract and validate authenticated user
      final userId = request.context['userId'];
      // Query all functions for this user
      // Ordered by creation date descending (newest first)
      // final result = await Database.connection.execute(
      //   'SELECT id, name, status, created_at FROM functions WHERE user_id = \$1 ORDER BY created_at DESC',
      //   parameters: [authUser.id],
      // );
      final entites = await DatabaseManagers.functions.findAll(
        where: {
          FunctionEntityExtension.userIdNameField: userId,
        },
      );

      // Map database rows to JSON objects
      final functions = entites.map((entity) {
        return {
          'uuid': entity.uuid,
          'name': entity.name,
          'status': entity.status,
          'createdAt': entity.createdAt?.toIso8601String(),
        };
      }).toList();

      // Return list of functions
      return Response.ok(
        jsonEncode(functions),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      LogsUtils.log(
        "unknown",
        "error",
        {
          'err': "Failed to list functions: $e",
          'trace': trace.toString(),
        },
      );
      // Handle database or other errors
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to list functions: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Get details of a specific function
  ///
  /// Retrieves metadata for a single function. Verifies that the
  /// requesting user owns the function.
  ///
  /// Parameters:
  /// - [id]: Function UUID
  ///
  /// Response:
  /// - 200: Function details
  /// - 404: Function not found or access denied
  /// - 500: Server error
  static Future<Response> get(Request request, String uuid) async {
    try {
      // Extract and validate authenticated user
      /// this is the user id from the auth middleware
      final userId = request.context['userId'];
      // Query function with ownership verification
      // Only returns result if function exists AND belongs to this user
      final functionEntity = await DatabaseManagers.functions.findOne(
        where: {
          FunctionEntityExtension.uuidNameField: uuid,
          FunctionEntityExtension.userIdNameField: userId,
        },
      );

      // Check if function exists and user has access
      if (functionEntity == null) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Map function entity to JSON object

      return Response.ok(
        jsonEncode({
          'uuid': functionEntity.uuid,
          'name': functionEntity.name,
          'status': functionEntity.status,
          'createdAt': functionEntity.createdAt?.toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // Handle database or other errors
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get function: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Delete a function and all associated resources
  ///
  /// This operation:
  /// 1. Validates delete confirmation flag and function name in request body
  /// 2. Verifies function ownership by UUID and name match
  /// 3. Deletes function directory (all versions)
  /// 4. Deletes database records (cascades to deployments, logs, invocations)
  ///
  /// Note: S3 archives and Docker images are NOT automatically deleted.
  /// Consider implementing cleanup jobs for those resources.
  ///
  /// Parameters:
  /// - [uuid]: Function UUID (from URL path)
  ///
  /// Request Body:
  /// ```json
  /// {
  ///   "name": "function-name",
  ///   "delete": true
  /// }
  /// ```
  ///
  /// Response:
  /// - 200: Function deleted successfully
  /// - 400: Missing or invalid delete confirmation or name
  /// - 404: Function not found or access denied
  /// - 500: Deletion failed
  static Future<Response> delete(Request request, String uuid) async {
    try {
      // Extract and validate authenticated user
      final userId = request.context['userId'];
      // Parse and validate request body
      final body = await request.readAsString();
      if (body.isEmpty) {
        return Response(
          400,
          body: jsonEncode({
            'error': 'Request body is required with delete confirmation',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return Response(
          400,
          body: jsonEncode({'error': 'Invalid JSON body'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Validate function name in body
      final functionName = data['name'] as String?;
      if (functionName == null || functionName.isEmpty) {
        return Response(
          400,
          body: jsonEncode({
            'error': 'Function name required',
            'message': 'Provide "name" field in request body',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Validate delete confirmation flag
      final deleteConfirmation = data['delete'];
      if (deleteConfirmation != true) {
        return Response(
          400,
          body: jsonEncode({
            'error': 'Delete confirmation required',
            'message': 'Set "delete": true in request body to confirm deletion',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verify function ownership before deletion using UUID and validate name matches
      final functionEntityToDelete = await DatabaseManagers.functions.findOne(
        where: {
          FunctionEntityExtension.uuidNameField: uuid,
          FunctionEntityExtension.userIdNameField: userId,
          FunctionEntityExtension.nameField: functionName,
        },
      );

      // Check if function exists, user has access, and name matches
      if (functionEntityToDelete == null) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found or name mismatch'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final id = functionEntityToDelete.id!;
      // Store deployment metadata in database
      final deploymentResult = await Database.connection.execute(
        'SELECT image_tag, s3_key from function_deployments where function_id = \$1',
        parameters: [id],
      );

      // Delete function directory from filesystem
      // This removes all extracted function code for all versions
      final functionDir = Directory(path.join(Config.functionsDir, '$id'));
      if (await functionDir.exists()) {
        await functionDir.delete(recursive: true);
      }

      await Future.forEach(deploymentResult, (deployment) async {
        final s3Key = deployment[1] as String;
        final imageTag = deployment[0] as String;
        // Delete S3 archive
        await S3Service.s3Client.deleteObject(s3Key);

        // Delete Docker image
        await DockerService.removeImageStatic(imageTag);
      });

      // Delete function from database
      // Foreign key constraints will cascade delete to:
      // - function_deployments
      // - function_logs
      // - function_invocations
      await Database.connection.execute(
        'DELETE FROM functions WHERE id = \$1',
        parameters: [id],
      );

      // Return success message
      return Response.ok(
        jsonEncode({'message': 'Function deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // Handle filesystem or database errors
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete function: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
