class OpenBaoException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  OpenBaoException(this.message, {this.statusCode, this.body});

  @override
  String toString() {
    if (statusCode != null) {
      return 'OpenBaoException: $message (Status: $statusCode)';
    }
    return 'OpenBaoException: $message';
  }
}
