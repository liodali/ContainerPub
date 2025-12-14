/// Support for doing something awesome.
///
/// More dartdocs go here.
library;


enum LoggerTypeAction {
  error,
  debug,
  info;

}

abstract class CloudDartFunctionLogger {
  void printLog(LoggerTypeAction logger,String message);
}

// TODO: Export any libraries intended for clients of this package.
