import 'package:http/http.dart' as http;

class TokenHttpClient extends http.BaseClient {
  final Future<String?> Function() getToken;
  final Future<String?> Function() refreshToken;
  final http.Client _inner;

  int _retryCount = 0;
  static const int _maxRetries = 3;

  // Ensure refresh token is called only once
  Future<String?>? _refreshTokenFuture;

  TokenHttpClient({
    required this.getToken,
    required this.refreshToken,
    http.Client? innerClient,
  }) : _inner = innerClient ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Skip token for requests marked as public
    if (!_isPublicRequest(request)) {
      // Add bearer token to request
      final token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    var response = await _inner.send(request);

    // Handle 401 Unauthorized
    if (response.statusCode == 401 || response.statusCode == 403) {
      return await _handleUnauthorized(request);
    }

    return response;
  }

  Future<http.StreamedResponse> _handleUnauthorized(
    http.BaseRequest request,
  ) async {
    if (_retryCount < _maxRetries) {
      try {
        _retryCount++;

        // Ensure refresh token is called only once
        final newToken = await (_refreshTokenFuture ??= refreshToken());

        if (newToken != null) {
          // Create a new request with the same properties
          final newRequest = _copyRequest(request);
          newRequest.headers['Authorization'] = 'Bearer $newToken';

          // Retry the request
          final retryResponse = await _inner.send(newRequest);

          _retryCount = 0;
          _refreshTokenFuture = null;

          return retryResponse;
        }
      } catch (e) {
        _retryCount = 0;
        _refreshTokenFuture = null;
        rethrow;
      }
    } else {
      // Max retries exceeded
      _retryCount = 0;
      _refreshTokenFuture = null;
    }

    // Return the original 401 response if refresh failed or max retries exceeded
    return _inner.send(request);
  }

  // Helper method to check if request should skip token
  bool _isPublicRequest(http.BaseRequest request) {
    // Check for custom header marker
    return request.headers.containsKey('X-Skip-Token') &&
        request.headers['X-Skip-Token'] == 'true';
  }

  /// Send a multipart request with automatic token handling and refresh
  ///
  /// [method]: HTTP method (e.g., 'POST', 'PUT')
  /// [url]: The request URL
  /// [fields]: Form fields to include
  /// [files]: Files to upload
  /// [headers]: Additional headers (Authorization will be added automatically)
  Future<http.Response> sendMultipartRequest(
    String method,
    Uri url, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Map<String, String>? headers,
  }) async {
    final request = http.MultipartRequest(method, url);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (files != null) {
      request.files.addAll(files);
    }

    if (headers != null) {
      request.headers.addAll(headers);
    }

    final streamedResponse = await send(request);
    return http.Response.fromStream(streamedResponse);
  }

  // Helper method to copy request (required because requests can only be sent once)
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    http.BaseRequest requestCopy;

    if (request is http.Request) {
      requestCopy = http.Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      requestCopy = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw UnsupportedError('Cannot copy StreamedRequest');
    } else {
      throw UnsupportedError('Unknown request type: $request');
    }

    requestCopy
      ..persistentConnection = request.persistentConnection
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..headers.addAll(request.headers);

    return requestCopy;
  }
}
