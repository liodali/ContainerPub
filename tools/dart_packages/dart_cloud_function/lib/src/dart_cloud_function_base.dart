import 'package:dart_cloud_function/src/dart_function_models.dart'
    show CloudResponse, CloudRequest;
import 'package:dart_cloud_logger/dart_cloud_logger.dart';

abstract class CloudDartFunction {
  Future<CloudResponse> handle({
    required CloudRequest request,
    required CloudDartFunctionLogger logger,
    Map<String, String>? env,
  });
}
