import 'dart:convert';
import 'dart:io';

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
    final method = input['method'] as String? ?? 'POST';
    
    // Call the handler
    final result = await handler(body, query, method);
    
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

/// Handler function that processes the HTTP request
@function
Future<Map<String, dynamic>> handler(
  Map<String, dynamic> body,
  Map<String, dynamic> query,
  String method,
) async {
  // Extract name from body or query
  final name = body['name'] as String? ?? query['name'] as String? ?? 'World';
  
  // Return response
  return {
    'success': true,
    'message': 'Hello, $name!',
    'timestamp': DateTime.now().toIso8601String(),
    'method': method,
    'receivedBody': body,
    'receivedQuery': query,
  };
}
