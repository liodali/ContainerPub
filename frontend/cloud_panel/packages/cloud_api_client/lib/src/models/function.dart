import 'package:equatable/equatable.dart';

class CloudFunction extends Equatable {
  final String uuid;
  final String name;
  final String status;
  final String? endpoint;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CloudFunction({
    required this.uuid,
    required this.name,
    required this.status,
    this.endpoint,
    required this.createdAt,
    this.updatedAt,
  });

  factory CloudFunction.fromJson(Map<String, dynamic> json) {
    return CloudFunction(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      endpoint: json['endpoint'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [uuid, name, status, endpoint, createdAt, updatedAt];
}
