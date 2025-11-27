import 'package:dart_cloud_function/src/dart_function_models.dart'
    show CloudResponse, CloudRequest;

abstract class CloudDartFunction {
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  });
}
