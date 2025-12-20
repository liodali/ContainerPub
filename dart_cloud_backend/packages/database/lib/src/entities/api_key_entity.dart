import '../entity.dart';

/// Validity duration options for API keys
enum ApiKeyValidity {
  oneHour('1h', Duration(hours: 1)),
  oneDay('1d', Duration(days: 1)),
  oneWeek('1w', Duration(days: 7)),
  oneMonth('1m', Duration(days: 30)),
  forever('forever', null)
  ;

  final String value;
  final Duration? duration;

  const ApiKeyValidity(this.value, this.duration);

  static ApiKeyValidity fromString(String value) {
    return ApiKeyValidity.values.firstWhere(
      (v) => v.value == value,
      orElse: () => ApiKeyValidity.oneDay,
    );
  }

  /// Calculate expiration date from creation time
  DateTime? getExpirationDate(DateTime createdAt) {
    if (duration == null) return null; // forever
    return createdAt.add(duration!);
  }
}

/// API Key entity for function signing
///
/// Each function can have one active API key pair.
/// - Public key: stored in database, used to verify signatures
/// - Private key: returned only once at creation, stored by CLI in .dart_tool
///
/// The private key is used to sign request data when invoking functions.
/// The public key is used by the backend to verify the signature.
class ApiKeyEntity extends Entity {
  final int? id;
  final String? uuid;
  final String functionUuid;
  final String publicKey;
  final String?
  privateKeyHash; // Hash of private key for revocation verification
  final String validity;
  final DateTime? expiresAt;
  final bool isActive;
  final String? name; // Optional friendly name for the key
  final DateTime? createdAt;
  final DateTime? revokedAt;

  ApiKeyEntity({
    this.id,
    this.uuid,
    required this.functionUuid,
    required this.publicKey,
    this.privateKeyHash,
    required this.validity,
    this.expiresAt,
    this.isActive = true,
    this.name,
    this.createdAt,
    this.revokedAt,
  });

  @override
  String get tableName => 'api_keys';

  @override
  Map<String, dynamic> toMap() {
    return {
      if (uuid != null) 'uuid': uuid,
      'function_uuid': functionUuid,
      'public_key': publicKey,
      if (privateKeyHash != null) 'private_key_hash': privateKeyHash,
      'validity': validity,
      if (expiresAt != null) 'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (revokedAt != null) 'revoked_at': revokedAt?.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> toDBMap() {
    return {
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      'function_uuid': functionUuid,
      'public_key': publicKey,
      if (privateKeyHash != null) 'private_key_hash': privateKeyHash,
      'validity': validity,
      if (expiresAt != null) 'expires_at': expiresAt,
      'is_active': isActive,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (revokedAt != null) 'revoked_at': revokedAt,
    };
  }

  static ApiKeyEntity fromMap(Map<String, dynamic> map) {
    return ApiKeyEntity(
      id: map['id'] as int?,
      uuid: map['uuid']?.toString(),
      functionUuid: map['function_uuid'] as String,
      publicKey: map['public_key'] as String,
      privateKeyHash: map['private_key_hash'] as String?,
      validity: map['validity'] as String,
      expiresAt: map['expires_at'] as DateTime?,
      isActive: map['is_active'] as bool? ?? true,
      name: map['name'] as String?,
      createdAt: map['created_at'] as DateTime?,
      revokedAt: map['revoked_at'] as DateTime?,
    );
  }

  ApiKeyEntity copyWith({
    int? id,
    String? uuid,
    String? functionUuid,
    String? publicKey,
    String? privateKeyHash,
    String? validity,
    DateTime? expiresAt,
    bool? isActive,
    String? name,
    DateTime? createdAt,
    DateTime? revokedAt,
  }) {
    return ApiKeyEntity(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      functionUuid: functionUuid ?? this.functionUuid,
      publicKey: publicKey ?? this.publicKey,
      privateKeyHash: privateKeyHash ?? this.privateKeyHash,
      validity: validity ?? this.validity,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      revokedAt: revokedAt ?? this.revokedAt,
    );
  }

  /// Check if the API key is expired
  bool get isExpired {
    if (expiresAt == null) return false; // forever keys never expire
    return DateTime.now().toUtc().isAfter(expiresAt!);
  }

  /// Check if the API key is valid (active and not expired)
  bool get isValid => isActive && !isExpired;

  /// Get validity enum from string
  ApiKeyValidity get validityEnum => ApiKeyValidity.fromString(validity);
}

extension ApiKeyEntityExtension on ApiKeyEntity {
  static String get idNameField => 'id';
  static String get uuidNameField => 'uuid';
  static String get functionUuidNameField => 'function_uuid';
  static String get publicKeyNameField => 'public_key';
  static String get privateKeyHashNameField => 'private_key_hash';
  static String get validityNameField => 'validity';
  static String get expiresAtNameField => 'expires_at';
  static String get isActiveNameField => 'is_active';
  static String get nameField => 'name';
  static String get createdAtNameField => 'created_at';
  static String get revokedAtNameField => 'revoked_at';
}
