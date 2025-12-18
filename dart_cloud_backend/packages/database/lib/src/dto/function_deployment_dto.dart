import 'package:database/database.dart';

/// DTO for function deployment returned to frontend
class FunctionDeploymentDto {
  final String uuid;
  final int version;
  final String imageTag;
  final String s3Key;
  final String? status;
  final bool? isActive;
  final String? buildLogs;
  final DateTime? deployedAt;

  FunctionDeploymentDto({
    required this.uuid,
    required this.version,
    required this.imageTag,
    required this.s3Key,
    this.status,
    this.isActive,
    this.buildLogs,
    this.deployedAt,
  });

  factory FunctionDeploymentDto.fromEntity(FunctionDeploymentEntity entity) {
    return FunctionDeploymentDto(
      uuid: entity.uuid!,
      version: entity.version,
      imageTag: entity.imageTag,
      s3Key: entity.s3Key,
      status: entity.status,
      isActive: entity.isActive,
      buildLogs: entity.buildLogs,
      deployedAt: entity.deployedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'version': version,
      'image_tag': imageTag,
      's3_key': s3Key,
      if (status != null) 'status': status,
      if (isActive != null) 'is_active': isActive,
      if (buildLogs != null) 'build_logs': buildLogs,
      if (deployedAt != null) 'deployed_at': deployedAt!.toIso8601String(),
    };
  }
}
