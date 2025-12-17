import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:database/database.dart';

/// Handles function logging and monitoring operations
///
/// This handler provides access to function logs for debugging
/// and monitoring purposes. Logs include:
/// - Deployment events (build start, upload, completion)
/// - Execution results (success/failure)
/// - Error messages
/// - Performance metrics
class LogsHandler {
  /// Retrieve logs for a specific function
  ///
  /// Returns the most recent logs for a function, ordered by timestamp
  /// descending (newest first). Logs are limited to the last 100 entries
  /// to prevent excessive data transfer.
  ///
  /// Log levels:
  /// - info: Normal operations (deployment, execution)
  /// - warning: Non-critical issues
  /// - error: Failures and exceptions
  /// - debug: Detailed debugging information
  ///
  /// Response format:
  /// ```json
  /// {
  ///   "logs": [
  ///     {
  ///       "level": "info",
  ///       "message": "Function deployed successfully",
  ///       "timestamp": "2024-01-01T00:00:00Z"
  ///     }
  ///   ]
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [id]: Function UUID
  ///
  /// Response codes:
  /// - 200: Logs retrieved successfully
  /// - 404: Function not found or access denied
  /// - 500: Failed to retrieve logs
  static Future<Response> getLogs(Request request, String id) async {
    try {
      // Extract user ID from authenticated request
      final userId = request.context['userId'] as int;

      // === VERIFY FUNCTION OWNERSHIP ===
      // Check that function exists and belongs to requesting user
      final funcResult = await Database.connection.execute(
        'SELECT id FROM functions WHERE id = \$1 AND user_id = \$2',
        parameters: [id, userId],
      );

      // Return 404 if function not found or access denied
      if (funcResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // === RETRIEVE LOGS ===
      // Query recent logs for this function
      // Ordered by timestamp descending (newest first)
      // Limited to 100 entries to prevent excessive data transfer
      final logsResult = await Database.connection.execute(
        'SELECT level, message, created_at FROM function_logs WHERE function_id = \$1 ORDER BY created_at DESC LIMIT 100',
        parameters: [id],
      );

      // Map database rows to JSON objects
      final logs = logsResult.map((row) {
        return {
          'level': row[0], // Log level (info, warning, error, debug)
          'message': row[1], // Human-readable log message
          'timestamp': (row[2] as DateTime).toIso8601String(), // ISO 8601 timestamp
        };
      }).toList();

      // Return logs array
      return Response.ok(
        jsonEncode({'logs': logs}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // Handle database or other errors
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get logs: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
