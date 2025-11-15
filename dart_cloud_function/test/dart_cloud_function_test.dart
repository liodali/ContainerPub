import 'package:dart_cloud_function/dart_cloud_function.dart';
import 'package:test/test.dart';

class TestFn extends CloudDartFunction {
  @override
  Future<CloudResponse> handle(CloudRequest request) async {
    return CloudResponse.text('ok');
  }
}

void main() {
  test('handle returns CloudResponse', () async {
    final fn = TestFn();
    final res = await fn.handle(
      CloudRequest(method: 'GET', path: '/', headers: {}, query: {}),
    );
    expect(res.statusCode, 200);
  });
}
