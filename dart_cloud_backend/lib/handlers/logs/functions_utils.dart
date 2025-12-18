import 'package:dart_cloud_backend/handlers/logs/log_utils.dart';
import 'package:dart_cloud_backend/utils/commons.dart';
import 'package:database/database.dart';

/// Utility functions shared across function handlers
/// Provides common operations like logging and validation
class FunctionUtils {
  /// Log a message for a specific function while deploying
  ///
  /// Logs are stored in the function_deploy_logs table and can be retrieved
  /// via the logs endpoint. Useful for tracking deployment progress,
  /// execution status, and debugging issues.
  ///
  /// Parameters:
  /// - [functionUuid]: UUID of the function
  /// - [level]: Log level (info, warning, error, debug)
  /// - [message]: Human-readable log message
  static Future<void> logDeploymentFunction(
    String functionUuid,
    String level,
    String message,
  ) async {
    try {
      await Database.connection.execute(
        'INSERT INTO function_deploy_logs (function_uuid, level, message) VALUES (\$1, \$2, \$3)',
        parameters: [functionUuid, level, message],
      );
    } catch (e) {
      // Print to console if database logging fails
      // This ensures we don't lose critical logs
      print('Failed to log function: $e');
    }
  }

  /// Log a message for a specific function while deploying
  ///
  /// Logs are stored in the function_deploy_logs table and can be retrieved
  /// via the logs endpoint. Useful for tracking deployment progress,
  /// execution status, and debugging issues.
  ///
  /// Parameters:
  /// - [functionUuid]: UUID of the function
  /// - [level]: Log level (info, warning, error, debug)
  /// - [message]: Human-readable log message
  static Future<void> logInvocationFunction(
    FunctionInvocationEntity functionInvocationEntity,
  ) async {
    try {
      await DatabaseManagers.functionInvocations.insert(
        functionInvocationEntity.toDBMap(),
      );
    } catch (e, trace) {
      print('Failed to log function: $e');
      LogsUtils.log(
        LogLevels.error.name,
        'logInvocationFunction',
        {
          'error': 'Failed to log function: $e',
          'trace': trace.toString(),
        },
      );
    }
  }
}
