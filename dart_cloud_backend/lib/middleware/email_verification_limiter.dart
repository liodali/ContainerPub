import 'package:shelf/shelf.dart';
import 'package:shelf_limiter/shelf_limiter.dart';

Middleware emailVerificationLimiter(
  dynamic bodyError, {
  int maxRequests = 1,
  Duration windowSize = const Duration(minutes: 15),
}) => shelfLimiter(
  RateLimiterOptions(
    maxRequests: maxRequests,
    windowSize: windowSize,
    onRateLimitExceeded: (request) {
      return Response.forbidden(
        bodyError,
        headers: {'Content-Type': 'application/json'},
      );
    },
  ),
);
