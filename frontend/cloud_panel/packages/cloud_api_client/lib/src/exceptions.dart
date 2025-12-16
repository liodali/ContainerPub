class CloudApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  CloudApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'CloudApiException: $message (Status: $statusCode)';
}

class AuthException extends CloudApiException {
  AuthException(super.message) : super(statusCode: 401);
}

class NotFoundException extends CloudApiException {
  NotFoundException(super.message) : super(statusCode: 404);
}
