import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';

/// Annotation to mark this as a cloud function
const function = 'function';

/// Main entry point for the cloud function with database access
@function
void main() async {
  try {
    // Read HTTP request from environment
    final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');

    // Extract body and query parameters
    final body = input['body'] as Map<String, dynamic>? ?? {};
    final query = input['query'] as Map<String, dynamic>? ?? {};

    // Call the handler
    final result = await handler(body, query);

    // Return JSON response to stdout
    print(jsonEncode(result));
  } catch (e) {
    // Return error response
    print(jsonEncode({
      'error': 'Function execution failed',
      'message': e.toString(),
    }));
    exit(1);
  }
}

/// Handler function that accesses database with timeout protection
@function
Future<Map<String, dynamic>> handler(
  Map<String, dynamic> body,
  Map<String, dynamic> query,
) async {
  // Get database URL from environment (provided by platform)
  final databaseUrl = Platform.environment['DATABASE_URL'];

  if (databaseUrl == null) {
    return {
      'success': false,
      'error': 'Database access not configured',
    };
  }

  // Get timeout from environment (enforced by platform)
  final timeoutMs = int.tryParse(
        Platform.environment['DB_TIMEOUT_MS'] ?? '5000',
      ) ??
      5000;

  Connection? connection;

  try {
    // Parse database URL
    final uri = Uri.parse(databaseUrl);

    // Connect with timeout (max 5 seconds as enforced by platform)
    connection = await Connection.open(
      Endpoint(
        host: uri.host,
        port: uri.port,
        database: uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : 'db',
        username: uri.userInfo.split(':').first,
        password: uri.userInfo.contains(':') ? uri.userInfo.split(':')[1] : '',
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
        connectTimeout: Duration(milliseconds: timeoutMs),
      ),
    ).timeout(Duration(milliseconds: timeoutMs));

    // Example: Query with timeout
    final action = body['action'] as String? ?? 'list';

    switch (action) {
      case 'list':
        return await _listItems(connection, timeoutMs);
      case 'get':
        final id = body['id'] as String?;
        if (id == null) {
          return {'success': false, 'error': 'ID required'};
        }
        return await _getItem(connection, id, timeoutMs);
      case 'create':
        final name = body['name'] as String?;
        if (name == null) {
          return {'success': false, 'error': 'Name required'};
        }
        return await _createItem(connection, name, timeoutMs);
      default:
        return {
          'success': false,
          'error': 'Unknown action: $action',
        };
    }
  } on TimeoutException {
    return {
      'success': false,
      'error': 'Database operation timed out',
    };
  } catch (e) {
    return {
      'success': false,
      'error': 'Database error: ${e.toString()}',
    };
  } finally {
    // Always close connection
    await connection?.close();
  }
}

/// List items with timeout
Future<Map<String, dynamic>> _listItems(
  Connection connection,
  int timeoutMs,
) async {
  final result = await connection
      .execute('SELECT id, name, created_at FROM items LIMIT 10')
      .timeout(Duration(milliseconds: timeoutMs));

  final items = result.map((row) {
    return {
      'id': row[0],
      'name': row[1],
      'createdAt': (row[2] as DateTime).toIso8601String(),
    };
  }).toList();

  return {
    'success': true,
    'items': items,
    'count': items.length,
  };
}

/// Get single item with timeout
Future<Map<String, dynamic>> _getItem(
  Connection connection,
  String id,
  int timeoutMs,
) async {
  final result = await connection.execute(
    'SELECT id, name, created_at FROM items WHERE id = \$1',
    parameters: [id],
  ).timeout(Duration(milliseconds: timeoutMs));

  if (result.isEmpty) {
    return {
      'success': false,
      'error': 'Item not found',
    };
  }

  final row = result.first;
  return {
    'success': true,
    'item': {
      'id': row[0],
      'name': row[1],
      'createdAt': (row[2] as DateTime).toIso8601String(),
    },
  };
}

/// Create item with timeout
Future<Map<String, dynamic>> _createItem(
  Connection connection,
  String name,
  int timeoutMs,
) async {
  final result = await connection.execute(
    'INSERT INTO items (name) VALUES (\$1) RETURNING id, name, created_at',
    parameters: [name],
  ).timeout(Duration(milliseconds: timeoutMs));

  final row = result.first;
  return {
    'success': true,
    'item': {
      'id': row[0],
      'name': row[1],
      'createdAt': (row[2] as DateTime).toIso8601String(),
    },
  };
}
