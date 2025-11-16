import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:path/path.dart' as path;
import 'package:dart_cloud_backend/config/config.dart';
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
      // Extract user ID from authenticated request
      final userId = request.context['userId'] as String;

      // Query all functions for this user
      // Ordered by creation date descending (newest first)
      final result = await Database.connection.execute(
        'SELECT id, name, status, created_at FROM functions WHERE user_id = \$1 ORDER BY created_at DESC',
        parameters: [userId],
      );

      // Map database rows to JSON objects
      final functions = result.map((row) {
        return {
          'id': row[0],
          'name': row[1],
          'status': row[2],
          'createdAt': (row[3] as DateTime).toIso8601String(),
        };
      }).toList();

      // Return list of functions
      return Response.ok(
        jsonEncode(functions),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
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
  static Future<Response> get(Request request, String id) async {
    try {
      // Extract user ID from authenticated request
      final userId = request.context['userId'] as String;

      // Query function with ownership verification
      // Only returns result if function exists AND belongs to this user
      final result = await Database.connection.execute(
        'SELECT id, name, status, created_at FROM functions WHERE id = \$1 AND user_id = \$2',
        parameters: [id, userId],
      );

      // Check if function exists and user has access
      if (result.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Map database row to JSON object
      final row = result.first;
      return Response.ok(
        jsonEncode({
          'id': row[0],
          'name': row[1],
          'status': row[2],
          'createdAt': (row[3] as DateTime).toIso8601String(),
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
  /// 1. Verifies function ownership
  /// 2. Deletes function directory (all versions)
  /// 3. Deletes database records (cascades to deployments, logs, invocations)
  ///
  /// Note: S3 archives and Docker images are NOT automatically deleted.
  /// Consider implementing cleanup jobs for those resources.
  ///
  /// Parameters:
  /// - [id]: Function UUID
  ///
  /// Response:
  /// - 200: Function deleted successfully
  /// - 404: Function not found or access denied
  /// - 500: Deletion failed
  static Future<Response> delete(Request request, String id) async {
    try {
      // Extract user ID from authenticated request
      final userId = request.context['userId'] as String;

      // Verify function ownership before deletion
      final result = await Database.connection.execute(
        'SELECT id,s3_key,tag FROM functions WHERE uuid = \$1 AND user_id = \$2',
        parameters: [id, userId],
      );

      // Check if function exists and user has access
      if (result.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Delete function directory from filesystem
      // This removes all extracted function code for all versions
      final functionDir = Directory(path.join(Config.functionsDir, id));
      if (await functionDir.exists()) {
        await functionDir.delete(recursive: true);
      }

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
