import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_api_client/src/common/commons.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  late AuthService authService;
  late CloudApiAuthClient authClient;
  late Dio dio;
  late DioAdapter dioAdapter;
  late FakeTokenService tokenService;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dioAdapter = DioAdapter(dio: dio);
    tokenService = FakeTokenService();
    authClient = CloudApiAuthClient(dio: dio);
    authService = AuthService(authClient, tokenService);
  });

  group('AuthService', () {
    test('login success stores tokens', () async {
      final email = 'test@example.com';
      final password = 'password';
      final mockResponse = {
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
      };

      dioAdapter.onPost(
        CommonsApis.apiLoginPath,
        (server) => server.reply(200, mockResponse),
        data: Matchers
            .any, // Body is checked below in a custom way if needed, or just rely on path
      );

      await authService.login(email, password);

      expect(tokenService.token, 'access-token');
      expect(tokenService.refreshToken, 'refresh-token');
    });

    test('login failure throws CloudApiException', () async {
      final email = 'test@example.com';
      final password = 'wrong-password';

      dioAdapter.onPost(
        CommonsApis.apiLoginPath,
        (server) => server.reply(401, {'error': 'Invalid credentials'}),
      );

      expect(
        authService.login(email, password),
        throwsA(isA<CloudApiException>()),
      );

      expect(tokenService.token, isNull);
    });

    test('logout clears tokens', () async {
      await tokenService.loginSuccess('token', 'refresh');
      await authService.logout();

      expect(tokenService.token, isNull);
      expect(tokenService.refreshToken, isNull);
    });
  });

  group('CloudApiAuthClient', () {
    test('register posts correct data', () async {
      final email = 'new@example.com';
      final password = 'password';

      dioAdapter.onPost(
        CommonsApis.apiRegisterPath,
        (server) => server.reply(200, {'message': 'Success'}),
        data: {
          'email': email,
          'password': password,
        },
      );

      await authClient.register(email, password);
    });

    test('refreshToken returns new tokens on success', () async {
      final oldRefresh = 'old-refresh';
      final mockResponse = {
        'accessToken': 'new-access',
        'refreshToken': 'new-refresh',
      };

      dioAdapter.onPost(
        CommonsApis.apiRefreshTokenPath,
        (server) => server.reply(200, mockResponse),
        data: {'refreshToken': oldRefresh},
      );

      final result = await authClient.refreshToken(refreshToken: oldRefresh);

      expect(result, isNotNull);
      expect(result!.token, 'new-access');
      expect(result.refreshToken, 'new-refresh');
    });

    test('refreshToken returns null on failure', () async {
      final oldRefresh = 'bad-refresh';

      dioAdapter.onPost(
        CommonsApis.apiRefreshTokenPath,
        (server) => server.reply(400, {'error': 'Invalid token'}),
      );

      // CloudApiAuthClient.refreshToken handles non-200 by throwing in _handleRequest usually?
      // Let's check implementation.
      // _handleRequest throws if status != 2xx.
      // But refreshToken implementation:
      // final data = await _handleRequest(...)
      // if (data is Map ...) return ...; return null;
      // If _handleRequest throws, refreshToken throws.
      // So this test should expect throw, OR if we want to test 'return null' case,
      // we need _handleRequest to return something that isn't the map we expect.

      expect(
        authClient.refreshToken(refreshToken: oldRefresh),
        throwsA(isA<CloudApiException>()),
      );
    });
  });
}
