import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:dart_cloud_cli/services/hive_service.dart';

typedef ApiKeyStorageData = ({String uuid, String privateKey});

/// Service for managing API key storage using Hive CE
///
/// Stores API keys with:
/// - Key: functionUuid
/// - Value: base64-encoded private key
mixin ApiKeyStorage {
  static const String _boxName = 'api_keys';
  static late Box<String> _box;
  static bool _initialized = false;

  /// Initialize the Hive box for API key storage
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _box = await HiveService.initBox<String>(_boxName, subPath: 'api_keys');
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize API key storage: $e');
    }
  }

  /// Store an API key for a function
  ///
  /// [functionUuid]: The UUID of the function
  /// [privateKey]: The private key to store (will be base64 encoded)
  static Future<void> storeApiKey(
    String functionUuid,
    String privateKey,
    String keyUUID,
  ) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Base64 encode the private key for storage

      final encoded = base64.encode(utf8.encode(privateKey));
      final data = {'keyUUID': keyUUID, 'privateKey': encoded};
      await _box.put(functionUuid, jsonEncode(data));
    } catch (e) {
      throw Exception('Failed to store API key: $e');
    }
  }

  /// Retrieve an API key for a function
  ///
  /// [functionUuid]: The UUID of the function
  /// Returns the decoded private key, or null if not found
  static Future<ApiKeyStorageData?> getApiKey(String functionUuid) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final encoded = _box.get(functionUuid);
      if (encoded == null) {
        return null;
      }
      if (!encoded.contains('keyUUID')) {
        return (uuid: '', privateKey: utf8.decode(base64.decode(encoded)));
      }
      final data = json.decode(encoded);
      final privateKey = data['privateKey'];

      // Decode the base64-encoded private key
      return (
        uuid: data['keyUUID'] as String,
        privateKey: utf8.decode(base64.decode(privateKey)),
      );
    } catch (e) {
      throw Exception('Failed to retrieve API key');
    }
  }

  /// Check if an API key exists for a function
  ///
  /// [functionUuid]: The UUID of the function
  static Future<bool> hasApiKey(String functionUuid) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      return _box.containsKey(functionUuid);
    } catch (e) {
      throw Exception('Failed to check API key existence: $e');
    }
  }

  /// Delete an API key for a function
  ///
  /// [functionUuid]: The UUID of the function
  static Future<void> deleteApiKey(String functionUuid) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await _box.delete(functionUuid);
    } catch (e) {
      throw Exception('Failed to delete API key: $e');
    }
  }

  /// List all stored API key function UUIDs
  static Future<List<String>> listApiKeyFunctions() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      return _box.keys.cast<String>().toList();
    } catch (e) {
      throw Exception('Failed to list API keys: $e');
    }
  }

  /// Clear all stored API keys
  static Future<void> clearAll() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await _box.clear();
    } catch (e) {
      throw Exception('Failed to clear API keys: $e');
    }
  }

  /// Close the Hive box (cleanup)
  static Future<void> close() async {
    if (_initialized && _box.isOpen) {
      await _box.close();
      _initialized = false;
    }
  }
}
