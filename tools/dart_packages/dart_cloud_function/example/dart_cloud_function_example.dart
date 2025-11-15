import 'package:dart_cloud_function/dart_cloud_function.dart';

/// Example cloud function that echoes back the request details
///
/// This demonstrates the proper structure for a cloud function:
/// - Exactly one class extending CloudDartFunction
/// - Annotated with @cloudFunction
/// - No main() function
@cloudFunction
class EchoFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({
      'message': 'Echo Function',
      'method': request.method,
      'path': request.path,
      'query': request.query,
      'body': request.body,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
