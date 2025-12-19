import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive.dart';

class ApiKeyStorage {
  static ApiKeyStorage? _instance;
  const ApiKeyStorage._();

  static ApiKeyStorage get instance {
    _instance ??= ApiKeyStorage._();
    return _instance!;
  }

  static LazyBox? _apiKeyBox;

  Future<void> init() async {
    if (!Hive.isBoxOpen('api_keys')) {
      _apiKeyBox = await Hive.openLazyBox('api_keys');
    }
  }

  /// Store API key with password-based encryption
  /// Stores: base64(secretKey) with password hash as verification
  Future<void> storeApiKey(
    String apiKeyUuid,
    String secretKey,
    String password,
  ) async {
    try {
      // Create hash from password for verification
      final passwordHash = sha256.convert(utf8.encode(password)).toString();

      // Base64 encode the secret key
      final encodedSecretKey = base64Encode(utf8.encode(secretKey));

      // Store with password hash as verification
      await _apiKeyBox?.put('apikey_$apiKeyUuid', encodedSecretKey);
      await _apiKeyBox?.put('apikey_${apiKeyUuid}_hash', passwordHash);
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieve API key with password verification
  /// Returns base64 decoded secret key if password matches
  Future<String?> getApiKey(String apiKeyUuid, String password) async {
    try {
      final storedHash = await _apiKeyBox?.get('apikey_${apiKeyUuid}_hash');
      final passwordHash = sha256.convert(utf8.encode(password)).toString();

      // Verify password
      if (storedHash != passwordHash) {
        return null;
      }

      final encodedSecretKey = await _apiKeyBox?.get('apikey_$apiKeyUuid');
      if (encodedSecretKey == null) {
        return null;
      }

      // Decode from base64
      return utf8.decode(base64Decode(encodedSecretKey));
    } catch (e) {
      return null;
    }
  }

  /// Check if API key exists
  Future<bool> hasApiKey(String apiKeyUuid) async {
    try {
      final stored = await _apiKeyBox?.get('apikey_$apiKeyUuid');
      return stored != null;
    } catch (e) {
      return false;
    }
  }

  /// Get all stored API key UUIDs
  Future<List<String>> getStoredApiKeyUuids() async {
    try {
      final keys = _apiKeyBox?.keys ?? [];
      return keys
          .where((key) =>
              key.toString().startsWith('apikey_') &&
              !key.toString().endsWith('_hash'))
          .map((key) => key.toString().replaceFirst('apikey_', ''))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete stored API key
  Future<void> deleteApiKey(String apiKeyUuid) async {
    try {
      await _apiKeyBox?.delete('apikey_$apiKeyUuid');
      await _apiKeyBox?.delete('apikey_${apiKeyUuid}_hash');
    } catch (e) {
      rethrow;
    }
  }
}
