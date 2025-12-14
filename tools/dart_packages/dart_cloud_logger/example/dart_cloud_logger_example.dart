import 'package:dart_cloud_logger/dart_cloud_logger.dart';

class MyLogger extends CloudDartFunctionLogger {
  @override
  void printLog(LoggerTypeAction logger, String message) {
    // Simple console output for example
    print('${logger.name.toUpperCase()}: $message');
  }
}

void main() {
  var logger = MyLogger();
  logger.printLog(LoggerTypeAction.error, "This is an error message");
  logger.printLog(LoggerTypeAction.debug, "This is a debug message");
  logger.printLog(LoggerTypeAction.info, "This is an info message");
}
