import 'package:dart_cloud_backend/configuration/config.dart';
import 'package:dart_cloud_backend/handlers/function_handler/utils.dart'
    show FunctionUtils;
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
    required String functionUUId,
    required String functionName,
    required int version,
    required String s3key,
  }) {
    return instance.rollbackDeployment(
      functionUUId,
      functionName,
      version,
      s3key,
    );
  }

  Future<bool> rollbackDeployment(
    String functionUUId,
    String functionName,
    int version,
    String s3key,
  ) async {
    await FunctionUtils.logFunction(
      functionUUId,
      'info',
      'Downloading function from S3: $s3key',
    );
    final folderFunction = '${Config.functionsDir}/$functionUUId/$version';
    final path = '$folderFunction/${functionName}.zip';
    final result = await S3Service.s3Client.download(s3key, path);
    if (result.isNotEmpty) {
      await FunctionUtils.logFunction(
        functionUUId,
        'error',
        'Fail to download function: $result from s3 bucket',
      );
      return false;
    }
    // === DOCKER IMAGE BUILD ===
    // Build Docker image with versioned tag
    await FunctionUtils.logFunction(
      functionUUId,
      'info',
      'Extracting Docker image...',
    );
    await ArchiveUtility.extractZipFile(path, folderFunction);
    // === DOCKER IMAGE BUILD ===
    // Build Docker image with versioned tag
    await FunctionUtils.logFunction(
      functionUUId,
      'info',
      'Rolling back to version $version: Building Docker image',
    );
    await DockerService.buildImageStatic(functionUUId, folderFunction);

    await FunctionUtils.logFunction(
      functionUUId,
      'info',
      'Rollback to version $version completed successfully',
    );

    return true;
  }
}
