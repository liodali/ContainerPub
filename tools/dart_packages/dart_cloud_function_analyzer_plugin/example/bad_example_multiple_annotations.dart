// This is an INCORRECT cloud function implementation
// ❌ LINT ERROR: multiple_cloud_function_annotations
// The class has duplicate @cloudFunction annotations

import 'package:dart_cloud_function/dart_cloud_function.dart';
import 'package:dart_cloud_logger/dart_cloud_logger.dart';

/// This will trigger: multiple_cloud_function_annotations
/// Fix: Remove duplicate @cloudFunction annotations (keep only one)
@cloudFunction
@cloudFunction // ❌ Duplicate annotation
class BadExampleMultipleAnnotations extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    required CloudDartFunctionLogger logger,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({
      'message': 'Multiple annotations',
    });
  }
}
