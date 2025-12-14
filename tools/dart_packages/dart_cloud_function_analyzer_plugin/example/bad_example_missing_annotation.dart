// This is an INCORRECT cloud function implementation
// ❌ LINT ERROR: missing_cloud_function_annotation
// The class extends CloudDartFunction but lacks @cloudFunction annotation

import 'package:dart_cloud_function/dart_cloud_function.dart';
import 'package:dart_cloud_logger/dart_cloud_logger.dart';

/// This will trigger: missing_cloud_function_annotation
/// Fix: Add @cloudFunction annotation above the class
class BadExampleMissingAnnotation extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    required CloudDartFunctionLogger logger,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({
      'message': 'Missing annotation 2',
    });
  }
}
