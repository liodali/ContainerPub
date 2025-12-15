import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:database/database.dart';

/// Service for generating and managing API keys for function signing
/// Uses HMAC-SHA256 with a shared secret key for signing and verification
class ApiKeyService {
  static final ApiKeyService _instance = ApiKeyService._();
  static ApiKeyService get instance => _instance;

  ApiKeyService._();

  /// Generate a new API key for a function
  /// Returns the secret key - only returned once, developer must store it securely
  Future<ApiKeyResult> generateApiKey({
    required String functionUuid,
    required ApiKeyValidity validity,
    String? name,
  }) async {
    // Generate cryptographically secure secret key
    final secretKey = _generateSecureKey(64); // 512-bit secret key
    final secretKeyHash = _hashKey(secretKey);

    // Calculate expiration date
    final now = DateTime.now();
    final expiresAt = validity.getExpirationDate(now);

    // Deactivate any existing active keys for this function
    await _deactivateExistingKeys(functionUuid);

    // Store the API key in database (we store the secret key for verification)
    final apiKeyEntity = await DatabaseManagers.apiKeys.insert(
      ApiKeyEntity(
        functionUuid: functionUuid,
        publicKey:
            secretKey, // Store secret key (named publicKey in DB for compatibility)
        privateKeyHash: secretKeyHash,
        validity: validity.value,
        expiresAt: expiresAt,
        isActive: true,
        name: name,
        createdAt: now,
      ).toDBMap(),
    );

    if (apiKeyEntity == null) {
      throw Exception('Failed to create API key');
    }

    return ApiKeyResult(
      uuid: apiKeyEntity.uuid!,
      secretKey: secretKey, // Only returned once! Developer must store this.
      validity: validity,
      expiresAt: expiresAt,
      name: name,
      createdAt: now,
    );
  }

  /// Deactivate existing active keys for a function
  Future<void> _deactivateExistingKeys(String functionUuid) async {
    final existingKeys = await DatabaseManagers.apiKeys.findAll(
      where: {
        'function_uuid': functionUuid,
        'is_active': true,
      },
    );

    for (final key in existingKeys) {
      await DatabaseManagers.apiKeys.update(
        {
          'is_active': false,
          'revoked_at': DateTime.now(),
        },
        where: {'uuid': key.uuid},
      );
    }
  }

  /// Get the active API key for a function
  Future<ApiKeyEntity?> getActiveApiKey(String functionUuid) async {
    final keys = await DatabaseManagers.apiKeys.findAll(
      where: {
        'function_uuid': functionUuid,
        'is_active': true,
      },
    );

    if (keys.isEmpty) return null;

    final key = keys.first;

    // Check if expired
    if (key.isExpired) {
      // Deactivate expired key
      await DatabaseManagers.apiKeys.update(
        {'is_active': false},
        where: {'uuid': key.uuid},
      );
      return null;
    }

    return key;
  }

  /// Revoke an API key
  Future<bool> revokeApiKey(String apiKeyUuid) async {
    final results = await DatabaseManagers.apiKeys.update(
      {
        'is_active': false,
        'revoked_at': DateTime.now(),
      },
      where: {'uuid': apiKeyUuid},
    );

    return results.isNotEmpty;
  }

  /// Verify a signature against the stored secret key
  /// Returns true if signature is valid
  Future<bool> verifySignature({
    required String functionUuid,
    required String signature,
    required String payload,
    required int timestamp,
  }) async {
    final apiKey = await getActiveApiKey(functionUuid);
    if (apiKey == null) {
      return false; // No active API key
    }

    // Check timestamp to prevent replay attacks (5 minute window)
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if ((now - timestamp).abs() > 300) {
      return false; // Timestamp too old or too far in future
    }

    // Verify the signature using the same secret key
    // apiKey.publicKey contains the secret key (DB field name kept for compatibility)
    final expectedSignature = createSignatureWithSecretKey(
      secretKey: apiKey.publicKey,
      payload: payload,
      timestamp: timestamp,
    );

    return _secureCompare(signature, expectedSignature);
  }

  /// Create a signature for a payload using the secret key
  /// Used by both CLI (signing) and backend (verification)
  static String createSignatureWithSecretKey({
    required String secretKey,
    required String payload,
    required int timestamp,
  }) {
    final dataToSign = '$timestamp:$payload';
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmac.convert(utf8.encode(dataToSign));
    return base64Encode(digest.bytes);
  }

  /// Generate a cryptographically secure random key
  String _generateSecureKey(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Encode(bytes);
  }

  /// Hash the secret key for storage (for revocation verification)
  String _hashKey(String key) {
    final digest = sha256.convert(utf8.encode(key));
    return digest.toString();
  }

  /// Constant-time string comparison to prevent timing attacks
  bool _secureCompare(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// List all API keys for a function (without private keys)
  Future<List<ApiKeyEntity>> listApiKeys(String functionUuid) async {
    return await DatabaseManagers.apiKeys.findAll(
      where: {'function_uuid': functionUuid},
      orderBy: 'created_at DESC',
    );
  }

  /// Check if a function has an active API key
  Future<bool> hasActiveApiKey(String functionUuid) async {
    final key = await getActiveApiKey(functionUuid);
    return key != null;
  }
}

/// Represents a generated API key result
/// Secret key is only available at creation time - developer must store it
class ApiKeyResult {
  final String uuid;
  final String secretKey;
  final ApiKeyValidity validity;
  final DateTime? expiresAt;
  final String? name;
  final DateTime createdAt;

  ApiKeyResult({
    required this.uuid,
    required this.secretKey,
    required this.validity,
    this.expiresAt,
    this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'secret_key': secretKey, // Only returned once! Developer must store this.
      'validity': validity.value,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      if (name != null) 'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// DTO for API key info (without secret key - never expose the secret)
class ApiKeyInfo {
  final String uuid;
  final String validity;
  final DateTime? expiresAt;
  final bool isActive;
  final String? name;
  final DateTime? createdAt;

  ApiKeyInfo({
    required this.uuid,
    required this.validity,
    this.expiresAt,
    required this.isActive,
    this.name,
    this.createdAt,
  });

  factory ApiKeyInfo.fromEntity(ApiKeyEntity entity) {
    return ApiKeyInfo(
      uuid: entity.uuid!,
      validity: entity.validity,
      expiresAt: entity.expiresAt,
      isActive: entity.isActive,
      name: entity.name,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'validity': validity,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'is_active': isActive,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
