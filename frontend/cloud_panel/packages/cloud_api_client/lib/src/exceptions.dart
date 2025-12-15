class CloudApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  CloudApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'CloudApiException: $message (Status: $statusCode)';
}

class AuthException extends CloudApiException {
  AuthException(String message) : super(message, statusCode: 401);
}

class NotFoundException extends CloudApiException {
  NotFoundException(String message) : super(message, statusCode: 404);
}
