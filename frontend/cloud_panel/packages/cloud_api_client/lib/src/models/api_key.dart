import 'package:equatable/equatable.dart';

class ApiKey extends Equatable {
  final String uuid;
  final String validity;
  final DateTime? expiresAt;
  final bool isActive;
  final String? name;
  final DateTime createdAt;

  const ApiKey({
    required this.uuid,
    required this.validity,
    this.expiresAt,
    required this.isActive,
    this.name,
    required this.createdAt,
  });

  factory ApiKey.fromJson(Map<String, dynamic> json) {
    return ApiKey(
      uuid: json['uuid'] as String,
      validity: json['validity'] as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool,
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] != null
          ? json['created_at'] as String
          : DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props =>
      [uuid, validity, expiresAt, isActive, name, createdAt];
}

class GeneratedApiKey extends ApiKey {
  final String secretKey;

  const GeneratedApiKey({
    required super.uuid,
    required super.validity,
    super.expiresAt,
    required super.isActive,
    super.name,
    required super.createdAt,
    required this.secretKey,
  });

  factory GeneratedApiKey.fromJson(Map<String, dynamic> json) {
    // Backend returns 'api_key' object inside response, or mixed?
    // Based on ApiKeyHandler.generateApiKey:
    // {
    //   'message': ...,
    //   'warning': ...,
    //   'api_key': { 'uuid':..., 'secret_key':..., ... }
    // }
    // This factory expects the inner 'api_key' map.
    return GeneratedApiKey(
      uuid: json['uuid'] as String,
      validity: json['validity'] as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: true, // Generated keys are active by default
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      secretKey: json['secret_key'] as String,
    );
  }
}
