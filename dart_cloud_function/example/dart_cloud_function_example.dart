import 'package:dart_cloud_function/dart_cloud_function.dart';

class EchoFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle(CloudRequest request) async {
    return CloudResponse.json({
      'method': request.method,
      'path': request.path,
      'query': request.query,
      'body': request.body,
    });
  }
}

Future<void> main() async {
  await EchoFunction().serve(port: 8080);
}
