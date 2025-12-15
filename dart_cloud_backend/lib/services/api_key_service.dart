import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:database/database.dart';

/// Service for generating and managing API keys for function signing
class ApiKeyService {
  static final ApiKeyService _instance = ApiKeyService._();
  static ApiKeyService get instance => _instance;

  ApiKeyService._();

  /// Generate a new API key pair for a function
  /// Returns both public and private keys - private key is only returned once
  Future<ApiKeyPair> generateApiKey({
    required String functionUuid,
    required ApiKeyValidity validity,
    String? name,
  }) async {
    // Generate cryptographically secure random keys
    final privateKey = _generateSecureKey(64); // 512-bit private key
    final publicKey = _derivePublicKey(privateKey);
    final privateKeyHash = _hashKey(privateKey);

    // Calculate expiration date
    final now = DateTime.now();
    final expiresAt = validity.getExpirationDate(now);

    // Deactivate any existing active keys for this function
    await _deactivateExistingKeys(functionUuid);

    // Store the API key in database
    final apiKeyEntity = await DatabaseManagers.apiKeys.insert(
      ApiKeyEntity(
        functionUuid: functionUuid,
        publicKey: publicKey,
        privateKeyHash: privateKeyHash,
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

    return ApiKeyPair(
      uuid: apiKeyEntity.uuid!,
      publicKey: publicKey,
      privateKey: privateKey, // Only returned once!
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

  /// Get the active API key for a function (public key only)
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

  /// Verify a signature against the stored public key
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

    // Verify the signature
    final expectedSignature = _createSignature(
      apiKey.publicKey,
      payload,
      timestamp,
    );

    return _secureCompare(signature, expectedSignature);
  }

  /// Create a signature for a payload (used by CLI)
  /// This is the algorithm that CLI will use with the private key
  static String createSignatureWithPrivateKey({
    required String privateKey,
    required String payload,
    required int timestamp,
  }) {
    final dataToSign = '$timestamp:$payload';
    final hmac = Hmac(sha256, utf8.encode(privateKey));
    final digest = hmac.convert(utf8.encode(dataToSign));
    return base64Encode(digest.bytes);
  }

  /// Create signature using public key (for verification)
  String _createSignature(String publicKey, String payload, int timestamp) {
    // The public key is derived from private key, so we use it to verify
    // by recreating the expected signature
    final dataToSign = '$timestamp:$payload';
    final hmac = Hmac(sha256, utf8.encode(publicKey));
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

  /// Derive public key from private key using HMAC
  String _derivePublicKey(String privateKey) {
    final hmac = Hmac(sha256, utf8.encode('containerpub-api-key-derivation'));
    final digest = hmac.convert(utf8.encode(privateKey));
    return base64Encode(digest.bytes);
  }

  /// Hash the private key for storage (for revocation verification)
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

/// Represents a generated API key pair
/// Private key is only available at creation time
class ApiKeyPair {
  final String uuid;
  final String publicKey;
  final String privateKey;
  final ApiKeyValidity validity;
  final DateTime? expiresAt;
  final String? name;
  final DateTime createdAt;

  ApiKeyPair({
    required this.uuid,
    required this.publicKey,
    required this.privateKey,
    required this.validity,
    this.expiresAt,
    this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'public_key': publicKey.substring(0, 20),
      'private_key': privateKey, // Only included at creation!
      'validity': validity.value,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      if (name != null) 'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// DTO for API key info (without private key)
class ApiKeyInfo {
  final String uuid;
  final String publicKey;
  final String validity;
  final DateTime? expiresAt;
  final bool isActive;
  final String? name;
  final DateTime? createdAt;

  ApiKeyInfo({
    required this.uuid,
    required this.publicKey,
    required this.validity,
    this.expiresAt,
    required this.isActive,
    this.name,
    this.createdAt,
  });

  factory ApiKeyInfo.fromEntity(ApiKeyEntity entity) {
    return ApiKeyInfo(
      uuid: entity.uuid!,
      publicKey: entity.publicKey,
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
      'public_key': publicKey,
      'validity': validity,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'is_active': isActive,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
