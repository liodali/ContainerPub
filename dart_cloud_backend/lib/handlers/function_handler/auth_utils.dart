import 'dart:convert';

import 'package:database/database.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/v4.dart';

/// Result of authenticated user validation
/// Contains only the internal user ID, not sensitive data
class AuthenticatedUser {
  final int id;
  AuthenticatedUser(this.id);
}

/// Utility for extracting and validating authenticated user from request
class AuthUtils {
  /// Extract and validate authenticated user from request context
  ///
  /// Returns [AuthenticatedUser] with internal ID if valid,
  /// or null if user not found (invalid token or deleted user)
  ///
  /// Usage:
  /// ```dart
  /// final authUser = await AuthUtils.getAuthenticatedUser(request);
  /// if (authUser == null) {
  ///   return Response.notFound(jsonEncode({'error': 'Unauthorized'}));
  /// }
  /// // Use authUser.id for database queries
  /// ```
  static Future<AuthenticatedUser?> getAuthenticatedUser(Request request) async {
    final userUUID = request.context['userId'] as String?;
    if (userUUID == null) return null;

    final userEntity = await DatabaseManagers.users.findByUuid(userUUID);
    if (userEntity == null || userEntity.id == null) return null;

    return AuthenticatedUser(userEntity.id!);
  }

  static Future<AuthenticatedUser?> getAuthenticatedUserFromJWT(String uuid) async {
    final userEntity = await DatabaseManagers.users.findByUuid(uuid);
    if (userEntity == null || userEntity.id == null) return null;

    return AuthenticatedUser(userEntity.id!);
  }
}

/// Utility functions shared across function handlers
/// Provides common operations like logging and validation
class FunctionUtils {
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
  static Future<void> logFunction(
    String functionUuid,
    String level,
    String message,
  ) async {
    try {
      await Database.connection.execute(
        'INSERT INTO function_logs (function_uuid, level, message) VALUES (\$1, \$2, \$3)',
        parameters: [functionUuid, level, message],
      );
    } catch (e) {
      // Print to console if database logging fails
      // This ensures we don't lose critical logs
      print('Failed to log function: $e');
    }
  }
}

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
