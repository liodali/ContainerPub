import 'package:dart_cloud_logger/dart_cloud_logger.dart';
import 'package:test/test.dart';

class Logger extends CloudDartFunctionLogger {
  Map<String, dynamic> logs = {};
  @override
  void printLog(LoggerTypeAction logger, String message) {
    logs[logger.name] = message;
  }
}

void main() {
  group('A group of tests', () {
    final logger = Logger();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      logger.printLog(LoggerTypeAction.error, "test error");
      expect(logger.logs[LoggerTypeAction.error.name], "test error");
      expect(logger.logs.length, 1);
    });

    test('Debug Test', () {
      logger.printLog(LoggerTypeAction.debug, "test debug");
      expect(logger.logs[LoggerTypeAction.debug.name], "test debug");
      expect(logger.logs.length, 2);
    });

    test('Info Test', () {
      logger.printLog(LoggerTypeAction.info, "test info");
      expect(logger.logs[LoggerTypeAction.info.name], "test info");
      expect(logger.logs.length, 3);
    });
    
    test('Multiple Logs Test', () {
      logger.printLog(LoggerTypeAction.error, "error message");
      logger.printLog(LoggerTypeAction.debug, "debug message");
      logger.printLog(LoggerTypeAction.info, "info message");
      expect(logger.logs.length, 3);
      expect(logger.logs[LoggerTypeAction.error.name], "error message");
      expect(logger.logs[LoggerTypeAction.debug.name], "debug message");
      expect(logger.logs[LoggerTypeAction.info.name], "info message");
    });
  });
}
