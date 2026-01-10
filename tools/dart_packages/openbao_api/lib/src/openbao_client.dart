import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'models/openbao_exception.dart';
import 'services/token_storage.dart';

/// Client for interacting with OpenBao/Vault.
class OpenBaoClient {
  final String address;
  final String? roleId;
  final String? roleName;
  final String? managerToken;
  final TokenStorage tokenStorage;
  final http.Client _httpClient;

  /// Creates a new OpenBao client.
  ///
  /// [address] is the base URL of the OpenBao server.
  /// [tokenStorage] is the storage service for caching tokens.
  /// [roleId] is the AppRole Role ID (required for login).
  /// [roleName] is the AppRole Role Name (required for secret-id generation).
  /// [managerToken] is the token used to generate secret-ids (optional).
  OpenBaoClient({
    required this.address,
    required this.tokenStorage,
    this.roleId,
    this.roleName,
    this.managerToken,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Check if a string looks like a file path
  bool _isFilePath(String value) {
    return value.startsWith('/') ||
        value.startsWith('~/') ||
        value.startsWith('./') ||
        value.startsWith('../') ||
        value.contains('/') ||
        value.contains('\\');
  }

  /// Retrieve and decode manager token.
  /// Handles both direct token strings and file paths.
  Future<String?> _resolveManagerToken() async {
    if (managerToken == null) {
      return null;
    }

    String base64Token;

    // Check if token_manager is a file path or direct base64 token
    if (_isFilePath(managerToken!)) {
      final file = File(managerToken!);
      if (!file.existsSync()) {
        throw OpenBaoException('Token manager file not found: $managerToken');
      }

      base64Token = file.readAsStringSync().trim();
      if (base64Token.isEmpty) {
        throw OpenBaoException('Token manager file is empty: $managerToken');
      }
    } else {
      // It's a direct base64 token
      base64Token = managerToken!.trim();
    }

    // Decode base64 token
    try {
      return utf8.decode(base64.decode(base64Token));
    } catch (e) {
      throw OpenBaoException('Failed to decode base64 token: $e');
    }
  }

  /// Generate a secret-id using AppRole authentication.
  /// Uses the [managerToken] to authenticate and generate a secret-id.
  Future<String> generateSecretId() async {
    if (roleName == null) {
      throw OpenBaoException('roleName is required to generate secret-id');
    }

    final resolvedToken = await _resolveManagerToken();
    if (resolvedToken == null) {
      throw OpenBaoException('managerToken is required to generate secret-id');
    }

    try {
      final url = Uri.parse(
        '$address/v1/auth/approle/role/$roleName/secret-id',
      );
      final response = await _httpClient.post(
        url,
        headers: {
          'X-Vault-Token': resolvedToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secretIdData = data['data'] as Map<String, dynamic>?;
        if (secretIdData != null) {
          final secretId = secretIdData['secret_id'] as String?;
          if (secretId != null) {
            return secretId;
          }
        }
      }

      throw OpenBaoException(
        'Failed to generate secret-id',
        statusCode: response.statusCode,
        body: response.body,
      );
    } catch (e) {
      if (e is OpenBaoException) rethrow;
      throw OpenBaoException('Failed to generate secret-id: $e');
    }
  }

  /// Get or create a valid token for the given [context] (e.g. environment name).
  /// Checks cache first, if expired or missing, creates a new one using AppRole login.
  Future<String> getOrCreateToken(String context) async {
    // Check if we have a valid cached token
    final cachedToken = await tokenStorage.getToken(context);
    if (cachedToken != null) {
      return cachedToken;
    }

    if (roleId == null) {
      throw OpenBaoException('roleId is required for AppRole login');
    }

    // Generate secret-id
    final secretId = await generateSecretId();

    try {
      final url = Uri.parse('$address/v1/auth/approle/login');
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role_id': roleId, 'secret_id': secretId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final auth = data['auth'] as Map<String, dynamic>?;
        if (auth != null) {
          final token = auth['client_token'] as String?;
          if (token != null) {
            // Store token in Hive with 1 hour TTL
            await tokenStorage.storeToken(context, token);
            return token;
          }
        }
      }

      throw OpenBaoException(
        'Failed to login with AppRole',
        statusCode: response.statusCode,
        body: response.body,
      );
    } catch (e) {
      if (e is OpenBaoException) rethrow;
      throw OpenBaoException('Failed to login with AppRole: $e');
    }
  }

  /// Get headers with valid token for the given [context].
  Future<Map<String, String>> _getHeaders(String context) async {
    final token = await getOrCreateToken(context);
    return {'X-Vault-Token': token, 'Content-Type': 'application/json'};
  }

  /// Fetch secrets from a specific [secretPath].
  /// [context] is used to look up the cached token (e.g. environment name).
  Future<Map<String, String>> fetchSecrets(
    String secretPath,
    String context,
  ) async {
    final url = Uri.parse('$address/v1/$secretPath');

    try {
      final headers = await _getHeaders(context);
      final response = await _httpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secretData = data['data'] as Map<String, dynamic>?;

        if (secretData == null) {
          throw OpenBaoException('No data found at path: $secretPath');
        }

        // Handle KV v2 format
        if (secretData.containsKey('data')) {
          final kvData = secretData['data'] as Map<String, dynamic>;
          return kvData.map((k, v) => MapEntry(k, v.toString()));
        }

        // Handle KV v1 format
        return secretData.map((k, v) => MapEntry(k, v.toString()));
      } else if (response.statusCode == 403) {
        throw OpenBaoException(
          'Permission denied. Check your OpenBao token.',
          statusCode: 403,
        );
      } else if (response.statusCode == 404) {
        throw OpenBaoException(
          'Secret not found at path: $secretPath',
          statusCode: 404,
        );
      } else {
        throw OpenBaoException(
          'Failed to fetch secrets',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on SocketException catch (e) {
      throw OpenBaoException('Cannot connect to OpenBao at $address: $e');
    }
  }

  /// List secret keys at [path].
  Future<List<String>> listSecrets(String path, String context) async {
    final url = Uri.parse('$address/v1/$path?list=true');

    try {
      final headers = await _getHeaders(context);
      final response = await _httpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final keys = data['data']?['keys'] as List<dynamic>?;
        return keys?.map((k) => k.toString()).toList() ?? [];
      }
      return [];
    } catch (e) {
      // Don't throw on list failure, just return empty
      return [];
    }
  }

  /// Check health of the OpenBao server.
  Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$address/v1/sys/health');
      final response = await _httpClient.get(url);
      return response.statusCode == 200 || response.statusCode == 429;
    } catch (e) {
      return false;
    }
  }
}
