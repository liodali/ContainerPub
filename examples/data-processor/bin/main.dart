import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class MyProcessor extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    // Read input from environment variable
    final inputJson = Platform.environment['FUNCTION_INPUT'] ?? '{}';
    final input = jsonDecode(inputJson) as Map<String, dynamic>;

    // Extract numbers array
    final numbers = (input['numbers'] as List?)?.cast<num>() ?? [];

    if (numbers.isEmpty) {
      print(jsonEncode({
        'error': 'No numbers provided',
        'usage': 'Send {"numbers": [1, 2, 3, 4, 5]}'
      }));
      return CloudResponse(
        body: jsonEncode({
          'error': 'No numbers provided',
          'usage': 'Send {"numbers": [1, 2, 3, 4, 5]}'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // Calculate statistics
    final sum = numbers.fold<num>(0, (a, b) => a + b);
    final average = sum / numbers.length;
    final min = numbers.reduce((a, b) => a < b ? a : b);
    final max = numbers.reduce((a, b) => a > b ? a : b);

    // Calculate standard deviation
    final variance =
        numbers.map((n) => pow(n - average, 2)).fold<num>(0, (a, b) => a + b) /
            numbers.length;
    final stdDev = sqrt(variance);

    // Create response
    final result = {
      'count': numbers.length,
      'sum': sum,
      'average': average,
      'min': min,
      'max': max,
      'standard_deviation': stdDev,
      'processed_at': DateTime.now().toIso8601String(),
    };

    // Output result as JSON
    print(jsonEncode(result));
    return CloudResponse(
      body: jsonEncode(result),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
