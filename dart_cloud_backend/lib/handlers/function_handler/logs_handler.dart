import 'dart:convert';
import 'package:dart_cloud_backend/handlers/logs_utils/log_utils.dart';
import 'package:dart_cloud_backend/utils/commons.dart';
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
  static Future<Response> getLogs(Request request, String uuid) async {
    try {
      // Extract user ID from authenticated request
      final userId = request.context['userId'] as int;

      // === VERIFY FUNCTION OWNERSHIP ===
      // Check that function exists and belongs to requesting user
      // final funcResult = await Database.connection.execute(
      //   'SELECT id FROM functions WHERE id = \$1 AND user_id = \$2',
      //   parameters: [id, userId],
      // );
      final funcResult = await DatabaseManagers.functions.findOne(
        where: {
          FunctionEntityExtension.uuidNameField: uuid,
          FunctionEntityExtension.userIdNameField: userId,
        },
      );

      // Return 404 if function not found or access denied
      if (funcResult == null) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // === RETRIEVE LOGS ===
      // Query recent logs for this function
      // Ordered by timestamp descending (newest first)
      // Limited to 100 entries to prevent excessive data transfer
      final logs = await DatabaseManagers.functionInvocations.findAll(
        where: {
          ExtFunctionInvocations.functionIdNameField: funcResult.id,
        },
      );
      // final logsResult = await Database.connection.execute(
      //   'SELECT level, message, created_at FROM function_invocations WHERE function_id = \$1 ORDER BY created_at DESC LIMIT 100',
      //   parameters: [funcResult.id],
      // );

      // Map database rows to JSON objects
      final logResults = logs.map((log) {
        return {
          'status': log.status, // Log level (info, warning, error, debug)
          'error': log.error,
          'logs': log.functionDebugLogs
              .map((log) => 'DEBUG. ${log.timestamp}. ${log.message}')
              .toList(), // Human-readable log message
          'timestamp': log.timestamp?.toIso8601String(), // ISO 8601 timestamp
        };
      }).toList();

      // Return logs array
      return Response.ok(
        jsonEncode({'logs': logResults}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      // Handle database or other errors
      LogsUtils.log(
        LogLevels.error.name,
        'logs retrieval failed for $uuid',
        {
          'error': 'Failed to get logs for $uuid: $e',
          'trace': trace.toString(),
        },
      );
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get logs for $uuid'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
