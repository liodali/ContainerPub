import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Annotation to mark this as a cloud function
const function = 'function';

/// Main entry point for the cloud function
@function
void main() async {
  try {
    // Read HTTP request from environment
    final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');

    // Extract body and query parameters
    final body = input['body'] as Map<String, dynamic>? ?? {};
    final query = input['query'] as Map<String, dynamic>? ?? {};

    // Call the handler
    final result = await handler(body, query);

    // Return JSON response to stdout
    print(jsonEncode(result));
  } catch (e) {
    // Return error response
    print(jsonEncode({
      'error': 'Function execution failed',
      'message': e.toString(),
    }));
    exit(1);
  }
}

/// Handler function that makes HTTP requests
@function
Future<Map<String, dynamic>> handler(
  Map<String, dynamic> body,
  Map<String, dynamic> query,
) async {
  // Get URL from body or query
  final url = body['url'] as String? ?? query['url'] as String?;

  if (url == null) {
    return {
      'success': false,
      'error': 'URL parameter is required',
    };
  }

  try {
    // Make HTTP GET request (allowed operation)
    final response = await http
        .get(
          Uri.parse(url),
        )
        .timeout(const Duration(seconds: 10));

    return {
      'success': true,
      'statusCode': response.statusCode,
      'headers': response.headers,
      'bodyLength': response.body.length,
      'contentType': response.headers['content-type'],
    };
  } catch (e) {
    return {
      'success': false,
      'error': 'HTTP request failed',
      'message': e.toString(),
    };
  }
}
