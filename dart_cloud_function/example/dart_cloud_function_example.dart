import 'package:dart_cloud_function/dart_cloud_function.dart';

class EchoFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({
      'method': request.method,
      'path': request.path,
      'query': request.query,
      'body': request.body,
    });
  }
}

Future<void> main() async {
  await EchoFunction().handle(
    request: CloudRequest(
      method: 'GET',
      path: '/',
      headers: {},
      query: {},
    ),
    env: {},
  );
}
