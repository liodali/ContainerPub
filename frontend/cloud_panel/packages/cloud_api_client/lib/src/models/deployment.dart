import 'package:equatable/equatable.dart';

class FunctionDeployment extends Equatable {
  final String uuid;
  final String functionUuid;
  final String status;
  final int version;
  final String? buildLogs;
  final DateTime createdAt;

  const FunctionDeployment({
    required this.uuid,
    required this.functionUuid,
    required this.status,
    required this.version,
    this.buildLogs,
    required this.createdAt,
  });

  factory FunctionDeployment.fromJson(Map<String, dynamic> json) {
    return FunctionDeployment(
      uuid: json['uuid'] as String,
      functionUuid: json['function_uuid'] as String,
      status: json['status'] as String,
      version: json['version'] as int? ?? 0,
      buildLogs: json['build_logs'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [uuid, functionUuid, status, version, buildLogs, createdAt];
}
