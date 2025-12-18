import 'dart:convert';
import 'dart:math';

import 'package:dart_cloud_function/dart_cloud_function.dart';
import 'package:dart_cloud_logger/dart_cloud_logger.dart';

extension ExtCloudRequest on CloudRequest {
  String str() {
    return 'CloudRequest(method: $method, path: $path, headers: $headers, query: $query, body: $body)';
  }
}

@cloudFunction
class MyProcessor extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    required CloudDartFunctionLogger logger,
    Map<String, String>? env,
  }) async {
    logger.info(request.str());
    // Read input from environment variable
    final input = request.body is String
        ? jsonDecode(request.body as String) as Map<String, dynamic>
        : (request.body as Map<String, dynamic>? ?? {});

    // Extract numbers array
    final numbers = (input['numbers'] as List?)?.cast<num>() ?? [];

    if (numbers.isEmpty) {
      logger.error(jsonEncode({
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
    final diffMinMax = max - min;
    final sumLog = numbers.fold<num>(0, (a, b) => a + log(b));

    // Calculate standard deviation
    final variance =
        numbers.map((n) => pow(n - average, 2)).fold<num>(0, (a, b) => a + b) /
            numbers.length;
    final stdDev = sqrt(variance);

    // Create response
    final result = {
      'count': numbers.length,
      'sum': sum,
      'log': sumLog,
      'average': average,
      'min': min,
      'max': max,
      'diffMinMax': diffMinMax,
      'standard_deviation': stdDev,
      'processed_at': DateTime.now().toIso8601String(),
    };

    // Output result as JSON
    logger.info('Processed data: ${jsonEncode(result)}');
    return CloudResponse(
      body: jsonEncode(result),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
