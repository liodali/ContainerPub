/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

enum LoggerTypeAction { error, debug, info }

abstract class CloudDartFunctionLogger {
  void printLog(
    LoggerTypeAction level,
    String message, {
    Map<String, dynamic>? metadata,
  });

  void error(
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    printLog(LoggerTypeAction.error, message, metadata: metadata);
  }

  void debug(
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    printLog(LoggerTypeAction.debug, message, metadata: metadata);
  }

  void info(
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    printLog(LoggerTypeAction.info, message, metadata: metadata);
  }
}

// TODO: Export any libraries intended for clients of this package.
