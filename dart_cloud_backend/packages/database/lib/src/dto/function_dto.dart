import 'package:database/database.dart';

/// DTO for function returned to frontend
class FunctionDto {
  final String uuid;
  final String name;
  final String? status;
  final int? activeDeploymentId;
  final Map<String, dynamic>? analysisResult;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FunctionDto({
    required this.uuid,
    required this.name,
    this.status,
    this.activeDeploymentId,
    this.analysisResult,
    this.createdAt,
    this.updatedAt,
  });

  factory FunctionDto.fromEntity(FunctionEntity entity) {
    return FunctionDto(
      uuid: entity.uuid!,
      name: entity.name,
      status: entity.status,
      activeDeploymentId: entity.activeDeploymentId,
      analysisResult: entity.analysisResult,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      if (status != null) 'status': status,
      if (activeDeploymentId != null)
        'active_deployment_id': activeDeploymentId,
      if (analysisResult != null) 'analysis_result': analysisResult,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
