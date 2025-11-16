// This is a CORRECT cloud function implementation
// It demonstrates proper usage that passes all lint rules

import 'package:dart_cloud_function/dart_cloud_function.dart';

/// Example of a properly structured cloud function
/// - Has @cloudFunction annotation
/// - Extends CloudDartFunction
/// - No main() function
@cloudFunction
class GoodExampleFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({
      'message': 'This is a good example',
      'method': request.method,
      'path': request.path,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
