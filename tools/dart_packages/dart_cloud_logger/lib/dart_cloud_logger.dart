/// Dart Cloud Logger - A structured logging utility for Dart cloud functions
///
/// Provides a base logger interface for cloud functions with three log levels:
/// - error: Error messages
/// - debug: Debug messages
/// - info: Informational messages
///
/// Note: The actual CloudLogger implementation is embedded directly into
/// the generated main.dart during function deployment.
library;

/// Log level action types
enum LoggerTypeAction { error, debug, info }

/// Abstract base class for cloud function loggers
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
