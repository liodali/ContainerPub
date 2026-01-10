import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/deploy_config.dart';
import '../utils/console.dart';
import '../utils/config_paths.dart';
import 'token_storage.dart';

class OpenBaoService {
  final String address;
  final OpenBaoConfig? config;
  Environment _currentEnv;

  OpenBaoService({
    required this.address,
    this.config,
    Environment environment = Environment.local,
  }) : _currentEnv = environment;

  /// Set the current environment
  set currentEnvironment(Environment env) => _currentEnv = env;

  /// Get token manager path for current environment
  String? get tokenManager => config?.getTokenManager(_currentEnv);

  /// Get policy for current environment
  String? get policy => config?.getPolicy(_currentEnv);

  /// Get role_id for current environment
  String? get roleId => config?.getEnvConfig(_currentEnv)?.roleId;

  /// Get role_name for current environment
  String? get roleName => config?.getEnvConfig(_currentEnv)?.roleName;

  /// Get secret path for current environment
  String? get secretPath => config?.getSecretPath(_currentEnv);

  /// Check if a string looks like a file path
  bool _isFilePath(String value) {
    return value.startsWith('/') ||
        value.startsWith('~/') ||
        value.startsWith('./') ||
        value.startsWith('../') ||
        value.contains('/') ||
        value.contains('\\');
  }

  /// Centralized method to retrieve and decode manager token
  Future<String?> _getManagerToken() async {
    final managerToken = tokenManager;
    if (managerToken == null) {
      Console.error('No token_manager configured for ${_currentEnv.name}');
      return null;
    }

    String base64Token;

    // Check if token_manager is a file path or direct base64 token
    if (_isFilePath(managerToken)) {
      // It's a file path - read the base64 token from file
      final expandedPath = ConfigPaths.expandPath(managerToken);
      final file = File(expandedPath);
      if (!file.existsSync()) {
        Console.error('Token manager file not found: $expandedPath');
        return null;
      }

      base64Token = file.readAsStringSync().trim();
      if (base64Token.isEmpty) {
        Console.error('Token manager file is empty: $expandedPath');
        return null;
      }
    } else {
      // It's a direct base64 token
      base64Token = managerToken.trim();
    }

    // Decode base64 token
    try {
      return utf8.decode(base64.decode(base64Token));
    } catch (e) {
      Console.error('Failed to decode base64 token: $e');
      return null;
    }
  }

  /// Generate a secret-id using AppRole authentication
  /// Uses the token_manager to authenticate and generate a secret-id
  Future<String?> _generateSecretId() async {
    final envRoleName = roleName;
    if (envRoleName == null) {
      Console.error('No role_name configured for ${_currentEnv.name}');
      return null;
    }

    final managerTokenValue = await _getManagerToken();
    if (managerTokenValue == null) {
      return null;
    }

    Console.info('Generating secret-id for role: $envRoleName');

    try {
      final url = Uri.parse(
        '$address/v1/auth/approle/role/$envRoleName/secret-id',
      );
      final response = await http.post(
        url,
        headers: {
          'X-Vault-Token': managerTokenValue,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secretIdData = data['data'] as Map<String, dynamic>?;
        if (secretIdData != null) {
          final secretId = secretIdData['secret_id'] as String?;
          if (secretId != null) {
            Console.success('Secret-id generated successfully');
            return secretId;
          }
        }
      }

      Console.error(
        'Failed to generate secret-id: ${response.statusCode} - ${response.body}',
      );
      return null;
    } catch (e) {
      Console.error('Failed to generate secret-id: $e');
      return null;
    }
  }

  /// Get or create a valid token
  /// Checks cache first, if expired or missing, creates a new one
  Future<String?> _getOrCreateToken() async {
    final storage = TokenStorage.instance;

    // Check if we have a valid cached token
    final cachedToken = await storage.getToken(_currentEnv.name);
    if (cachedToken != null) {
      Console.info('Using cached token for ${_currentEnv.name}');
      return cachedToken;
    }

    // No valid token, create a new one
    Console.info(
      'No valid cached token, creating new token for ${_currentEnv.name}',
    );

    final envRoleId = roleId;
    if (envRoleId == null) {
      Console.error('No role_id configured for ${_currentEnv.name}');
      return null;
    }

    // Generate secret-id
    final secretId = await _generateSecretId();
    if (secretId == null) {
      return null;
    }

    Console.info('Logging in with AppRole for ${_currentEnv.name}');
    final managerTokenValue = await _getManagerToken();
    if (managerTokenValue == null) {
      Console.error('Failed to get manager token');
      return null;
    }

    try {
      final url = Uri.parse('$address/v1/auth/approle/login');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Vault-Token': managerTokenValue,
        },
        body: jsonEncode({'role_id': envRoleId, 'secret_id': secretId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final auth = data['auth'] as Map<String, dynamic>?;
        if (auth != null) {
          final token = auth['client_token'] as String?;
          if (token != null) {
            // Store token in Hive with 1 hour TTL
            await storage.storeToken(_currentEnv.name, token);
            Console.success('AppRole login successful for ${_currentEnv.name}');
            return token;
          }
        }
      }

      Console.error(
        'Failed to login with AppRole: ${response.statusCode} - ${response.body}',
      );
      return null;
    } catch (e) {
      Console.error('Failed to login with AppRole: $e');
      return null;
    }
  }

  /// Ensure we have a valid token (for backward compatibility)
  Future<bool> createToken() async {
    final token = await _getOrCreateToken();
    return token != null;
  }

  /// Get headers with valid token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getOrCreateToken();
    if (token == null) {
      throw Exception('Failed to get valid token for ${_currentEnv.name}');
    }
    return {'X-Vault-Token': token, 'Content-Type': 'application/json'};
  }

