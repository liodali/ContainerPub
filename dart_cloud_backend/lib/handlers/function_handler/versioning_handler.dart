import 'dart:convert';
import 'package:dart_cloud_backend/handlers/logs_utils/log_utils.dart';
import 'package:dart_cloud_backend/services/docker/docker.dart';
import 'package:dart_cloud_backend/services/functions_services/function_rollback.dart';
import 'package:dart_cloud_backend/services/s3_service.dart';
import 'package:dart_cloud_backend/utils/commons.dart';
import 'package:shelf/shelf.dart';
import 'package:database/database.dart';
import 'package:dart_cloud_backend/handlers/logs_utils/functions_utils.dart';

enum VersioningResultAction {
  rollbackFailed,
  rollbackFunctionDone,
}

/// Handles function versioning and deployment history operations
///
/// This handler manages deployment versions and provides rollback capabilities:
/// - View complete deployment history
/// - Rollback to previous versions
/// - Track active deployments
/// - Manage version lifecycle
class VersioningHandler {
  /// Get deployment history for a function
  ///
  /// Returns all deployment versions for a function, ordered by version
  /// number descending (newest first). Each deployment includes:
  /// - Version number (auto-incremented)
  /// - Docker image tag
  /// - S3 archive location
  /// - Deployment status
  /// - Active/inactive flag
  /// - Deployment timestamp
  ///
  /// This information is useful for:
  /// - Auditing deployment history
  /// - Identifying which version is currently active
  /// - Selecting a version for rollback
  /// - Tracking deployment frequency
  ///
  /// Response format:
  /// ```json
  /// {
  ///   "deployments": [
  ///     {
  ///       "id": "uuid",
  ///       "version": 3,
  ///       "imageTag": "localhost:5000/dart-function-id-v3:latest",
  ///       "s3Key": "functions/id/v3/function.tar.gz",
  ///       "status": "active",
  ///       "isActive": true,
  ///       "deployedAt": "2024-01-03T00:00:00Z"
  ///     }
  ///   ]
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [id]: Function UUID
  ///
  /// Response codes:
  /// - 200: Deployment history retrieved
  /// - 404: Function not found or access denied
  /// - 500: Failed to retrieve history
  static Future<Response> getDeployments(Request request, String uuid) async {
    try {
      // Extract user ID from authenticated request
      final userId = request.context['userId'] as String;

      // === VERIFY FUNCTION OWNERSHIP ===
      // Check that function exists and belongs to requesting user
      final functionEntity = await DatabaseManagers.functions.findOne(
        where: {'uuid': uuid, 'user_id': userId},
        select: ['id', 'name', 'status'],
      );

      // Return 404 if function not found or access denied
      if (functionEntity == null) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // === RETRIEVE DEPLOYMENT HISTORY ===
      // Query all deployments for this function using internal ID
      // Ordered by version descending (newest first)
      final deploymentsResult = await DatabaseManagers.functionDeployments.findAll(
        where: {'function_id': functionEntity.id},
        select: [
          'uuid',
          'version',
          'image_tag',
          's3_key',
          'status',
          'is_active',
          'deployed_at',
        ],
        orderBy: 'version desc',
      );

      // Map database rows to JSON objects
      final deployments = deploymentsResult.map((deploy) {
        return deploy.toMap();
      }).toList();

      // Return deployment history with function info
      return Response.ok(
        jsonEncode({
          'function_uuid': uuid,
          'function_name': functionEntity.name,
          'function_status': functionEntity.status,
          'deployments': deployments,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // Handle database or other errors
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get deployments: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Rollback function to a specific deployment version
  ///
  /// This operation performs an instant rollback by switching the active
  /// deployment pointer. No rebuild is required since the Docker image
  /// and S3 archive already exist.
  ///
  /// Rollback process:
  /// 1. Verify function ownership
  /// 2. Check that target version exists
  /// 3. Deactivate current deployment
  /// 4. Activate target deployment
  /// 5. Update function's active_deployment_id
  /// 6. Log rollback event
  ///
  /// The rollback is atomic and causes zero downtime. The next function
  /// invocation will use the rolled-back version.
  ///
  /// Request format:
  /// ```json
  /// {
  ///   "version": 2
  /// }
  /// ```
  ///
  /// Response format:
  /// ```json
  /// {
  ///   "message": "Successfully rolled back to version 2",
  ///   "version": 2,
  ///   "deploymentId": "uuid"
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [id]: Function UUID
  ///
  /// Response codes:
  /// - 200: Rollback successful
  /// - 400: Invalid request (missing version)
  /// - 404: Function or version not found
  /// - 500: Rollback failed
  static Future<Response> rollback(Request request, String uuid) async {
    try {
      // Extract user ID from authenticated request
      final userUuid = request.context['userId'] as String;
      final user = await DatabaseManagers.users.findOne(
        where: {'uuid': userUuid},
        select: ['id'],
      );
      final userId = user!.id;

      // Parse request body to get target version
      final body = jsonDecode(await request.readAsString());
      final version = body['version'] as int?;

      // Validate that version is provided
      if (version == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Version is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // === VERIFY FUNCTION OWNERSHIP ===
      // Check that function exists and belongs to requesting user
      final functionEntity = await DatabaseManagers.functions.findOne(
        where: {'uuid': uuid, 'user_id': userId},
        select: ['user_id', 'name', 'id'],
      );
      // final funcResult = await Database.connection.execute(
      //   'SELECT id FROM functions WHERE uuid = \$1 AND user_id = \$2',
      //   parameters: [uuid, userId],
      // );

      // Return 404 if function not found or access denied
      if (functionEntity == null) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // === VERIFY TARGET DEPLOYMENT EXISTS ===
      // Check that the specified version exists for this function
      final deploymentEntity = await DatabaseManagers.functionDeployments.findOne(
        where: {'function_id': functionEntity.id, 'version': version},
        select: ['id'],
      );
      // final deploymentResult = await Database.connection.execute(
      //   'SELECT id FROM function_deployments WHERE function_id = \$1 AND version = \$2',
      //   parameters: [id, version],
      // );

      // Return 404 if version doesn't exist
      if (deploymentEntity == null) {
        return Response.notFound(
          jsonEncode({
            'error': 'We cannot rollback to version $version: deployment not found',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
      // Get deployment ID for target version
      final deploymentId = deploymentEntity.id;

      // === PERFORM DOCKER/S3 ROLLBACK ===
      // This rebuilds the Docker image from S3 archive if needed
      final result = await rollbackFunctionDeployment(
        functionId: functionEntity.id!,
        functionName: functionEntity.name,
        functionUUId: functionEntity.uuid!,
        version: version,
        imageTag: deploymentEntity.imageTag,
        s3Key: deploymentEntity.s3Key,
      );
      if (result != VersioningResultAction.rollbackFunctionDone) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'Rollback failed: could not restore Docker image',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // === UPDATE DATABASE (ATOMIC TRANSACTION) ===
      // Only update DB after Docker image is confirmed ready
      // Use transaction to ensure all-or-nothing update
      await Database.transaction((conn) async {
        // Step 1: Deactivate current active deployment
        await conn.execute(
          'UPDATE function_deployments SET is_active = false WHERE function_id = \$1 AND is_active = true',
          parameters: [functionEntity.id],
        );

        // Step 2: Activate target deployment
        await conn.execute(
          'UPDATE function_deployments SET is_active = true WHERE id = \$1',
          parameters: [deploymentId],
        );

        // Step 3: Update function's active deployment reference
        await conn.execute(
          'UPDATE functions SET active_deployment_id = \$1, status = \$2 WHERE id = \$3',
          parameters: [
            deploymentId,
            DeploymentStatus.active.name,
            functionEntity.id,
          ],
        );
      });

      // Log rollback event for audit trail
      await FunctionUtils.logDeploymentFunction(
        uuid,
        'info',
        'Rolled back to version $version',
      );

      // Return success response with rollback details
      return Response.ok(
        jsonEncode({
          'message': 'Successfully rolled back to version $version',
          'version': version,
          'deploymentId': deploymentId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      // Handle database or other errors
      LogsUtils.log('error', 'rollback functon', {
        'error': e.toString(),
        'trace': trace.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Ops!Failed to rollback',
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );
    }
  }

  /// Ensures Docker image exists for the target version.
  ///
  /// Strategy:
  /// 1. Check if Docker image already exists → success (fast path)
  /// 2. If not, verify S3 archive exists (required for rebuild)
  /// 3. Download from S3 and rebuild Docker image
  /// 4. Verify rebuilt image exists
  static Future<VersioningResultAction> rollbackFunctionDeployment({
    required int functionId,
    required String functionUUId,
    required String functionName,
    required int version,
    required String imageTag,
    required String s3Key,
  }) async {
    // Fast path: Docker image already exists
    final isImageExist = await DockerService.isContainerImageExist(imageTag);
    if (isImageExist) {
      // Log that we're using existing image
      await FunctionUtils.logDeploymentFunction(
        functionUUId,
        'info',
        'Rollback to v$version: Using existing Docker image',
      );
      return VersioningResultAction.rollbackFunctionDone;
    }

    // Image doesn't exist - need to rebuild from S3
    // First verify S3 archive exists
    final s3Exists = await S3Service.s3Client.isKeyBucketExist(s3Key);
    if (!s3Exists) {
      await FunctionUtils.logDeploymentFunction(
        functionUUId,
        'error',
        'Rollback to v$version failed: S3 archive not found at $s3Key',
      );
      return VersioningResultAction.rollbackFailed;
    }

    // Rebuild from S3 archive
    final result = await FunctionRollback.rollbackFunctionDeployment(
      functionId: functionId,
      functionUUId: functionUUId,
      functionName: functionName,
      version: version,
      s3key: s3Key,
    );

    if (result) {
      return VersioningResultAction.rollbackFunctionDone;
    } else {
      return VersioningResultAction.rollbackFailed;
    }
  }
}
