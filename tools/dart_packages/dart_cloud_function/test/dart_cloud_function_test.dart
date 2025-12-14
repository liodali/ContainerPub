import 'package:dart_cloud_function/dart_cloud_function.dart';
import 'package:test/test.dart';
import 'package:dart_cloud_logger/dart_cloud_logger.dart';

class TestLogger extends CloudDartFunctionLogger {
  @override
  void printLog(
    LoggerTypeAction level,
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    print('$level: $message');
  }
}

class TestFn extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    required CloudDartFunctionLogger logger,
    Map<String, String>? env,
  }) async {
    logger.info('Test function called');
    return CloudResponse.text('ok');
  }
}

void main() {
  test('handle returns CloudResponse', () async {
    final fn = TestFn();
    final logger = TestLogger();
    final res = await fn.handle(
      request: CloudRequest(
        method: 'GET',
        path: '/',
        headers: {},
        query: {},
      ),
      logger: logger,
      env: {},
    );
    expect(res.statusCode, 200);
  });
}
