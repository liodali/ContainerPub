import 'package:database/database.dart';

/// DTO for API key returned to frontend
class ApiKeyDto {
  final String uuid;
  final String functionUuid;
  final String publicKey;
  final String validity;
  final DateTime? expiresAt;
  final bool isActive;
  final String? name;
  final DateTime? createdAt;
  final DateTime? revokedAt;

  ApiKeyDto({
    required this.uuid,
    required this.functionUuid,
    required this.publicKey,
    required this.validity,
    this.expiresAt,
    required this.isActive,
    this.name,
    this.createdAt,
    this.revokedAt,
  });

  factory ApiKeyDto.fromEntity(ApiKeyEntity entity) {
    return ApiKeyDto(
      uuid: entity.uuid!,
      functionUuid: entity.functionUuid,
      publicKey: entity.publicKey,
      validity: entity.validity,
      expiresAt: entity.expiresAt,
      isActive: entity.isActive,
      name: entity.name,
      createdAt: entity.createdAt,
      revokedAt: entity.revokedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'function_uuid': functionUuid,
      'public_key': publicKey,
      'validity': validity,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'is_active': isActive,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (revokedAt != null) 'revoked_at': revokedAt!.toIso8601String(),
    };
  }
}
