import 'package:dart_cloud_logger/dart_cloud_logger.dart';

class MyLogger extends CloudDartFunctionLogger {
  @override
  void printLog(
    LoggerTypeAction logger,
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    // Simple console output for example
    print('${logger.name.toUpperCase()}: $message');
    if (metadata != null) {
      print('  Metadata: $metadata');
    }
  }
}

void main() {
  var logger = MyLogger();
  logger.printLog(LoggerTypeAction.error, "This is an error message");
  logger.printLog(LoggerTypeAction.debug, "This is a debug message");
  logger.printLog(
    LoggerTypeAction.info,
    "This is an info message",
    metadata: {"source": "example"},
  );
}