  Future<Map<String, String>> fetchSecrets(String secretPath) async {
    final url = Uri.parse('$address/v1/$secretPath');

    Console.info('Fetching secrets from OpenBao: $secretPath');

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secretData = data['data'] as Map<String, dynamic>?;

        if (secretData == null) {
          throw Exception('No data found at path: $secretPath');
        }

        // Handle KV v2 format
        if (secretData.containsKey('data')) {
          final kvData = secretData['data'] as Map<String, dynamic>;
          return kvData.map((k, v) => MapEntry(k, v.toString()));
        }

        // Handle KV v1 format
        return secretData.map((k, v) => MapEntry(k, v.toString()));
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied. Check your OpenBao token.');
      } else if (response.statusCode == 404) {
        throw Exception('Secret not found at path: $secretPath');
      } else {
        throw Exception(
          'Failed to fetch secrets: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException catch (e) {
      throw Exception('Cannot connect to OpenBao at $address: $e');
    }
  }

  Future<void> writeEnvFile(String secretPath, String envFilePath) async {
    final secrets = await fetchSecrets(secretPath);

    final buffer = StringBuffer();
    buffer.writeln('# Generated by dart_cloud_deploy from OpenBao');
    buffer.writeln('# Path: $secretPath');
    buffer.writeln('# Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    for (final entry in secrets.entries) {
      final value = entry.value;
      // Quote values that contain spaces or special characters
      if (value.contains(' ') || value.contains('"') || value.contains("'")) {
        buffer.writeln('${entry.key}="${value.replaceAll('"', '\\"')}"');
      } else {
        buffer.writeln('${entry.key}=$value');
      }
    }

    final file = File(envFilePath);
    await file.writeAsString(buffer.toString());

    // Set restrictive permissions
    if (!Platform.isWindows) {
      await Process.run('chmod', ['600', envFilePath]);
    }

    Console.success(
      'Secrets written to $envFilePath (${secrets.length} variables)',
    );
  }

  Future<List<String>> listSecrets(String path) async {
    final url = Uri.parse('$address/v1/$path?list=true');

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final keys = data['data']?['keys'] as List<dynamic>?;
        return keys?.map((k) => k.toString()).toList() ?? [];
      }
      return [];
    } catch (e) {
      Console.warning('Failed to list secrets at $path: $e');
      return [];
    }
  }

  Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$address/v1/sys/health');
      final response = await http.get(url);
      return response.statusCode == 200 || response.statusCode == 429;
    } catch (e) {
      return false;
    }
  }
}
