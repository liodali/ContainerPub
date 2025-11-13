import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:archive/archive_io.dart';
import 'package:s3_client_dart/s3_client_dart.dart';
import 'package:dart_cloud_backend/config/config.dart';
import 'package:dart_cloud_backend/database/database.dart';
import 'package:dart_cloud_backend/services/function_executor.dart';
import 'package:dart_cloud_backend/services/docker_service.dart';

class FunctionHandler {
  static const _uuid = Uuid();
  static S3Client? _s3Client;

  /// Initialize S3 client (call once at startup)
  static void initializeS3() {
    _s3Client = S3Client();
    _s3Client!.initialize(
      configuration: S3Configuration(
        endpoint: Config.s3Endpoint,
        bucketName: Config.s3BucketName,
        accessKeyId: Config.s3AccessKeyId,
        secretAccessKey: Config.s3SecretAccessKey,
        sessionToken: Config.s3SessionToken ?? '',
        region: Config.s3Region,
        accountId: Config.s3AccountId ?? '',
      ),
    );
  }

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

      // Check if function already exists
      final existingResult = await Database.connection.execute(
        'SELECT id FROM functions WHERE user_id = \$1 AND name = \$2',
        parameters: [userId, functionName],
      );

      String functionId;
      int version = 1;
      bool isNewFunction = existingResult.isEmpty;

      if (isNewFunction) {
        // Create new function
        functionId = _uuid.v4();
        await Database.connection.execute(
          'INSERT INTO functions (id, user_id, name, status) VALUES (\$1, \$2, \$3, \$4)',
          parameters: [functionId, userId, functionName, 'building'],
        );
        await _logFunction(functionId, 'info', 'Creating new function: $functionName');
      } else {
        // Update existing function
        functionId = existingResult.first[0] as String;

        // Get latest version number
        final versionResult = await Database.connection.execute(
          'SELECT COALESCE(MAX(version), 0) FROM function_deployments WHERE function_id = \$1',
          parameters: [functionId],
        );
        version = (versionResult.first[0] as int) + 1;

        // Mark current active deployment as inactive
        await Database.connection.execute(
          'UPDATE function_deployments SET is_active = false WHERE function_id = \$1 AND is_active = true',
          parameters: [functionId],
        );

        // Update function status
        await Database.connection.execute(
          'UPDATE functions SET status = \$1 WHERE id = \$2',
          parameters: ['building', functionId],
        );

        await _logFunction(
          functionId,
          'info',
          'Updating function: $functionName (version $version)',
        );
      }

      // Upload archive to S3 with version
      await _logFunction(functionId, 'info', 'Uploading archive to S3...');
      final s3Key = 'functions/$functionId/v$version/function.tar.gz';

      if (_s3Client == null) {
        initializeS3();
      }

      final uploadResult = await _s3Client!.upload(archiveFile.path, s3Key);
      if (uploadResult.isEmpty) {
        throw Exception('Failed to upload archive to S3');
      }

      await _logFunction(functionId, 'info', 'Archive uploaded to S3: $s3Key');

      // Create function directory with version
      final functionDir = Directory(
        path.join(Config.functionsDir, functionId, 'v$version'),
      );
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

      // Build Docker image with version tag
      await _logFunction(functionId, 'info', 'Building Docker image...');
      final imageTag = await DockerService.buildImage(
        '$functionId-v$version',
        functionDir.path,
      );
      await _logFunction(functionId, 'info', 'Docker image built: $imageTag');

      // Create deployment record
      final deploymentId = _uuid.v4();
      await Database.connection.execute(
        'INSERT INTO function_deployments (id, function_id, version, image_tag, s3_key, status, is_active) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7)',
        parameters: [
          deploymentId,
          functionId,
          version,
          imageTag,
          s3Key,
          'active',
          true,
        ],
      );

      // Update function with active deployment
      await Database.connection.execute(
        'UPDATE functions SET active_deployment_id = \$1, status = \$2 WHERE id = \$3',
        parameters: [deploymentId, 'active', functionId],
      );

      await _logFunction(
        functionId,
        'info',
        'Function deployed successfully (version $version)',
      );

      return Response(
        isNewFunction ? 201 : 200,
        body: jsonEncode({
          'id': functionId,
          'name': functionName,
          'version': version,
          'deploymentId': deploymentId,
          'status': 'active',
          'isNewFunction': isNewFunction,
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

  /// Get deployment history for a function
  static Future<Response> getDeployments(Request request, String id) async {
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

      // Get deployment history
      final deploymentsResult = await Database.connection.execute(
        '''
        SELECT id, version, image_tag, s3_key, status, is_active, deployed_at 
        FROM function_deployments 
        WHERE function_id = \$1 
        ORDER BY version DESC
        ''',
        parameters: [id],
      );

      final deployments = deploymentsResult.map((row) {
        return {
          'id': row[0],
          'version': row[1],
          'imageTag': row[2],
          's3Key': row[3],
          'status': row[4],
          'isActive': row[5],
          'deployedAt': (row[6] as DateTime).toIso8601String(),
        };
      }).toList();

      return Response.ok(
        jsonEncode({'deployments': deployments}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get deployments: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Rollback to a specific deployment version
  static Future<Response> rollback(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString());
      final version = body['version'] as int?;

      if (version == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Version is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

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

      // Get the target deployment
      final deploymentResult = await Database.connection.execute(
        'SELECT id FROM function_deployments WHERE function_id = \$1 AND version = \$2',
        parameters: [id, version],
      );

      if (deploymentResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Deployment version not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final deploymentId = deploymentResult.first[0] as String;

      // Deactivate current active deployment
      await Database.connection.execute(
        'UPDATE function_deployments SET is_active = false WHERE function_id = \$1 AND is_active = true',
        parameters: [id],
      );

      // Activate target deployment
      await Database.connection.execute(
        'UPDATE function_deployments SET is_active = true WHERE id = \$1',
        parameters: [deploymentId],
      );

      // Update function's active deployment
      await Database.connection.execute(
        'UPDATE functions SET active_deployment_id = \$1, status = \$2 WHERE id = \$3',
        parameters: [deploymentId, 'active', id],
      );

      await _logFunction(id, 'info', 'Rolled back to version $version');

      return Response.ok(
        jsonEncode({
          'message': 'Successfully rolled back to version $version',
          'version': version,
          'deploymentId': deploymentId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to rollback: $e'}),
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
