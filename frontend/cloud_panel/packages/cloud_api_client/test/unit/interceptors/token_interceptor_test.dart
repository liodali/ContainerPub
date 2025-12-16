import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_api_client/src/common/commons.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

import '../../mocks.dart';

void main() {
  late TokenAuthInterceptor interceptor;
  late FakeTokenService tokenService;
  late Dio mainDio;
  late Dio refreshDio;
  late DioAdapter mainAdapter;
  late DioAdapter refreshAdapter;
  late CloudApiAuthClient authClient;

  setUp(() {
    tokenService = FakeTokenService();

    // Setup Refresh/Auth Dio
    refreshDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    refreshAdapter = DioAdapter(dio: refreshDio);
    authClient = CloudApiAuthClient(dio: refreshDio);

    // Setup Main Dio
    mainDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    mainAdapter = DioAdapter(dio: mainDio);

    interceptor = TokenAuthInterceptor(
      tokenService: tokenService,
      apiAuthClient: authClient,
      refreshDio: refreshDio,
    );

    mainDio.interceptors.add(interceptor);
  });

  test('Interceptor injects token if available', () async {
    await tokenService.loginSuccess('access-token', 'refresh-token');

    mainAdapter.onGet(
      '/test',
      (server) {
        // Verify header
        // Since we can't easily inspect request in adapter callback in this lib version easily (maybe),
        // we can check if it works. But better to check headers.
        // http_mock_adapter passes 'request' as first arg?
        // No, `(server)`.
        // But we can check `mainDio` request options via a custom interceptor or just trust that if we set matchers.
        // Actually, we can just return the headers in the body to verify.
        server.reply(200, {'status': 'ok'});
      },
      headers: {'Authorization': 'Bearer access-token'}, // Matcher!
    );

    await mainDio.get('/test');
  });

  test('Interceptor refreshes token on 401 and retries', () async {
    await tokenService.loginSuccess('expired-token', 'valid-refresh');

    // 1. Mock Refresh Endpoint
    refreshAdapter.onPost(
      CommonsApis.apiRefreshTokenPath,
      (server) => server.reply(200, {
        'accessToken': 'new-access-token',
        'refreshToken': 'new-refresh-token',
      }),
      data: {'refreshToken': 'valid-refresh'},
    );

    // 2. Mock Main Endpoint: Fail 401 then Succeed
    // The retry will use refreshDio, so we need to mock success on refreshAdapter too
    refreshAdapter.onGet(
      '/test-refresh',
      (server) => server.reply(200, {'data': 'success'}),
    );

    int callCount = 0;
    mainAdapter.onGet(
      '/test-refresh',
      (server) {
        if (callCount == 0) {
          callCount++;
          server.reply(401, {'error': 'Unauthorized'});
        } else {
          server.reply(200, {'data': 'success'});
        }
      },
    );

    // Execute
    final response = await mainDio.get('/test-refresh');

    expect(response.data['data'], 'success');
    expect(await tokenService.token, 'new-access-token');
    expect(callCount,
        1); // 1 failure + 1 success (handled by adapter internal logic? No, retry calls adapter again)
    // Wait, retry calls fetch again. So adapter lambda runs again.
  });

  test('Interceptor logs out on refresh failure', () async {
    await tokenService.loginSuccess('expired-token', 'bad-refresh');

    // 1. Mock Refresh Endpoint to Fail
    refreshAdapter.onPost(
      CommonsApis.apiRefreshTokenPath,
      (server) => server.reply(400, {'error': 'Invalid refresh token'}),
      data: Matchers.any,
    );

    // 2. Mock Main Endpoint to 401
    mainAdapter.onGet(
      '/test-logout',
      (server) => server.reply(401, {'error': 'Unauthorized'}),
    );

    // Execute 3 times to trigger logout (max retries = 3)
    for (int i = 0; i < 3; i++) {
      try {
        await mainDio.get('/test-logout');
      } catch (e) {
        // Expected to fail
      }
    }

    expect(await tokenService.token, isNull); // Should be logged out
  });

  test('Interceptor queues concurrent requests during refresh', () async {
    await tokenService.loginSuccess('expired-token', 'valid-refresh');

    // Mock Refresh
    refreshAdapter.onPost(
      CommonsApis.apiRefreshTokenPath,
      (server) => server.reply(200, {
        'accessToken': 'new-access-token',
        'refreshToken': 'new-refresh-token',
      }),
      data: Matchers.any,
    );

    // Mock Endpoints
    // Retries go to refreshAdapter
    refreshAdapter.onGet('/test-1', (server) => server.reply(200, {'id': 1}));
    refreshAdapter.onGet('/test-2', (server) => server.reply(200, {'id': 2}));

    int callCount1 = 0;
    mainAdapter.onGet('/test-1', (server) {
      if (callCount1 == 0) {
        callCount1++;
        server.reply(401, {});
      } else {
        server.reply(200, {'id': 1});
      }
    });

    int callCount2 = 0;
    mainAdapter.onGet('/test-2', (server) {
      if (callCount2 == 0) {
        callCount2++;
        server.reply(401, {});
      } else {
        server.reply(200, {'id': 2});
      }
    });

    // Fire two requests "simultaneously"
    final results = await Future.wait([
      mainDio.get('/test-1'),
      mainDio.get('/test-2'),
    ]);

    expect(results[0].data['id'], 1);
    expect(results[1].data['id'], 2);
    expect(await tokenService.token, 'new-access-token');
  });
}
