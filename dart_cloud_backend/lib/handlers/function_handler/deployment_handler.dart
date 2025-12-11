import 'dart:convert';
import 'dart:io';
import 'package:dart_cloud_backend/services/docker/docker.dart';
import 'package:dart_cloud_backend/services/s3_service.dart' show S3Service;
import 'package:dart_cloud_backend/utils/archive_utils.dart';
import 'package:dart_cloud_backend/utils/commons.dart' show StringExtension;
import 'package:json2yaml/json2yaml.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:archive/archive_io.dart';
import 'package:s3_client_dart/s3_client_dart.dart';
import 'package:dart_cloud_backend/configuration/config.dart';
import 'package:database/database.dart';
import 'package:dart_cloud_backend/services/function_main_injection.dart';
import 'package:yaml/yaml.dart';
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
    final functDir = Directory(
      '${Config.functionsDir}/dart_cloud_upload_${DateTime.now().millisecondsSinceEpoch}',
    )..createSync(recursive: true);
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
        final contentDisposition = header['content-disposition'];
        // Extract function name from 'name' field
        if (contentDisposition?.retrieveFieldName() == 'name') {
          // Extract function name
          // final fieldBytes =
          // await part.fold<List<int>>(
          //   [],
          //   (prev, element) => prev..addAll(element),
          // );
          functionName = await part.readString(); //utf8.decode(fieldBytes);
        } else
        // Extract archive file from 'archive' field
        if (contentDisposition?.retrieveFieldName() == 'archive') {
          // Create temporary directory for uploaded file
          // final tempDir = Directory.systemTemp.createTempSync(
          //   'dart_cloud_upload_${DateTime.now().millisecondsSinceEpoch}_',
          // );

          final tempFile = File(
            path.join(
              functDir.path,
              '${functionName}.tar.gz',
            ),
          );
          // Stream uploaded file to temporary location
          // final sink = tempFile.openWrite();
          // await part.pipe(sink);
          // await sink.close();
          final bytes = await part.readBytes();
          // final zipper = ZipDecoder().decodeBytes(bytes);
          // final bytes = await part.fold<List<int>>(
          //   [],
          //   (prev, element) => prev..addAll(element),
          // );

          await tempFile.writeAsBytes(bytes);

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

      // Check if user exists
      final userResult = await DatabaseManagers.users.findByUuid(userId);
      if (userResult == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if function with this name already exists for this user
      final functionEntity = await DatabaseManagers.functions.findOne(
        where: {
          FunctionEntityExtension.userIdNameField: userResult.id,
          FunctionEntityExtension.nameField: functionName,
        },
      );

      String functionUUID;
      int functionId;
      int version = 1;
      bool isNewFunction = functionEntity == null;

      if (isNewFunction) {
        // === NEW FUNCTION WORKFLOW ===
        // Generate unique ID for new function
        functionUUID = _uuid.v4();

        // Create function record in database with 'building' status
        final result = await Database.connection.execute(
          'INSERT INTO functions (uuid, user_id, name, status) VALUES (\$1, \$2, \$3, \$4)',
          parameters: [functionUUID, userResult.id, functionName, 'building'],
        );
        functionId = result.first[0] as int;

        // Log function creation
        await FunctionUtils.logFunction(
          functionUUID,
          'info',
          'Creating new function: $functionName',
        );
      } else {
        // === UPDATE EXISTING FUNCTION WORKFLOW ===
        // Get existing function ID
        functionId = functionEntity.id!;
        functionUUID = functionEntity.uuid!;

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
          functionUUID,
          'info',
          'Updating function: $functionName (version $version)',
        );
      }

      // === LOCAL EXTRACTION ===
      // Create versioned directory for function code
      final functionDir = Directory(
        path.join(Config.functionsDir, functionUUID, 'v$version', functionName),
      );
      await functionDir.create(recursive: true);

      // Extract tar.gz archive to function directory
      final inputStream = InputFileStream(archiveFile.path);
      final archive = ZipDecoder().decodeBytes(
        inputStream.toUint8List(),
      );
      extractArchiveToDisk(archive, functionDir.path);
      inputStream.close();

      // === MAIN.DART INJECTION ===
      // Inject main.dart that reads environment and request.json,
      // then invokes the @cloudFunction annotated class
      await FunctionUtils.logFunction(
        functionUUID,
        'info',
        'Injecting DotEnv...',
      );

      await _injectDoEnv(functionDir.path);

      await FunctionUtils.logFunction(
        functionUUID,
        'info',
        'Injecting main.dart...',
      );
      final injectionResult = await FunctionMainInjection.injectMain(
        functionDir.path,
      );
      if (!injectionResult.success) {
        throw Exception(
          'Failed to inject main.dart: ${injectionResult.error ?? "Unknown error"}. '
          'Ensure function has exactly one class extending CloudDartFunction '
          'with @cloudFunction annotation.',
        );
      }

      // === REMOVE dart_cloud_cli FROM DEV_DEPENDENCIES ===
      // Remove dart_cloud_cli from pubspec.yaml to avoid unnecessary dependencies in production
      await _removeDartCloudCliFromPubspec(functionDir.path);

      await FunctionUtils.logFunction(
        functionUUID,
        'info',
        'Removed dart_cloud_cli from dev_dependencies',
      );

      await FunctionUtils.logFunction(
        functionUUID,
        'info',
        'main.dart injected at ${injectionResult.entrypoint}',
      );

      // === S3 UPLOAD (FUNCTION FOLDER) ===
      // Upload the entire function folder to S3 before building Docker image
      await FunctionUtils.logFunction(
        functionUUID,
        'info',
        'Uploading function folder to S3...',
      );

      // S3 key prefix: functions/{function-uuid}/v{version}/
      final s3KeyPrefix = 'functions/$functionUUID/v$version';
      await _uploadFunctionFolderToS3(
        functionName: functionName,
        folderPath: functionDir.path,
        s3KeyPrefix: s3KeyPrefix,
      );

      await FunctionUtils.logFunction(
        functionUUID,
        'info',
        'Function folder uploaded to S3: $s3KeyPrefix',
      );
      print('archieve file received ${archiveFile.path}');
      // Clean up temporary uploaded archive file
      await archiveFile.delete();

      // === DOCKER IMAGE BUILD ===
      // Build Docker image with versioned tag
      await FunctionUtils.logFunction(
        functionUUID,
        'info',
        'Building Docker image with entrypoint: ${injectionResult.entrypoint}...',
      );

      // Image tag format: {registry}/dart-function-{id}-v{version}:latest
      final imageTag = await DockerService.buildImageWithEntrypointStatic(
        '$functionId-v$version',
        functionDir.path,
        injectionResult.entrypoint,
      );

      await FunctionUtils.logFunction(
        functionUUID,
        'info',
        'Docker image built: $imageTag',
      );

      // === CREATE DEPLOYMENT RECORD ===
      // Generate unique ID for this deployment
      final deploymentUUId = _uuid.v4();

      // Store deployment metadata in database
      final result = await DatabaseManagers.functionDeployments.insert({
        'uuid': deploymentUUId,
        'function_id': functionId,
        'version': version,
        'image_tag': imageTag,
        's3_key': s3KeyPrefix,
        'status': 'active',
        'is_active': true,
      });
      // final result = await Database.connection.execute(
      //   'INSERT INTO function_deployments (uuid, function_id, version, image_tag, s3_key, status, is_active) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7)',
      //   parameters: [
      //     deploymentUUId,
      //     functionId,
      //     version,
      //     imageTag,
      //     s3KeyPrefix,
      //     'active',
      //     true, // Mark as active deployment
      //   ],
      // );

      // Update function record with active deployment reference
      await Database.connection.execute(
        'UPDATE functions SET active_deployment_id = \$1, status = \$2 WHERE id = \$3',
        parameters: [result!.id, 'active', functionId],
      );

      // Log successful deployment
      await FunctionUtils.logFunction(
        functionUUID,
        'info',
        'Function deployed successfully (version $version)',
      );

      // Return success response with deployment details
      return Response(
        isNewFunction ? 201 : 200, // 201 for new, 200 for update
        body: jsonEncode({
          'id': functionUUID,
          'name': functionName,
          'version': version,
          'deploymentId': deploymentUUId,
          'status': 'active',
          'isNewFunction': isNewFunction,
          'createdAt': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      functDir.deleteSync(recursive: true);
      // Handle any errors during deployment
      return Response.internalServerError(
        body: jsonEncode({'error': 'Deployment failed: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Remove dart_cloud_cli from dev_dependencies in pubspec.yaml
  static Future<void> _removeDartCloudCliFromPubspec(String functionPath) async {
    final pubspecFile = File(path.join(functionPath, 'pubspec.yaml'));
    if (!(await pubspecFile.exists())) {
      return;
    }

    final content = await pubspecFile.readAsString();
    var docPubspec = loadYaml(content);
    final jsonYaml = json.decode(json.encode(docPubspec));
    final devDep = Map.from(jsonYaml["dev_dependencies"]);
    devDep.remove("dart_cloud_cli");
    if (devDep.isNotEmpty) {
      jsonYaml["dev_dependencies"] = devDep;
    } else {
      jsonYaml.remove("dev_dependencies");
    }
    final Map<String, dynamic> jsonConvYamlTransformed = Map<String, dynamic>.from(
      jsonYaml,
    );
    final newYamlContent = json2yaml(jsonConvYamlTransformed);

    await pubspecFile.writeAsString(newYamlContent);
  }

  /// Remove dart_cloud_cli from dev_dependencies in pubspec.yaml
  static Future<void> _injectDoEnv(String functionPath) async {
    final pubspecFile = File(path.join(functionPath, 'pubspec.yaml'));
    if (!(await pubspecFile.exists())) {
      return;
    }

    final content = await pubspecFile.readAsString();
    var docPubspec = loadYaml(content);
    final jsonYaml = json.decode(json.encode(docPubspec));
    final dependencies = Map<String, dynamic>.from(jsonYaml["dependencies"]);
    dependencies.putIfAbsent('dotenv', () => '^4.2.0');
    jsonYaml["dependencies"] = dependencies;
    final Map<String, dynamic> jsonConvYamlTransformed = Map<String, dynamic>.from(
      jsonYaml,
    );
    final newYamlContent = json2yaml(jsonConvYamlTransformed);

    await pubspecFile.writeAsString(newYamlContent);
  }

  /// Upload entire function folder to S3
  static Future<void> _uploadFunctionFolderToS3({
    required String functionName,
    required String folderPath,
    required String s3KeyPrefix,
  }) async {
    final dirFunction = Directory(folderPath);
    // final files = dir.listSync(recursive: true).whereType<File>();
    final (archiveFile, path) = await dirFunction.createFunctionArchive(
      functionName,
    );
    await _s3Client.upload(archiveFile.path, '$s3KeyPrefix/${functionName}.zip');
  }
}
