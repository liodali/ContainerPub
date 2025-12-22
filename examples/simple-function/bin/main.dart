import 'dart:convert';
import 'dart:math';

import 'package:dart_cloud_function/dart_cloud_function.dart';
import 'package:dart_cloud_logger/dart_cloud_logger.dart';

/// Main entry point for the cloud function
@cloudFunction
class MyProcessor extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    required CloudDartFunctionLogger logger,
    Map<String, String>? env,
  }) async {
    // Read input from environment variable
    final input = request.body is String
        ? jsonDecode(request.body as String) as Map<String, dynamic>
        : (request.body as Map<String, dynamic>? ?? {});
    final proccessingtime = Random().nextInt(15) + 5;
    logger.info('Processing for $proccessingtime seconds');
    await Future.delayed(Duration(seconds: proccessingtime));
    logger.info('Processing done');
    // Extract name from body or query
    final name = input['name'] as String? ?? request.query['name'] ?? 'World';
    ;
    // Output result as JSON
    logger.info('response generated');
    return CloudResponse(
      body: jsonEncode({
        'success': true,
        'message': 'Hello, $name!',
        'timestamp': DateTime.now().toIso8601String(),
        'method': request.method,
        'receivedBody': input,
        'receivedQuery': request.query,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
