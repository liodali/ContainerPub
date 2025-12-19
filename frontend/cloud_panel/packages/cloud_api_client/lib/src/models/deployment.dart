import 'package:cloud_api_client/src/common/commons.dart';
import 'package:equatable/equatable.dart';

class FunctionDeployment extends Equatable {
  final String uuid;
  final String status;
  final bool isLatest;
  final int version;
  final DateTime createdAt;

  const FunctionDeployment({
    required this.uuid,
    required this.isLatest,
    required this.status,
    required this.version,
    required this.createdAt,
  });

  factory FunctionDeployment.fromJson(Map<String, dynamic> json) {
    return FunctionDeployment(
      uuid: json['uuid'] as String,
      isLatest: json['is_active'] as bool,
      status: json['status'] as String,
      version: json['version'] as int,
      createdAt: dateFormatter.tryParse(json['deployed_at']) ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [uuid, isLatest, status, version, createdAt];
}
