import 'package:dart_cloud_logger/dart_cloud_logger.dart';
import 'package:test/test.dart';

class Logger extends CloudDartFunctionLogger {
  Map<String, dynamic> logs = {};

  @override
  void printLog(
    LoggerTypeAction level,
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    logs[level.name] = message;

    if (metadata != null) {
      logs['${level.name}_metadata'] = metadata;
    }
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

    test('Error with Metadata Test', () {
      logger.error("error with metadata", metadata: {"key": "value"});
      expect(logger.logs[LoggerTypeAction.error.name], "error with metadata");
      expect(logger.logs["${LoggerTypeAction.error.name}_metadata"], {
        "key": "value",
      });
      expect(logger.logs.length, 4);
    });

    test('Debug with Metadata Test', () {
      logger.debug("debug with metadata", metadata: {"user_id": 123});
      expect(logger.logs[LoggerTypeAction.debug.name], "debug with metadata");
      expect(logger.logs["${LoggerTypeAction.debug.name}_metadata"], {
        "user_id": 123,
      });
      expect(logger.logs.length, 5);
    });

    test('Info with Metadata Test', () {
      logger.info("info with metadata", metadata: {"request_id": "abc123"});
      expect(logger.logs[LoggerTypeAction.info.name], "info with metadata");
      expect(logger.logs["${LoggerTypeAction.info.name}_metadata"], {
        "request_id": "abc123",
      });
      expect(logger.logs.length, 6);
    });

    test('Clear Logs Test', () {
      logger.logs.clear();
      expect(logger.logs.length, 0);
    });

    test('New Logs After Clear Test', () {
      logger.printLog(LoggerTypeAction.info, "new info");
      expect(logger.logs[LoggerTypeAction.info.name], "new info");
      expect(logger.logs.length, 1);
    });

    test('All Logs Clear Test', () {
      logger.logs.clear();
      expect(logger.logs.length, 0);

      logger.error("error after clear");
      logger.debug("debug after clear");
      logger.info("info after clear");

      expect(logger.logs.length, 3);
      expect(logger.logs[LoggerTypeAction.error.name], "error after clear");
      expect(logger.logs[LoggerTypeAction.debug.name], "debug after clear");
      expect(logger.logs[LoggerTypeAction.info.name], "info after clear");
    });
  });
}
