import 'dart:async';

import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_api_client/src/common/commons.dart';
import 'package:dio/dio.dart';

class TokenAuthInterceptor extends QueuedInterceptor {
  // Storage/Service for handling token persistence (e.g., SharedPreferences)
  final TokenService _tokenService;
  final CloudApiAuthClient _apiClient;
  final Dio _refreshDio;
  final void Function()? onLogout;
  int _refreshRetryCount = 0;
  final int _maxRefreshRetries = 3;

  TokenAuthInterceptor({
    required TokenService tokenService,
    required CloudApiAuthClient apiAuthClient,
    required Dio refreshDio,
    this.onLogout,
  })  : _tokenService = tokenService,
        _apiClient = apiAuthClient,
        _refreshDio = refreshDio;

  // A flag to ensure only one refresh request is active at a time
  bool _isRefreshing = false;

  // A queue of requests waiting for the new token
  final _waitingRequests = <_RequestJob>[];

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = _tokenService.token;

    if (accessToken != null && !options.headers.containsKey("Authorization")) {
      options.headers["Authorization"] = "Bearer $accessToken";
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 1. Check if the error is 401 and if we have a refresh token

    final refreshToken = _tokenService.refreshToken;
    if (err.response?.statusCode == 401 &&
        refreshToken != null &&
        err.requestOptions.path != CommonsApis.apiRefreshTokenPath) {
      // Avoid infinite loop

      final options = err.requestOptions;
      // 1. Create a Completer to hold the request result
      final completer = Completer<Response<dynamic>>();

      // 2. Add the failing request to the queue
      _waitingRequests.add(_RequestJob(options, completer));

      // 3. Start refresh process only if it's not already running
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final newAccessToken = await _performTokenRefresh(refreshToken);

          // Refresh was successful, retry all queued requests
          await _retryAllWaitingRequests(newAccessToken);
        } catch (e) {
          // Refresh failed (e.g., token expired, invalid, or network error)
          _handleRefreshFailure(e);
        } finally {
          _isRefreshing = false;
          // The queue should now be cleared by either success or failure
        }
      }
      // 4. Tell the original error handler to wait for the completer's result.
      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          return handler.reject(e);
        }
        return handler.reject(DioException(requestOptions: options, error: e));
      }
    } else {
      // Not a 401, or no refresh token, or refresh route failed (handled by _handleRefreshFailure)
      super.onError(err, handler);
    }
  }

  Future<String> _performTokenRefresh(String refreshToken) async {
    // Use a separate Dio instance (`_refreshDio`) to ensure it doesn't
    // get caught in its own interceptor loop.
    final response = await _apiClient.refreshToken(
      refreshToken: refreshToken,
    );

    if (response != null) {
      _refreshRetryCount = 0; // Reset counter on success
      final newAccessToken = response.token;
      final newRefreshToken = response.refreshToken;
      await _tokenService.loginSuccess(newAccessToken, newRefreshToken);
      return newAccessToken;
    } else {
      // If refresh endpoint returns a non-200 code
      throw AuthException('Failed to refresh token');
    }
  }

  void _handleRefreshFailure(Object error) {
    _refreshRetryCount++;

    // Fail all pending requests
    for (var job in _waitingRequests) {
      if (!job.completer.isCompleted) {
        job.completer.completeError(error);
      }
    }
    _waitingRequests.clear();

    if (_refreshRetryCount >= _maxRefreshRetries) {
      // ⚠️ CRITICAL STEP: Logout the user
      _tokenService.logout();
      onLogout?.call();
      _refreshRetryCount = 0;
    }
  }

  Future<void> _retryAllWaitingRequests(String newAccessToken) async {
    _refreshRetryCount = 0;
    // We iterate a copy because we clear the list at the end
    // (though Future.forEach iterates the iterable, it's safer to not modify while iterating if strictly standard, but _waitingRequests is List)
    final requestsToRetry = List<_RequestJob>.from(_waitingRequests);
    _waitingRequests.clear();

    await Future.forEach(requestsToRetry, (job) async {
      try {
        job.options.headers["Authorization"] = "Bearer $newAccessToken";
        final response = await _refreshDio.fetch(job.options);
        job.completer.complete(response);
      } catch (e, trace) {
        job.completer.completeError(e, trace);
      }
    });
  }
}

class _RequestJob {
  final RequestOptions options;
  final Completer<Response<dynamic>> completer;
  _RequestJob(
    this.options,
    this.completer,
  );
}
