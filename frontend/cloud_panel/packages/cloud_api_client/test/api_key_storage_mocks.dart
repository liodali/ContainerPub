import 'package:cloud_api_client/src/api_key_storage.dart';

class FakeApiKeyStorage implements ApiKeyStorage {
  final Map<String, String> _apiKeys = {};
  final Map<String, String> _apiKeyHashes = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> storeApiKey(
    String apiKeyUuid,
    String secretKey,
    String password,
  ) async {
    _apiKeys[apiKeyUuid] = secretKey;
    _apiKeyHashes[apiKeyUuid] = password;
  }

  @override
  Future<String?> getApiKey(String apiKeyUuid, String password) async {
    if (_apiKeyHashes[apiKeyUuid] != password) {
      return null;
    }
    return _apiKeys[apiKeyUuid];
  }

  @override
  Future<bool> hasApiKey(String apiKeyUuid) async {
    return _apiKeys.containsKey(apiKeyUuid);
  }

  @override
  Future<List<String>> getStoredApiKeyUuids() async {
    return _apiKeys.keys.toList();
  }

  @override
  Future<void> deleteApiKey(String apiKeyUuid) async {
    _apiKeys.remove(apiKeyUuid);
    _apiKeyHashes.remove(apiKeyUuid);
  }
}
