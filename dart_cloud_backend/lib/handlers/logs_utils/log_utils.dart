import 'dart:convert';

import 'package:database/database.dart';
import 'package:uuid/v4.dart';

/// Utility functions shared across function handlers
/// Provides common operations like logging and validation
class LogsUtils {
  /// Log a message for a specific function
  ///
  /// Logs are stored in the function_logs table and can be retrieved
  /// via the logs endpoint. Useful for tracking deployment progress,
  /// execution status, and debugging issues.
  ///
  /// Parameters:
  /// - [functionUuid]: UUID of the function
  /// - [level]: Log level (info, warning, error, debug)
  /// - [message]: Human-readable log message
  static Future<void> log(
    String level,
    String action,
    Map<String, dynamic> message,
  ) async {
    try {
      await Database.connection.execute(
        'INSERT INTO logs (uuid,action, level, message) VALUES (\$1, \$2, \$3, \$4)',
        parameters: [UuidV4().generate(), action, level, jsonEncode(message)],
      );
    } catch (e) {
      // Print to console if database logging fails
      // This ensures we don't lose critical logs
      print('Failed to log log: $e');
    }
  }
}
