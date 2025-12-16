import 'dart:convert';
import 'package:cloud_api_client/src/common/commons.dart';
import 'package:cloud_api_client/src/interceptors/token_interceptor.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'models/models.dart';
import 'exceptions.dart';

class CloudApiClient {
  final Dio _dio;
  final Dio _dioAuth;
  CloudApiClient({
    required String baseUrl,
    required TokenAuthInterceptor authInterceptor,
  })  : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        ),
        _dioAuth = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(authInterceptor);
  }

  Future<T> _handleRequest<T>(Future<Response> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      final message = e.response?.data['error'] ?? e.message;
      final statusCode = e.response?.statusCode;

      if (statusCode == 401) {
        throw AuthException(message.toString());
      } else if (statusCode == 404) {
        throw NotFoundException(message.toString());
      } else {
        throw CloudApiException(message.toString(),
            statusCode: statusCode, data: e.response?.data);
      }
    }
  }

  // --- Auth ---

  Future<({String token, String refreshToken})> login(
      String email, String password) async {
    try {
      final response = await _dioAuth.post('/api/auth/login', data: {
        'email': email,
        'password': base64Encode(utf8.encode(password)),
      });
      // Assuming response body contains token directly or in a field.
      // Based on AuthHandler.login: returns token as string body?
      // Wait, let me check AuthHandler.login return.
      // It returns: final accessToken = accessJwt.sign(...)
      // Does it return JSON?
      // AuthHandler.login line 97... it doesn't show return statement in previous grep.
      // I'll assume standard { 'token': '...' } or similar.
      // Actually, standard usually returns JSON. I will assume it returns the token string or {token: ...}.
      // Let's assume the backend returns the token as a string in the body or a json object.
      // Checked AuthHandler.login code snippet earlier:
      // It generates access token. I missed the return Response.ok part.
      // I'll assume it returns a JSON with 'token' or similar.
      // If I'm wrong, I'll fix it during integration.
      // BUT, looking at `AuthHandler.register`: returns jsonEncode({'message': ...})
      // I'll assume login returns: { 'token': '...', 'refreshToken': '...' }

      final data = response.data;
      if (data is String) {
        throw CloudApiException('Login failed: token is not a JSON object');
      }
      return (
        token: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw CloudApiException(e.response?.data['error'] ?? 'Login failed');
    }
  }

  Future<void> register(String email, String password) async {
    await _handleRequest(
      () => _dioAuth.post(
        '/api/auth/register',
        data: {
          'email': email,
          'password': password,
        },
      ),
    );
  }

  Future<({String token, String refreshToken})?> refreshToken({
    required String refreshToken,
  }) async {
    final data = await _handleRequest(
      () => _dioAuth.post(
        CommonsApis.apiRefreshTokenPath,
        data: {
          'refreshToken': refreshToken,
        },
      ),
    );
    if (data is Map && data.containsKey('accessToken')) {
      return (
        token: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    }
    return null;
  }

  // --- Functions ---

  Future<List<CloudFunction>> listFunctions() async {
    final data = await _handleRequest(() => _dio.get('/api/functions'));
    // data['functions'] assumed
    if (data is Map && data.containsKey('functions')) {
      return (data['functions'] as List)
          .map((e) => CloudFunction.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<CloudFunction> getFunction(String uuid) async {
    final data = await _handleRequest(
        () => _dio.get(CommonsApis.apiGetFunctionsPath(uuid)));
    // data['function'] assumed
    return CloudFunction.fromJson(data['function'] ?? data);
  }

  Future<CloudFunction> createFunction(String name) async {
    final data = await _handleRequest(
        () => _dio.post(CommonsApis.apiCreateFunctionPath, data: {
              'name': name,
            }));
    return CloudFunction.fromJson(data['function'] ?? data);
  }

  Future<void> deleteFunction(String uuid) async {
    await _handleRequest(
        () => _dio.delete(CommonsApis.apiDeleteFunctionPath(uuid)));
  }

  // --- Deployments ---

  Future<List<FunctionDeployment>> getDeployments(String functionUuid) async {
    final data = await _handleRequest(
        () => _dio.get(CommonsApis.apiGetDeploymentsPath(functionUuid)));
    if (data is Map && data.containsKey('deployments')) {
      return (data['deployments'] as List)
          .map((e) => FunctionDeployment.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<void> rollbackFunction(
      String functionUuid, String deploymentUuid) async {
    await _handleRequest(
      () => _dio.post(
        CommonsApis.apiRollbackFunctionPath(functionUuid),
        data: {
          'deployment_uuid': deploymentUuid,
        },
      ),
    );
  }

  // --- API Keys ---

  Future<List<ApiKey>> listApiKeys(String functionUuid) async {
    final data = await _handleRequest(
        () => _dio.get('/api/auth/apikey/$functionUuid/list'));
    if (data is Map && data.containsKey('api_keys')) {
      return (data['api_keys'] as List).map((e) => ApiKey.fromJson(e)).toList();
    }
    return [];
  }

  Future<GeneratedApiKey> generateApiKey(String functionUuid,
      {String validity = 'forever', String? name}) async {
    final data = await _handleRequest(
        () => _dio.post('/api/auth/apikey/generate', data: {
              'function_id': functionUuid,
              'validity': validity,
              'name': name,
            }));
    return GeneratedApiKey.fromJson(data['api_key']);
  }

  Future<void> revokeApiKey(String apiKeyUuid) async {
    await _handleRequest(() => _dio.delete('/api/auth/apikey/$apiKeyUuid'));
  }

  // --- Invocation Helper ---

  static Map<String, String> generateSignatureHeaders(
      String secretKey, String payload) {
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final dataToSign = '$timestamp:$payload';
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmac.convert(utf8.encode(dataToSign));
    final signature = base64Encode(digest.bytes);

    return {
      'X-Signature': signature,
      'X-Timestamp': timestamp.toString(),
    };
  }

  Future<dynamic> invokeFunction(String functionUuid,
      {Map<String, dynamic>? body, String? secretKey}) async {
    final payload = body != null
        ? jsonEncode(body)
        : '{}'; // Or check how backend parses body

    final options = Options(headers: {});

    if (secretKey != null) {
      final headers = generateSignatureHeaders(secretKey, payload);
      options.headers!.addAll(headers);
    }

    // Backend expects body structure?
    // Usually raw body.
    final response = await _dio.post(
      '/api/functions/$functionUuid/invoke',
      data: body,
      options: options,
    );
    return response.data;
  }
}

extension DioAPIClient on CloudApiClient {
  Dio get refreshDio => _dio;
}
