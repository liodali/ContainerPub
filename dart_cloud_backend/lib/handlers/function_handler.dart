import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:archive/archive_io.dart';
import 'package:dart_cloud_backend/config/config.dart';
import 'package:dart_cloud_backend/database/database.dart';
import 'package:dart_cloud_backend/services/function_executor.dart';

class FunctionHandler {
  static const _uuid = Uuid();

  static Future<Response> deploy(Request request) async {
    try {
      final userId = request.context['userId'] as String;

      if (request.multipart() == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Multipart request required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      String? functionName;
      File? archiveFile;
      final multipart = request.multipart()!;
      await for (final part in multipart.parts) {
        final header = part.headers;
        if (header['name'] == 'name') {
          functionName = await part.readString();
        } else if (header['name'] == 'archive') {
          final tempDir = Directory.systemTemp.createTempSync(
            'dart_cloud_upload_',
          );
          final tempFile = File(path.join(tempDir.path, 'function.tar.gz'));
          final sink = tempFile.openWrite();
          await part.pipe(sink);
          await sink.close();
          archiveFile = tempFile;
        }
      }

      if (functionName == null || archiveFile == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing function name or archive'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Generate function ID
      final functionId = _uuid.v4();

      // Create function directory
      final functionDir = Directory(path.join(Config.functionsDir, functionId));
      await functionDir.create(recursive: true);

      // Extract archive
      final inputStream = InputFileStream(archiveFile.path);
      final archive = TarDecoder().decodeBytes(
        GZipDecoder().decodeBytes(inputStream.toUint8List()),
      );
      extractArchiveToDisk(archive, functionDir.path);
      inputStream.close();

      // Clean up temp file
      await archiveFile.delete();

      // Store function metadata in database
      await Database.connection.execute(
        'INSERT INTO functions (id, user_id, name, status) VALUES (\$1, \$2, \$3, \$4)',
        parameters: [
          functionId,
          userId,
          functionName,
          'active',
        ],
      );

      await _logFunction(functionId, 'info', 'Function deployed successfully');

      return Response(
        201,
        body: jsonEncode({
          'id': functionId,
          'name': functionName,
          'status': 'active',
          'createdAt': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Deployment failed: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> list(Request request) async {
    try {
      final userId = request.context['userId'] as String;

      final result = await Database.connection.execute(
        'SELECT id, name, status, created_at FROM functions WHERE user_id = \$1 ORDER BY created_at DESC',
        parameters: [userId],
      );

      final functions = result.map((row) {
        return {
          'id': row[0],
          'name': row[1],
          'status': row[2],
          'createdAt': (row[3] as DateTime).toIso8601String(),
        };
      }).toList();

      return Response.ok(
        jsonEncode(functions),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to list functions: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> get(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      final result = await Database.connection.execute(
        'SELECT id, name, status, created_at FROM functions WHERE id = \$1 AND user_id = \$2',
        parameters: [id, userId],
      );

      if (result.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

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
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get function: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> getLogs(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      // Verify function ownership
      final funcResult = await Database.connection.execute(
        'SELECT id FROM functions WHERE id = \$1 AND user_id = \$2',
        parameters: [id, userId],
      );

      if (funcResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get logs
      final logsResult = await Database.connection.execute(
        'SELECT level, message, timestamp FROM function_logs WHERE function_id = \$1 ORDER BY timestamp DESC LIMIT 100',
        parameters: [id],
      );

      final logs = logsResult.map((row) {
        return {
          'level': row[0],
          'message': row[1],
          'timestamp': (row[2] as DateTime).toIso8601String(),
        };
      }).toList();

      return Response.ok(
        jsonEncode({'logs': logs}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get logs: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> delete(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      // Verify function ownership
      final result = await Database.connection.execute(
        'SELECT id FROM functions WHERE id = \$1 AND user_id = \$2',
        parameters: [id, userId],
      );

      if (result.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Delete function directory
      final functionDir = Directory(path.join(Config.functionsDir, id));
      if (await functionDir.exists()) {
        await functionDir.delete(recursive: true);
      }

      // Delete from database (cascades to logs and invocations)
      await Database.connection.execute(
        'DELETE FROM functions WHERE id = \$1',
        parameters: [id],
      );

      return Response.ok(
        jsonEncode({'message': 'Function deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete function: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> invoke(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      // Verify function ownership
      final result = await Database.connection.execute(
        'SELECT id, name FROM functions WHERE id = \$1 AND user_id = \$2',
        parameters: [id, userId],
      );

      if (result.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Execute function
      final startTime = DateTime.now();
      final executor = FunctionExecutor(id);
      final executionResult = await executor.execute(body);

      final duration = DateTime.now().difference(startTime).inMilliseconds;

      // Log invocation
      await Database.connection.execute(
        'INSERT INTO function_invocations (function_id, status, duration_ms, error) VALUES (\$1, \$2, \$3, \$4)',
        parameters: [
          id,
          executionResult['success'] == true ? 'success' : 'error',
          duration,
          executionResult['error'],
        ],
      );

      await _logFunction(
        id,
        executionResult['success'] == true ? 'info' : 'error',
        executionResult['success'] == true
            ? 'Function executed successfully in ${duration}ms'
            : 'Function execution failed: ${executionResult['error']}',
      );

      return Response.ok(
        jsonEncode({
          'success': executionResult['success'],
          'result': executionResult['result'],
          'error': executionResult['error'],
          'duration_ms': duration,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to invoke function: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<void> _logFunction(
    String functionId,
    String level,
    String message,
  ) async {
    try {
      await Database.connection.execute(
        'INSERT INTO function_logs (function_id, level, message) VALUES (\$1, \$2, \$3)',
        parameters: [functionId, level, message],
      );
    } catch (e) {
      print('Failed to log function: $e');
    }
  }
}
