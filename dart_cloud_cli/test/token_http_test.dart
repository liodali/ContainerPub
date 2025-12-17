// Usage Example:
import 'package:dart_cloud_cli/api/token_http.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

// Mock HTTP client
class MockHttpClient extends Mock implements http.Client {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return super.noSuchMethod(
      Invocation.method(#send, [request]),
      returnValue: Future.value(http.StreamedResponse(Stream.value([]), 200)),
    );
  }
}

void main() {
  late TokenHttpClient tokenClient;
  late MockHttpClient mockHttpClient;
  late String currentToken;
  late String refreshedToken;

  setUp(() {
    mockHttpClient = MockHttpClient();
    currentToken = 'initial_token';
    refreshedToken = 'refreshed_token';

    tokenClient = TokenHttpClient(
      innerClient: mockHttpClient,
      getToken: () async => currentToken,
      refreshToken: () async {
        currentToken = refreshedToken;
        return refreshedToken;
      },
    );
  });

  group('TokenHttpClient - Request with Token', () {
    test('should add bearer token to protected request', () async {
      final uri = Uri.parse('https://api.example.com/protected');
      final request = http.Request('GET', uri);

      // Mock successful response
      when(mockHttpClient.send(request)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([]),
          200,
        ),
      );
      await tokenClient.send(request);

      // Verify token was added
      expect(
        request.headers['Authorization'],
        equals('Bearer $currentToken'),
      );

      // Verify the request was sent
      verify(mockHttpClient.send(request)).called(1);
    });

    test('should not add token when X-Skip-Token header is set', () async {
      final uri = Uri.parse('https://api.example.com/auth/login');
      final request = http.Request('POST', uri);
      request.headers['X-Skip-Token'] = 'true';

      when(mockHttpClient.send(request)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([]),
          200,
        ),
      );

      await tokenClient.send(request);

      // Verify token was NOT added
      expect(
        request.headers['Authorization'],
        isNull,
      );

      verify(mockHttpClient.send(request)).called(1);
    });
  });

  group('TokenHttpClient - Token Refresh on 401', () {
    test('should refresh token and retry on 401 response', () async {
      final uri = Uri.parse('https://api.example.com/protected');
      final request = http.Request('GET', uri);

      // First call returns 401, second call returns 200
      when(mockHttpClient.send(request)).thenAnswer(
        (_) async => http.StreamedResponse(Stream.value([]), 200),
      );

      final response = await tokenClient.send(request);

      // Verify token was refreshed
      expect(currentToken, equals(refreshedToken));

      // Verify response is successful
      expect(response.statusCode, equals(200));

      // Verify send was called twice (initial + retry)
      verify(mockHttpClient.send(request)).called(2);
    });

    test('should use new token in retry request', () async {
      final uri = Uri.parse('https://api.example.com/protected');
      List<http.BaseRequest> capturedRequests = [];

      when(mockHttpClient.send(http.Request('GET', uri)))
          .thenAnswer((invocation) {
        final request = invocation.positionalArguments[0] as http.BaseRequest;
        capturedRequests.add(request);

        // Return 401 on first call, 200 on second
        if (capturedRequests.length == 1) {
          return Future.value(http.StreamedResponse(Stream.value([]), 401));
        } else {
          return Future.value(http.StreamedResponse(Stream.value([]), 200));
        }
      });

      final request = http.Request('GET', uri);
      await tokenClient.send(request);

      // First request has initial token
      expect(
        capturedRequests[0].headers['Authorization'],
        equals(
          'Bearer $currentToken',
        ), // This will be the initial token before refresh
      );

      // Second request has refreshed token
      expect(
        capturedRequests[1].headers['Authorization'],
        equals('Bearer $refreshedToken'),
      );
    });

    test('should only call refresh token once for concurrent 401 requests',
        () async {
      int refreshCallCount = 0;

      tokenClient = TokenHttpClient(
        innerClient: mockHttpClient,
        getToken: () async => currentToken,
        refreshToken: () async {
          refreshCallCount++;
          currentToken = refreshedToken;
          return refreshedToken;
        },
      );
      final uri = Uri.parse('https://api.example.com/protected');
      when(mockHttpClient.send(http.Request('GET', uri))).thenAnswer(
        (_) async => http.StreamedResponse(Stream.value([]), 401),
      );

      // Send multiple requests concurrently that will all get 401
      final requests = [
        http.Request('GET', uri),
        http.Request('GET', uri),
        http.Request('GET', uri),
      ];

      // Send all requests concurrently
      await Future.wait(
        requests.map((req) => tokenClient.send(req)),
      );

      // Verify refresh token was called only once
      expect(refreshCallCount, equals(1));
    });

    test('should stop retrying after max retries exceeded', () async {
      final uri = Uri.parse('https://api.example.com/protected');
      final request = http.Request('GET', uri);

      // Always return 401
      when(mockHttpClient.send(request)).thenAnswer(
        (_) async => http.StreamedResponse(Stream.value([]), 401),
      );

      final response = await tokenClient.send(request);

      // Should return 401 after retries are exhausted
      expect(response.statusCode, equals(401));

      // Verify send was called 4 times (1 initial + 3 retries)
      verify(mockHttpClient.send(request)).called(4);
    });

    test('should handle refresh token failure gracefully', () async {
      tokenClient = TokenHttpClient(
        innerClient: mockHttpClient,
        getToken: () async => currentToken,
        refreshToken: () async {
          throw Exception('Refresh token failed');
        },
      );

      final uri = Uri.parse('https://api.example.com/protected');
      final request = http.Request('GET', uri);

      when(mockHttpClient.send(request)).thenAnswer(
        (_) async => http.StreamedResponse(Stream.value([]), 401),
      );

      // Should throw the refresh exception
      expect(
        () => tokenClient.send(request),
        throwsException,
      );
    });
  });

  group('TokenHttpClient - Integration Tests', () {
    test('should handle successful request without token refresh', () async {
      final uri = Uri.parse('https://api.example.com/data');
      final request = http.Request('GET', uri);

      when(mockHttpClient.send(request)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([]),
          200,
        ),
      );

      final response = await tokenClient.send(request);

      expect(response.statusCode, equals(200));
      expect(request.headers['Authorization'], equals('Bearer $currentToken'));
      verify(mockHttpClient.send(request)).called(1);
    });

    test('should handle POST request with body', () async {
      final uri = Uri.parse('https://api.example.com/protected');
      final request = http.Request('POST', uri);
      request.bodyBytes = [1, 2, 3];

      when(mockHttpClient.send(request)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([]),
          200,
        ),
      );

      final response = await tokenClient.send(request);

      expect(response.statusCode, equals(200));
      expect(request.headers['Authorization'], equals('Bearer $currentToken'));
      verify(mockHttpClient.send(request)).called(1);
    });
  });
}
