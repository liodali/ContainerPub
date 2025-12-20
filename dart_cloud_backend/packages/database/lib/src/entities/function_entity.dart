import '../entity.dart';

/// Function entity representing the functions table
class FunctionEntity extends Entity {
  final int? id;
  final String? uuid;
  final int? userId;
  final String name;
  final String? status;
  final int? activeDeploymentId;
  final Map<String, dynamic>? analysisResult;
  final bool skipSigning;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FunctionEntity({
    this.id,
    this.uuid,
    this.userId,
    required this.name,
    this.status,
    this.activeDeploymentId,
    this.analysisResult,
    this.skipSigning = false,
    this.createdAt,
    this.updatedAt,
  });

  @override
  String get tableName => 'functions';

  @override
  Map<String, dynamic> toMap() {
    return {
      if (uuid != null) 'uuid': uuid,
      if (userId != null) 'user_id': userId,
      'name': name,
      if (status != null) 'status': status,
      if (activeDeploymentId != null)
        'active_deployment_id': activeDeploymentId,
      if (analysisResult != null) 'analysis_result': analysisResult,
      'skip_signing': skipSigning,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  @override
  Map<String, dynamic> toDBMap() {
    return {
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (userId != null) 'user_id': userId,
      'name': name,
      if (status != null) 'status': status,
      if (activeDeploymentId != null)
        'active_deployment_id': activeDeploymentId,
      if (analysisResult != null) 'analysis_result': analysisResult,
      'skip_signing': skipSigning,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static FunctionEntity fromMap(Map<String, dynamic> map) {
    return FunctionEntity(
      id: map['id'] as int?,
      uuid: map['uuid']?.toString(),
      userId: map['user_id'] as int?,
      name: map['name'] as String,
      status: map['status'] as String?,
      activeDeploymentId: map['active_deployment_id'] as int?,
      analysisResult: map['analysis_result'] as Map<String, dynamic>?,
      skipSigning: map['skip_signing'] as bool? ?? false,
      createdAt: map['created_at'] as DateTime?,
      updatedAt: map['updated_at'] as DateTime?,
    );
  }

  FunctionEntity copyWith({
    int? id,
    String? uuid,
    int? userId,
    String? name,
    String? status,
    int? activeDeploymentId,
    Map<String, dynamic>? analysisResult,
    bool? skipSigning,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FunctionEntity(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      status: status ?? this.status,
      activeDeploymentId: activeDeploymentId ?? this.activeDeploymentId,
      analysisResult: analysisResult ?? this.analysisResult,
      skipSigning: skipSigning ?? this.skipSigning,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension FunctionEntityExtension on FunctionEntity {
  static String get idNameField => 'id';
  static String get uuidNameField => 'uuid';
  static String get userIdNameField => 'user_id';
  static String get nameField => 'name';
  static String get statusField => 'status';
  static String get activeDeploymentIdField => 'active_deployment_id';
  static String get analysisResultField => 'analysis_result';
  static String get skipSigningField => 'skip_signing';
  static String get createdAtField => 'created_at';
  static String get updatedAtField => 'updated_at';
}
