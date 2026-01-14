import 'dart:convert';

import 'package:dio/dio.dart';

import 'models/create_email_request.dart';
import 'models/create_email_response.dart';
import 'models/email.dart';
import 'models/list_emails_params.dart';

class ForwardEmailException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ForwardEmailException({required this.message, this.statusCode, this.data});

  @override
  String toString() =>
      'ForwardEmailException: $message (statusCode: $statusCode)';
}

class ForwardEmailClient {
  static const String _defaultBaseUrl = 'https://api.forwardemail.net';

  final Dio _dio;

  ForwardEmailClient({required String apiKey, String? baseUrl, Dio? dio})
    : _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl ?? _defaultBaseUrl;
    _dio.options.headers['Authorization'] = _buildBasicAuthHeader(apiKey);
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  String _buildBasicAuthHeader(String apiKey) {
    final credentials = base64Encode(utf8.encode('$apiKey:'));
    return 'Basic $credentials';
  }

  Future<List<Email>> listEmails([ListEmailsParams? params]) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/v1/emails',
        queryParameters: params?.toQueryParameters(),
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map((e) => Email.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CreateEmailResponse> createEmail(CreateEmailRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/emails',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw ForwardEmailException(
          message: 'Empty response from server',
          statusCode: response.statusCode,
        );
      }

      return CreateEmailResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ForwardEmailException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    String message;
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      message = data['message'] as String;
    } else {
      message = e.message ?? 'Unknown error occurred';
    }

    return ForwardEmailException(
      message: message,
      statusCode: statusCode,
      data: data,
    );
  }

  void close() {
    _dio.close();
  }
}
