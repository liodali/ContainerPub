import 'dart:io';

import 'package:dart_cloud_backend/configuration/config.dart';
import 'package:dart_cloud_backend/handlers/logs/functions_utils.dart';

import 'package:dart_cloud_backend/handlers/logs/log_utils.dart';
import 'package:dart_cloud_backend/services/docker/docker.dart';
import 'package:dart_cloud_backend/services/s3_service.dart' show S3Service;
import 'package:dart_cloud_backend/utils/archive_utils.dart';

class FunctionRollback {
  static FunctionRollback instance = FunctionRollback._();

  FunctionRollback._();

  static FunctionRollback getInstance() {
    return instance;
  }

  static Future<bool> rollbackFunctionDeployment({
    required int functionId,
    required String functionUUId,
    required String functionName,
    required int version,
    required String s3key,
  }) {
    return instance.rollbackDeployment(
      functionId,
      functionUUId,
      functionName,
      version,
      s3key,
    );
  }

  Future<bool> rollbackDeployment(
    int functionId,
    String functionUUId,
    String functionName,
    int version,
    String s3key,
  ) async {
    final folderFunction = '${Config.functionsDir}/$functionUUId/$version';
    final zipPath = '$folderFunction/$functionName.zip';

    try {
      // === STEP 1: DOWNLOAD FROM S3 ===
      await FunctionUtils.logDeploymentFunction(
        functionUUId,
        'info',
        'Downloading function from S3: $s3key',
      );

      final downloadResult = await S3Service.s3Client.download(s3key, zipPath);
      if (downloadResult.isNotEmpty) {
        await FunctionUtils.logDeploymentFunction(
          functionUUId,
          'error',
          'Failed to download function for rollback: $downloadResult',
        );
        return false;
      }

      // Verify download succeeded
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        await FunctionUtils.logDeploymentFunction(
          functionUUId,
          'error',
          'Downloaded file not found at: $zipPath',
        );
        return false;
      }

      // === STEP 2: EXTRACT ARCHIVE ===
      await FunctionUtils.logDeploymentFunction(
        functionUUId,
        'info',
        'Extracting function...',
      );

      try {
        await ArchiveUtility.extractZipFile(zipPath, folderFunction);
      } catch (extractError, trace) {
        await FunctionUtils.logDeploymentFunction(
          functionUUId,
          'error',
          'Failed to extract archive',
        );
        LogsUtils.log(
          'error',
          'function rollback',
          {
            'error': extractError.toString(),
            'trace': trace.toString(),
          },
        );
        await _cleanupOnFailure(folderFunction, zipPath);
        return false;
      }

      // Verify extraction - check for pubspec.yaml as indicator
      final pubspecFile = File('$folderFunction/pubspec.yaml');
      if (!await pubspecFile.exists()) {
        await FunctionUtils.logDeploymentFunction(
          functionUUId,
          'error',
          'Extraction verification failed: pubspec.yaml not found',
        );
        await _cleanupOnFailure(folderFunction, zipPath);
        return false;
      }

      // === STEP 3: BUILD DOCKER IMAGE ===
      await FunctionUtils.logDeploymentFunction(
        functionUUId,
        'info',
        'Rolling back to version $version: Building function',
      );

      String imageTag;
      try {
        imageTag = await DockerService.buildImageStatic(
          '$functionId-v$version',
          functionName,
          folderFunction,
        );
      } catch (buildError) {
        await FunctionUtils.logDeploymentFunction(
          functionUUId,
          'error',
          'Docker build failed: $buildError',
        );
        await _cleanupOnFailure(folderFunction, zipPath);
        return false;
      }

      // Verify image was created
      final imageExists = await DockerService.isContainerImageExist(imageTag);
      if (!imageExists) {
        await FunctionUtils.logDeploymentFunction(
          functionUUId,
          'error',
          'Docker image verification failed: $imageTag not found after build',
        );
        await _cleanupOnFailure(folderFunction, zipPath);
        return false;
      }

      // === SUCCESS ===
      await FunctionUtils.logDeploymentFunction(
        functionUUId,
        'info',
        'Rollback to version $version completed successfully',
      );

      // Cleanup zip file after successful build (keep extracted files)
      await _cleanupZipFile(zipPath);

      return true;
    } catch (e) {
      await FunctionUtils.logDeploymentFunction(
        functionUUId,
        'error',
        'Unexpected error during rollback: $e',
      );
      await _cleanupOnFailure(folderFunction, zipPath);
      return false;
    }
  }

  /// Cleanup temporary files on failure
  Future<void> _cleanupOnFailure(String folderPath, String zipPath) async {
    try {
      // Remove zip file
      await _cleanupZipFile(zipPath);

      // Remove extracted folder contents but keep the version folder
      // (in case there are other files we shouldn't delete)
      final folder = Directory(folderPath);
      if (await folder.exists()) {
        await for (final entity in folder.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {
            // Ignore cleanup errors
          }
        }
      }
    } catch (_) {
      // Ignore cleanup errors - best effort
    }
  }

  /// Cleanup zip file after successful extraction
  Future<void> _cleanupZipFile(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
    } catch (_) {
      // Ignore cleanup errors
    }
  }
}
