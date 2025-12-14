<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->


## Features

A simple logging utility for Dart cloud functions with support for error, debug, and info levels.

## Getting started

Add the package to your `pubspec.yaml`:
```yaml
dependencies:
  dart_cloud_logger: ^0.1.0
```

## Usage

```dart
import 'package:dart_cloud_logger/dart_cloud_logger.dart';

class MyLogger extends CloudDartFunctionLogger {
  @override
  void printLog(LoggerTypeAction logger, String message) {
    // Implement your logging logic here
    print('${logger.name.toUpperCase()}: $message');
  }
}

void main() {
  var logger = MyLogger();
  logger.printLog(LoggerTypeAction.error, "This is an error message");
  logger.printLog(LoggerTypeAction.debug, "This is a debug message");
  logger.printLog(LoggerTypeAction.info, "This is an info message");
}
```

```dart
const like = 'sample';
```

## Additional information

This package is designed to be used in cloud function environments where structured logging is needed. It provides a simple interface for logging at different levels (error, debug, info) and can be easily extended to support other logging backends.

For more information, visit the [GitHub repository](https://github.com/liodali/containerPub).
