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
      'password': base64.encode(password.codeUnits)
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

  static Future<Map<String, dynamic>> deployFunction(
    File archive,
    String functionName,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Config.serverUrl}/api/functions/deploy'),
    );

    request.headers['Authorization'] = 'Bearer ${Config.token}';
    request.fields['name'] = functionName;
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
    Map<String, dynamic>? data,
  ) async {
    final body = data != null
        ? {
            'body': data,
          }
        : null;
    final response = await http.post(
      Uri.parse('${Config.serverUrl}/api/functions/$functionId/invoke'),
      headers: {
        'Authorization': 'Bearer ${Config.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body ?? {}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to invoke function: ${response.body}');
    }
  }
}
