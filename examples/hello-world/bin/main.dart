import 'dart:convert';
import 'dart:io';

void main() {
  // Read input from environment variable
  final inputJson = Platform.environment['FUNCTION_INPUT'] ?? '{}';
  final input = jsonDecode(inputJson) as Map<String, dynamic>;

  // Process the input
  final name = input['name'] ?? 'World';

  // Create response
  final result = {
    'message': 'Hello, $name!',
    'timestamp': DateTime.now().toIso8601String(),
    'input_received': input,
  };

  // Output result as JSON
  print(jsonEncode(result));
}
