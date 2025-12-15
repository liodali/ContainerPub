import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dart_cloud_cli/config/config.dart';

class ApiClient {
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

  /// Initialize a new function on the backend
  ///
  /// Creates a function record with status 'init' and returns the UUID
  static Future<Map<String, dynamic>> initFunction(String functionName) async {
    final response = await http.post(
      Uri.parse('${Config.serverUrl}/api/functions/init'),
      headers: {
        'Authorization': 'Bearer ${Config.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': functionName}),
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
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Config.serverUrl}/api/functions/deploy'),
    );

    request.headers['Authorization'] = 'Bearer ${Config.token}';
    request.fields['function_id'] = functionUuid;
    request.headers['Content-Type'] = 'multipart/form-data';
    request.files
        .add(await http.MultipartFile.fromPath('archive', archive.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Deployment failed: ${response.body}');
    }
  }

  static Future<List<dynamic>> listFunctions() async {
    final response = await http.get(
      Uri.parse('${Config.serverUrl}/api/functions'),
      headers: {'Authorization': 'Bearer ${Config.token}'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to list functions: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getFunctionLogs(String functionId) async {
    final response = await http.get(
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
    final response = await http.delete(
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
    int? timestamp,
  }) async {
    final body = data != null
        ? {
            'body': data,
          }
        : null;

    final headers = <String, String>{
      'Authorization': 'Bearer ${Config.token}',
      'Content-Type': 'application/json',
    };

    // Add signature headers if provided
    if (signature != null && timestamp != null) {
      headers['X-Signature'] = signature;
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

    final response = await http.post(
      Uri.parse('${Config.serverUrl}/api/auth/apikey/generate'),
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
    final response = await http.get(
      Uri.parse('${Config.serverUrl}/api/auth/apikey/$functionId'),
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
    final response = await http.delete(
      Uri.parse('${Config.serverUrl}/api/auth/apikey/$apiKeyUuid'),
      headers: {'Authorization': 'Bearer ${Config.token}'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to revoke API key: ${response.body}');
    }
  }

  /// List all API keys for a function
  static Future<Map<String, dynamic>> listApiKeys(String functionId) async {
    final response = await http.get(
      Uri.parse('${Config.serverUrl}/api/auth/apikey/$functionId/list'),
      headers: {'Authorization': 'Bearer ${Config.token}'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to list API keys: ${response.body}');
    }
  }
}
