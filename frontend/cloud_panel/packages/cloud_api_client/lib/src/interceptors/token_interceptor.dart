import 'dart:async';

import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_api_client/src/common/commons.dart';
import 'package:dio/dio.dart';

class TokenAuthInterceptor extends QueuedInterceptor {
  // Storage/Service for handling token persistence (e.g., SharedPreferences)
  final TokenService _tokenService;
  final CloudApiAuthClient _apiClient;
  final Dio _refreshDio;
  int _refreshRetryCount = 0;
  final int _maxRefreshRetries = 3;

  TokenAuthInterceptor({
    required TokenService tokenService,
    required CloudApiAuthClient apiAuthClient,
    required Dio refreshDio,
  })  : _tokenService = tokenService,
        _apiClient = apiAuthClient,
        _refreshDio = refreshDio;

  // A flag to ensure only one refresh request is active at a time
  bool _isRefreshing = false;

  // A queue of requests waiting for the new token
  final _waitingRequests = <_RequestJob>[];

  // A simple class to hold the request and its handler
  // (You might define this outside or as a private inner class)

  // ... implementation of onRequest, onError, and _retry ...
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await _tokenService.token;

    if (accessToken != null && !options.headers.containsKey("Authorization")) {
      options.headers["Authorization"] = "Bearer $accessToken";
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 1. Check if the error is 401 and if we have a refresh token

    final refreshToken = await _tokenService.refreshToken;
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
          _handleRefreshFailure();
        } finally {
          _isRefreshing = false;
          // The queue should now be cleared by either success or failure
        }
      }
      // 4. Tell the original error handler to wait for the completer's result.
      // The request won't complete until we call completer.complete() or completer.completeError() later.
      return handler.resolve(await completer.future);
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

  void _handleRefreshFailure() {
    _refreshRetryCount++;

    if (_refreshRetryCount >= _maxRefreshRetries) {
      // ⚠️ CRITICAL STEP: Logout the user
      _tokenService.logout();
      _refreshRetryCount = 0;
      // Notify the UI/App to navigate to the login screen
      // (You'll need a way to communicate this event from the interceptor)

      // You could also re-throw a specific exception here to let the original caller handle the logout/error.
    }
  }

  Future<void> _retryAllWaitingRequests(String newAccessToken) async {
    _refreshRetryCount = 0;
    await Future.forEach(_waitingRequests, (job) async {
      try {
        job.options.headers["Authorization"] = "Bearer $newAccessToken";
        final response = await _refreshDio.fetch(job.options);
        job.completer.complete(response);
      } catch (e, trace) {
        job.completer.completeError(e, trace);
      }
    });
    _waitingRequests.clear(); // Clear the queue after retrying
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
