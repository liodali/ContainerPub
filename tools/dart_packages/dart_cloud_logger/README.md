# Dart Cloud Logger

A structured logging utility for Dart cloud functions that writes logs to a JSON file with three sections: error, debug, and info.

## Features

- **Structured JSON output**: Logs are written to a JSON file with separate sections for error, debug, and info messages
- **Timestamps**: Each log entry includes an ISO 8601 timestamp
- **Metadata support**: Attach optional key-value metadata to any log entry
- **Container integration**: Designed to work with container volume mounts for log retrieval
- **Sync and async flush**: Write logs synchronously or asynchronously

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  dart_cloud_logger: ^0.3.0
```

## Usage

### Basic Usage with CloudLogger

```dart
import 'package:dart_cloud_logger/dart_cloud_logger.dart';

void main() async {
  // Create logger for container execution (writes to /logs.json)
  final logger = CloudLogger.forContainer();

  // Or for local development
  // final logger = CloudLogger.forLocal('./my-logs.json');

  // Log messages at different levels
  logger.info('Function started');
  logger.debug('Processing request', metadata: {'requestId': '123'});
  logger.error('Something went wrong', metadata: {'code': 'ERR_001'});

  // Flush logs to file before exit
  await logger.flush();
}
```

### Output Format

The logger writes a JSON file with the following structure:

```json
{
  "error": [
    {
      "message": "Something went wrong",
      "timestamp": "2024-01-15T10:30:00.000Z",
      "metadata": { "code": "ERR_001" }
    }
  ],
  "debug": [
    {
      "message": "Processing request",
      "timestamp": "2024-01-15T10:29:59.000Z",
      "metadata": { "requestId": "123" }
    }
  ],
  "info": [
    {
      "message": "Function started",
      "timestamp": "2024-01-15T10:29:58.000Z"
    }
  ]
}
```

### Custom Logger Implementation

You can also create your own logger by extending `CloudDartFunctionLogger`:

```dart
import 'package:dart_cloud_logger/dart_cloud_logger.dart';

class MyCustomLogger extends CloudDartFunctionLogger {
  @override
  void printLog(LoggerTypeAction level, String message, {Map<String, dynamic>? metadata}) {
    print('${level.name.toUpperCase()}: $message');
    if (metadata != null) {
      print('  Metadata: $metadata');
    }
  }
}
```

## Container Integration

When used in a containerized cloud function:

1. The container mounts `/logs.json` as a writable volume
2. `CloudLogger.forContainer()` writes logs to this path
3. After function execution, the backend reads `/logs.json`
4. Logs are stored in the `function_invocations` table for retrieval

## API Reference

### CloudLogger

| Method                         | Description                            |
| ------------------------------ | -------------------------------------- |
| `CloudLogger.forContainer()`   | Creates logger writing to `/logs.json` |
| `CloudLogger.forLocal([path])` | Creates logger for local development   |
| `info(message, {metadata})`    | Log an info message                    |
| `debug(message, {metadata})`   | Log a debug message                    |
| `error(message, {metadata})`   | Log an error message                   |
| `flush()`                      | Write logs to file (async)             |
| `flushSync()`                  | Write logs to file (sync)              |
| `clear()`                      | Clear all logs                         |
| `logs`                         | Get all logs as `FunctionLogs` object  |
| `toJson()`                     | Get logs as JSON map                   |

## Additional information

This package is part of the ContainerPub cloud function platform. For more information, visit the [GitHub repository](https://github.com/liodali/containerPub).
