import '../entity.dart';

/// Function deployment entity representing the function_deployments table
class FunctionDeploymentEntity extends Entity {
  final int? id;
  final String? uuid;
  final int? functionId;
  final int version;
  final String imageTag;
  final String s3Key;
  final String? status;
  final bool? isActive;
  final String? buildLogs;
  final DateTime? deployedAt;

  FunctionDeploymentEntity({
    this.id,
    this.uuid,
    this.functionId,
    required this.version,
    required this.imageTag,
    required this.s3Key,
    this.status,
    this.isActive,
    this.buildLogs,
    this.deployedAt,
  });

  @override
  String get tableName => 'function_deployments';

  @override
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (functionId != null) 'function_id': functionId,
      'version': version,
      'image_tag': imageTag,
      's3_key': s3Key,
      if (status != null) 'status': status,
      if (isActive != null) 'is_active': isActive,
      if (buildLogs != null) 'build_logs': buildLogs,
      if (deployedAt != null) 'deployed_at': deployedAt,
    };
  }

  static FunctionDeploymentEntity fromMap(Map<String, dynamic> map) {
    return FunctionDeploymentEntity(
      id: map['id'] as int?,
      uuid: map['uuid']?.toString(),
      functionId: map['function_id'] as int?,
      version: map['version'] as int,
      imageTag: map['image_tag'] as String,
      s3Key: map['s3_key'] as String,
      status: map['status'] as String?,
      isActive: map['is_active'] as bool?,
      buildLogs: map['build_logs'] as String?,
      deployedAt: map['deployed_at'] as DateTime?,
    );
  }

  FunctionDeploymentEntity copyWith({
    int? id,
    String? uuid,
    int? functionId,
    int? version,
    String? imageTag,
    String? s3Key,
    String? status,
    bool? isActive,
    String? buildLogs,
    DateTime? deployedAt,
  }) {
    return FunctionDeploymentEntity(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      functionId: functionId ?? this.functionId,
      version: version ?? this.version,
      imageTag: imageTag ?? this.imageTag,
      s3Key: s3Key ?? this.s3Key,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      buildLogs: buildLogs ?? this.buildLogs,
      deployedAt: deployedAt ?? this.deployedAt,
    );
  }
}
