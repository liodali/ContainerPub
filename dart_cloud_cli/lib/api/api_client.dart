import 'dart:convert';
import 'dart:io';
import 'package:dart_cloud_cli/api/token_http.dart';
import 'package:http/http.dart' as http;
import 'package:dart_cloud_cli/config/config.dart';

class ApiClient {
  static final TokenHttpClient _client = TokenHttpClient(
    getToken: () async {
      return Config.token;
    },
    refreshToken: () async {
      final token = await refreshToken(Config.refreshToken!);
      if (token != null) {
        Config().save(
          token: token,
          refreshToken: Config.refreshToken!,
        );
      }
      return token;
    },
  );
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final body = {
      'email': email,
      'password': base64.encode(password.codeUnits),
    };
    final response = await http.post(
      Uri.parse('${Config.serverUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<String?> refreshToken(
    String refreshToken,
  ) async {
    final body = {
      'refreshToken': refreshToken,
    };
    final response = await http.post(
      Uri.parse('${Config.serverUrl}/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)["accessToken"];
    } else {
      throw Exception('refreshToken failed');
    }
  }

  /// Initialize a new function on the backend
  ///
  /// Creates a function record with status 'init' and returns the UUID
  /// [skipSigning]: If true, disables API key signing for this function
  static Future<Map<String, dynamic>> initFunction(
    String functionName, {
    bool skipSigning = false,
  }) async {
    final response = await _client.post(
      Uri.parse('${Config.serverUrl}/api/functions/init'),
      headers: {
        'Authorization': 'Bearer ${Config.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': functionName,
        'skip_signing': skipSigning,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Initialization failed: ${response.body}');
    }
  }

  /// Deploy a function using its UUID
  ///
  /// [functionUuid]: The UUID of the function (from init)
  /// [archive]: The archive file containing the function code
  static Future<Map<String, dynamic>> deployFunction(
    File archive,
    String functionUuid,
  ) async {
    final response = await _client.sendMultipartRequest(
      'POST',
      Uri.parse('${Config.serverUrl}/api/functions/deploy'),
      fields: {'function_id': functionUuid},
      files: [await http.MultipartFile.fromPath('archive', archive.path)],
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Deployment failed: ${response.body}');
    }
  }

  static Future<List<dynamic>> listFunctions() async {
    final response = await _client.get(
      Uri.parse('${Config.serverUrl}/api/functions'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to list functions: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getFunctionLogs(String functionId) async {
    final response = await _client.get(
      Uri.parse('${Config.serverUrl}/api/functions/$functionId/logs'),
      headers: {'Authorization': 'Bearer ${Config.token}'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get logs: ${response.body}');
    }
  }

  static Future<void> deleteFunction(String functionId) async {
    final response = await _client.delete(
      Uri.parse('${Config.serverUrl}/api/functions/$functionId'),
      headers: {'Authorization': 'Bearer ${Config.token}'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete function: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> invokeFunction(
    String functionId,
    Map<String, dynamic>? data, {
    String? signature,
    String? keyUUID,
    int? timestamp,
  }) async {
    final body = data != null
        ? {
            'body': data,
          }
        : null;

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // Add signature headers if provided
    if (signature != null && timestamp != null && keyUUID != null) {
      headers['X-Signature'] = signature;
      headers['X-Api-Key'] = keyUUID;
      headers['X-Timestamp'] = timestamp.toString();
    }

    final response = await http.post(
      Uri.parse('${Config.serverUrl}/api/functions/$functionId/invoke'),
      headers: headers,
      body: jsonEncode(body ?? {}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to invoke function: ${response.body}');
    }
  }

  /// Generate a new API key for a function
  static Future<Map<String, dynamic>> generateApiKey({
    required String functionId,
    required String validity,
    String? name,
  }) async {
    final body = {
      'function_id': functionId,
      'validity': validity,
      if (name != null) 'name': name,
    };

    final response = await _client.post(
      Uri.parse('${Config.serverUrl}/api/apikey/generate'),
      headers: {
        'Authorization': 'Bearer ${Config.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to generate API key: ${response.body}');
    }
  }

  /// Get API key info for a function
  static Future<Map<String, dynamic>> getApiKeyInfo(String functionId) async {
    final response = await _client.get(
      Uri.parse('${Config.serverUrl}/api/apikey/$functionId'),
      headers: {'Authorization': 'Bearer ${Config.token}'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get API key info: ${response.body}');
    }
  }

  /// Revoke an API key
  static Future<void> revokeApiKey(String apiKeyUuid) async {
    final response = await _client.delete(
      Uri.parse('${Config.serverUrl}/api/apikey/$apiKeyUuid'),
      headers: {'Authorization': 'Bearer ${Config.token}'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to revoke API key: ${response.body}');
    }
  }

  /// List all API keys for a function
  static Future<Map<String, dynamic>> listApiKeys(String functionId) async {
    final response = await _client.get(
      Uri.parse('${Config.serverUrl}/api/apikey/$functionId/list'),
      headers: {'Authorization': 'Bearer ${Config.token}'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to list API keys: ${response.body}');
    }
  }

  /// Roll an API key (extend its expiration)
  static Future<void> rollApiKey(String apiKeyUuid) async {
    final response = await _client.put(
      Uri.parse('${Config.serverUrl}/api/apikey/$apiKeyUuid/roll'),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to roll API key: ${response.body}');
    }
  }

  /// Get deployment versions for a function
  ///
  /// Returns deployment history including version numbers, status, and active flag
  static Future<Map<String, dynamic>> getDeployments(String functionId) async {
    final response = await _client.get(
      Uri.parse('${Config.serverUrl}/api/functions/$functionId/deployments'),
      headers: {'Authorization': 'Bearer ${Config.token}'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get deployments: ${response.body}');
    }
  }

  /// Rollback function to a specific version
  ///
  /// [functionId]: The UUID of the function
  /// [version]: The version number to rollback to
  static Future<Map<String, dynamic>> rollbackFunction(
    String functionId,
    int version,
  ) async {
    final response = await http.post(
      Uri.parse('${Config.serverUrl}/api/functions/$functionId/rollback'),
      headers: {
        'Authorization': 'Bearer ${Config.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'version': version}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to rollback: ${response.body}');
    }
  }
}
