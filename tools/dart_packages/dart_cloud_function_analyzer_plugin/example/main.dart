// This is an INCORRECT cloud function implementation
// ❌ LINT ERROR: no_main_function_in_cloud_function
// Cloud function files should not contain a main() function

import 'package:dart_cloud_function/dart_cloud_function.dart';
import 'package:dart_cloud_logger/dart_cloud_logger.dart';

@cloudFunction
class BadExampleWithMain extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    required CloudDartFunctionLogger logger,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({'message': 'Has main function'});
  }
}

/// This will trigger: no_main_function_in_cloud_function
/// Fix: Remove the main() function - cloud functions are invoked by the runtime
void main() {
  // ❌ Cloud functions should not have a main() entry point
  print('This should not exist in a cloud function file');
}
