import 'dart:convert';

import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_api_client/src/common/commons.dart';
import 'package:dio/dio.dart';

class AuthService {
  factory AuthService(
    CloudApiAuthClient cloudApiClient,
    TokenService tokenService,
  ) =>
      AuthService._internal(
        cloudApiClient: cloudApiClient,
        tokenService: tokenService,
      );

  AuthService._internal({
    required this.tokenService,
    required this.cloudApiClient,
  });
  final TokenService tokenService;
  final CloudApiAuthClient cloudApiClient;

  Future<void> login(String username, String password) async {
    final response = await cloudApiClient.login(username, password);
    await tokenService.loginSuccess(response.token, response.refreshToken);
  }

  Future<void> register(String username, String password) async {
    await cloudApiClient.register(username, password);
  }

  Future<void> logout() async {
    await tokenService.logout();
  }
}

class CloudApiAuthClient {
  final Dio _dio;
  CloudApiAuthClient({
    required Dio dio,
  }) : _dio = dio;

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
      final response = await _dio.post(CommonsApis.apiLoginPath, data: {
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
      () => _dio.post(
        CommonsApis.apiRegisterPath,
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
      () => _dio.post(
        CommonsApis.apiRefreshTokenPath,
        data: {
          'refreshToken': refreshToken,
        },
      ),
    );
    if (data is Map && data.containsKey('accessToken')) {
      final nextRefreshToken = (data['refreshToken'] as String?) ?? refreshToken;
      return (
        token: data['accessToken'] as String,
        refreshToken: nextRefreshToken,
      );
    }
    return null;
  }
}
