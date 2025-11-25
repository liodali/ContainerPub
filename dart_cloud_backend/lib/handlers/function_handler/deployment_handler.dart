import 'dart:convert';
import 'dart:io';
import 'package:dart_cloud_backend/services/s3_service.dart' show S3Service;
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:archive/archive_io.dart';
import 'package:s3_client_dart/s3_client_dart.dart';
import 'package:dart_cloud_backend/config/config.dart';
import 'package:database/database.dart';
import 'package:dart_cloud_backend/services/docker_service.dart';
import 'package:dart_cloud_backend/services/function_main_injection.dart';
import 'utils.dart';

/// Handles function deployment operations including:
/// - Creating new functions
/// - Updating existing functions with versioning
/// - Uploading archives to S3
/// - Building Docker images
/// - Managing deployment history
class DeploymentHandler {
  static const _uuid = Uuid();
  static late S3Client _s3Client = S3Service.s3Client;

  /// Deploy a new function or update an existing one
  ///
  /// This endpoint handles the complete deployment workflow:
  /// 1. Parse multipart request (function name + archive)
  /// 2. Check if function exists (new vs update)
  /// 3. Upload archive to S3 with versioning
  /// 4. Extract archive locally
  /// 5. Build Docker image
  /// 6. Create deployment record
  /// 7. Update function status
  ///
  /// Request format:
  /// - Content-Type: multipart/form-data
  /// - Fields: name (string), archive (file)
  ///
  /// Response:
  /// - 201: New function created
  /// - 200: Existing function updated
  /// - 400: Invalid request
  /// - 500: Deployment failed
  static Future<Response> deploy(Request request) async {
    try {
      // Extract user ID from authenticated request context
      final userId = request.context['userId'] as String;

      // Validate that request is multipart (required for file upload)
      if (request.multipart() == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Multipart request required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Parse multipart request to extract function name and archive file
      String? functionName;
      File? archiveFile;
      final multipart = request.multipart()!;

      await for (final part in multipart.parts) {
        final header = part.headers;
        // Extract function name from 'name' field
        if (header['name'] == 'name') {
          // Extract function name
          final fieldBytes = await part.fold<List<int>>(
            [],
            (prev, element) => prev..addAll(element),
          );
          functionName = utf8.decode(fieldBytes);
        } else
        // Extract archive file from 'archive' field
        if (header['name'] == 'archive') {
          // Create temporary directory for uploaded file
          final tempDir = Directory.systemTemp.createTempSync(
            'dart_cloud_upload_${DateTime.now().millisecondsSinceEpoch}_',
          );
          final tempFile = File(path.join(tempDir.path, 'function.tar.gz'));

          // Stream uploaded file to temporary location
          final sink = tempFile.openWrite();
          await part.pipe(sink);
          await sink.close();

          archiveFile = tempFile;
        }
      }

      // Validate that both required fields are present
      if (functionName == null || archiveFile == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing function name or archive'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if function with this name already exists for this user
      final existingResult = await Database.connection.execute(
        'SELECT id,uuid FROM functions WHERE user_id = \$1 AND name = \$2',
        parameters: [userId, functionName],
      );

      String functionUUID;
      String functionId;
      int version = 1;
      bool isNewFunction = existingResult.isEmpty;

      if (isNewFunction) {
        // === NEW FUNCTION WORKFLOW ===
        // Generate unique ID for new function
        functionUUID = _uuid.v4();

        // Create function record in database with 'building' status
        final result = await Database.connection.execute(
          'INSERT INTO functions (uuid, user_id, name, status) VALUES (\$1, \$2, \$3, \$4)',
          parameters: [functionUUID, userId, functionName, 'building'],
        );
        functionId = result.first[0] as String;

        // Log function creation
        await FunctionUtils.logFunction(
          functionUUID,
          'info',
          'Creating new function: $functionName',
        );
      } else {
        // === UPDATE EXISTING FUNCTION WORKFLOW ===
        // Get existing function ID
        functionId = existingResult.first[0] as String;
        functionUUID = existingResult.first[1] as String;

        // Get the latest version number for this function
        final versionResult = await Database.connection.execute(
          'SELECT COALESCE(MAX(version), 0) FROM function_deployments WHERE function_id = \$1',
          parameters: [functionId],
        );
        // Increment version for new deployment
        version = (versionResult.first[0] as int) + 1;

        // Mark current active deployment as inactive (old version)
        await Database.connection.execute(
          'UPDATE function_deployments SET is_active = false WHERE function_id = \$1 AND is_active = true',
          parameters: [functionId],
        );

        // Update function status to 'building' during deployment
        await Database.connection.execute(
          'UPDATE functions SET status = \$1 WHERE id = \$2',
          parameters: ['building', functionId],
        );

        // Log function update
        await FunctionUtils.logFunction(
          functionId,
          'info',
          'Updating function: $functionName (version $version)',
        );
      }

      // === S3 UPLOAD ===
      // Upload archive to S3 with versioned path
      await FunctionUtils.logFunction(
        functionId,
        'info',
        'Uploading archive to S3...',
      );

      // S3 key format: functions/{function-id}/v{version}/function.tar.gz
      final s3Key = 'functions/$functionId/v$version/function.tar.gz';

      // Upload file to S3
      final uploadResult = await _s3Client.upload(archiveFile.path, s3Key);
      if (uploadResult.isEmpty) {
        throw Exception('Failed to upload archive to S3');
      }

      await FunctionUtils.logFunction(
        functionId,
        'info',
        'Archive uploaded to S3: $s3Key',
      );

      // === LOCAL EXTRACTION ===
      // Create versioned directory for function code
      final functionDir = Directory(
        path.join(Config.functionsDir, functionId, 'v$version'),
      );
      await functionDir.create(recursive: true);

      // Extract tar.gz archive to function directory
      final inputStream = InputFileStream(archiveFile.path);
      final archive = TarDecoder().decodeBytes(
        GZipDecoder().decodeBytes(inputStream.toUint8List()),
      );
      extractArchiveToDisk(archive, functionDir.path);
      inputStream.close();

      // Clean up temporary uploaded file
      await archiveFile.delete();

      // === MAIN.DART INJECTION ===
      // Inject main.dart that reads environment and request.json,
      // then invokes the @cloudFunction annotated class
      await FunctionUtils.logFunction(
        functionId,
        'info',
        'Injecting main.dart...',
      );
      final injectionSuccess = await FunctionMainInjection.injectMain(
        functionDir.path,
      );

      if (!injectionSuccess) {
        throw Exception(
          'Failed to inject main.dart. Ensure function has exactly one class '
          'extending CloudDartFunction with @cloudFunction annotation.',
        );
      }

      await FunctionUtils.logFunction(
        functionId,
        'info',
        'main.dart injected successfully',
      );

      // === DOCKER IMAGE BUILD ===
      // Build Docker image with versioned tag
      await FunctionUtils.logFunction(
        functionId,
        'info',
        'Building Docker image...',
      );

      // Image tag format: {registry}/dart-function-{id}-v{version}:latest
      final imageTag = await DockerService.buildImage(
        '$functionId-v$version',
        functionDir.path,
      );

      await FunctionUtils.logFunction(
        functionId,
        'info',
        'Docker image built: $imageTag',
      );

      // === CREATE DEPLOYMENT RECORD ===
      // Generate unique ID for this deployment
      final deploymentId = _uuid.v4();

      // Store deployment metadata in database
      await Database.connection.execute(
        'INSERT INTO function_deployments (id, function_id, version, image_tag, s3_key, status, is_active) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7)',
        parameters: [
          deploymentId,
          functionId,
          version,
          imageTag,
          s3Key,
          'active',
          true, // Mark as active deployment
        ],
      );

      // Update function record with active deployment reference
      await Database.connection.execute(
        'UPDATE functions SET active_deployment_id = \$1, status = \$2 WHERE id = \$3',
        parameters: [deploymentId, 'active', functionId],
      );

      // Log successful deployment
      await FunctionUtils.logFunction(
        functionId,
        'info',
        'Function deployed successfully (version $version)',
      );

      // Return success response with deployment details
      return Response(
        isNewFunction ? 201 : 200, // 201 for new, 200 for update
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
      // Handle any errors during deployment
      return Response.internalServerError(
        body: jsonEncode({'error': 'Deployment failed: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
