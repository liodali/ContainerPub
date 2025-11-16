import 'package:database/database.dart' show Database;
import 'package:postgres/postgres.dart';

/// Helper class for database queries using UUIDs
///
/// This class provides methods to query database tables using public UUIDs
/// while internally working with serial IDs for performance.
class QueryHelpers {
  /// Get user by UUID (public identifier)
  static Future<Map<String, dynamic>?> getUserByUuid(String uuid) async {
    final result = await Database.connection.execute(
      Sql.named('''
        SELECT id, uuid, email, created_at, updated_at
        FROM users
        WHERE uuid = @uuid
      '''),
      parameters: {'uuid': uuid},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return {
      'id': row[0],
      'uuid': row[1].toString(),
      'email': row[2],
      'created_at': row[3],
      'updated_at': row[4],
    };
  }

  /// Get user by email
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final result = await Database.connection.execute(
      Sql.named('''
        SELECT id, uuid, email, password_hash, created_at, updated_at
        FROM users
        WHERE email = @email
      '''),
      parameters: {'email': email},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return {
      'id': row[0],
      'uuid': row[1].toString(),
      'email': row[2],
      'password_hash': row[3],
      'created_at': row[4],
      'updated_at': row[5],
    };
  }

  /// Create user and return UUID
  static Future<String> createUser(String email, String passwordHash) async {
    final result = await Database.connection.execute(
      Sql.named('''
        INSERT INTO users (email, password_hash)
        VALUES (@email, @password_hash)
        RETURNING uuid
      '''),
      parameters: {
        'email': email,
        'password_hash': passwordHash,
      },
    );

    return result.first[0].toString();
  }

  /// Get function by UUID (public identifier)
  static Future<Map<String, dynamic>?> getFunctionByUuid(String uuid) async {
    final result = await Database.connection.execute(
      Sql.named('''
        SELECT f.id, f.uuid, f.name, f.status, f.analysis_result,
               f.created_at, f.updated_at, u.uuid as user_uuid
        FROM functions f
        JOIN users u ON f.user_id = u.id
        WHERE f.uuid = @uuid
      '''),
      parameters: {'uuid': uuid},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return {
      'id': row[0],
      'uuid': row[1].toString(),
      'name': row[2],
      'status': row[3],
      'analysis_result': row[4],
      'created_at': row[5],
      'updated_at': row[6],
      'user_uuid': row[7].toString(),
    };
  }

  /// Get all functions for a user (by user UUID)
  static Future<List<Map<String, dynamic>>> getFunctionsByUserUuid(
    String userUuid,
  ) async {
    final result = await Database.connection.execute(
      Sql.named('''
        SELECT f.id, f.uuid, f.name, f.status, f.analysis_result,
               f.created_at, f.updated_at
        FROM functions f
        JOIN users u ON f.user_id = u.id
        WHERE u.uuid = @user_uuid
        ORDER BY f.created_at DESC
      '''),
      parameters: {'user_uuid': userUuid},
    );

    return result.map((row) {
      return {
        'id': row[0],
        'uuid': row[1].toString(),
        'name': row[2],
        'status': row[3],
        'analysis_result': row[4],
        'created_at': row[5],
        'updated_at': row[6],
      };
    }).toList();
  }

  /// Create function and return UUID
  static Future<String> createFunction({
    required String userUuid,
    required String name,
    String status = 'active',
    Map<String, dynamic>? analysisResult,
  }) async {
    final result = await Database.connection.execute(
      Sql.named('''
        INSERT INTO functions (user_id, name, status, analysis_result)
        SELECT u.id, @name, @status, @analysis_result
        FROM users u
        WHERE u.uuid = @user_uuid
        RETURNING uuid
      '''),
      parameters: {
        'user_uuid': userUuid,
        'name': name,
        'status': status,
        'analysis_result': analysisResult,
      },
    );

    return result.first[0].toString();
  }

  /// Update function by UUID
  static Future<bool> updateFunction({
    required String uuid,
    String? name,
    String? status,
    Map<String, dynamic>? analysisResult,
  }) async {
    final updates = <String>[];
    final parameters = <String, dynamic>{'uuid': uuid};

    if (name != null) {
      updates.add('name = @name');
      parameters['name'] = name;
    }
    if (status != null) {
      updates.add('status = @status');
      parameters['status'] = status;
    }
    if (analysisResult != null) {
      updates.add('analysis_result = @analysis_result');
      parameters['analysis_result'] = analysisResult;
    }

    if (updates.isEmpty) return false;

    final result = await Database.connection.execute(
      Sql.named('''
        UPDATE functions
        SET ${updates.join(', ')}
        WHERE uuid = @uuid
      '''),
      parameters: parameters,
    );

    return result.affectedRows > 0;
  }

  /// Delete function by UUID
  static Future<bool> deleteFunction(String uuid) async {
    final result = await Database.connection.execute(
      Sql.named('''
        DELETE FROM functions
        WHERE uuid = @uuid
      '''),
      parameters: {'uuid': uuid},
    );

    return result.affectedRows > 0;
  }

  /// Get function logs by function UUID
  static Future<List<Map<String, dynamic>>> getFunctionLogsByFunctionUuid(
    String functionUuid, {
    int limit = 100,
    int offset = 0,
  }) async {
    final result = await Database.connection.execute(
      Sql.named('''
        SELECT fl.uuid, fl.level, fl.message, fl.timestamp
        FROM function_logs fl
        JOIN functions f ON fl.function_id = f.id
        WHERE f.uuid = @function_uuid
        ORDER BY fl.timestamp DESC
        LIMIT @limit OFFSET @offset
      '''),
      parameters: {
        'function_uuid': functionUuid,
        'limit': limit,
        'offset': offset,
      },
    );

    return result.map((row) {
      return {
        'uuid': row[0].toString(),
        'level': row[1],
        'message': row[2],
        'timestamp': row[3],
      };
    }).toList();
  }

  /// Create function log and return UUID
  static Future<String> createFunctionLog({
    required String functionUuid,
    required String level,
    required String message,
  }) async {
    final result = await Database.connection.execute(
      Sql.named('''
        INSERT INTO function_logs (function_id, level, message)
        SELECT f.id, @level, @message
        FROM functions f
        WHERE f.uuid = @function_uuid
        RETURNING uuid
      '''),
      parameters: {
        'function_uuid': functionUuid,
        'level': level,
        'message': message,
      },
    );

    return result.first[0].toString();
  }

  /// Get function invocations by function UUID
  static Future<List<Map<String, dynamic>>> getFunctionInvocationsByFunctionUuid(
    String functionUuid, {
    int limit = 100,
    int offset = 0,
  }) async {
    final result = await Database.connection.execute(
      Sql.named('''
        SELECT fi.uuid, fi.status, fi.duration_ms, fi.error, fi.timestamp
        FROM function_invocations fi
        JOIN functions f ON fi.function_id = f.id
        WHERE f.uuid = @function_uuid
        ORDER BY fi.timestamp DESC
        LIMIT @limit OFFSET @offset
      '''),
      parameters: {
        'function_uuid': functionUuid,
        'limit': limit,
        'offset': offset,
      },
    );

    return result.map((row) {
      return {
        'uuid': row[0].toString(),
        'status': row[1],
        'duration_ms': row[2],
        'error': row[3],
        'timestamp': row[4],
      };
    }).toList();
  }

  /// Create function invocation and return UUID
  static Future<String> createFunctionInvocation({
    required String functionUuid,
    required String status,
    int? durationMs,
    String? error,
  }) async {
    final result = await Database.connection.execute(
      Sql.named('''
        INSERT INTO function_invocations (function_id, status, duration_ms, error)
        SELECT f.id, @status, @duration_ms, @error
        FROM functions f
        WHERE f.uuid = @function_uuid
        RETURNING uuid
      '''),
      parameters: {
        'function_uuid': functionUuid,
        'status': status,
        'duration_ms': durationMs,
        'error': error,
      },
    );

    return result.first[0].toString();
  }

  /// Get internal ID from UUID (for internal use only)
  static Future<int?> getInternalIdFromUuid(String table, String uuid) async {
    final result = await Database.connection.execute(
      Sql.named('''
        SELECT id FROM $table WHERE uuid = @uuid
      '''),
      parameters: {'uuid': uuid},
    );

    if (result.isEmpty) return null;
    return result.first[0] as int;
  }

  /// Get UUID from internal ID (for internal use only)
  static Future<String?> getUuidFromInternalId(String table, int id) async {
    final result = await Database.connection.execute(
      Sql.named('''
        SELECT uuid FROM $table WHERE id = @id
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return result.first[0].toString();
  }
}
