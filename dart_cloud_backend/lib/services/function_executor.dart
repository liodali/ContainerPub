import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:dart_cloud_backend/config/config.dart';

class FunctionExecutor {
  final String functionId;
  static int _activeExecutions = 0;

  FunctionExecutor(this.functionId);

  /// Execute function with HTTP request structure
  /// Input should contain 'body' and 'query' fields
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input) async {
    final functionDir = path.join(Config.functionsDir, functionId);
    final functionDirObj = Directory(functionDir);

    if (!await functionDirObj.exists()) {
      return {
        'success': false,
        'error': 'Function directory not found',
        'result': null,
      };
    }

    try {
      // Validate input structure - must have body and query
      if (!input.containsKey('body') && !input.containsKey('query')) {
        return {
          'success': false,
          'error': 'Invalid input: must contain "body" or "query" fields',
          'result': null,
        };
      }

      // Check concurrent execution limit
      if (_activeExecutions >= Config.functionMaxConcurrentExecutions) {
        return {
          'success': false,
          'error': 'Function execution limit reached. Try again later.',
          'result': null,
        };
      }

      _activeExecutions++;

      try {
        return await _executeFunction(input);
      } finally {
        _activeExecutions--;
      }
    } catch (e) {
      return {'success': false, 'error': 'Execution error: $e', 'result': null};
    }
  }

  Future<Map<String, dynamic>> _executeFunction(Map<String, dynamic> input) async {
    final functionDir = path.join(Config.functionsDir, functionId);

    try {
      // Prepare HTTP-like request structure
      final httpRequest = {
        'body': input['body'] ?? {},
        'query': input['query'] ?? {},
        'headers': input['headers'] ?? {},
        'method': input['method'] ?? 'POST',
      };

      // Create a temporary file with the HTTP request data
      final tempInputFile = File(path.join(functionDir, '.input.json'));
      await tempInputFile.writeAsString(jsonEncode(httpRequest));

      // Execute the Dart function
      // Look for main.dart or bin/main.dart
      String? mainFile;
      final mainDartFile = File(path.join(functionDir, 'main.dart'));
      final binMainDartFile = File(path.join(functionDir, 'bin', 'main.dart'));

      if (await mainDartFile.exists()) {
        mainFile = mainDartFile.path;
      } else if (await binMainDartFile.exists()) {
        mainFile = binMainDartFile.path;
      } else {
        return {
          'success': false,
          'error': 'No main.dart or bin/main.dart found in function',
          'result': null,
        };
      }

      // Prepare environment with database access if configured
      final environment = {
        'FUNCTION_INPUT': jsonEncode(httpRequest),
        'HTTP_BODY': jsonEncode(httpRequest['body']),
        'HTTP_QUERY': jsonEncode(httpRequest['query']),
        'HTTP_METHOD': httpRequest['method'] as String,
        // Restrict dangerous operations
        'DART_CLOUD_RESTRICTED': 'true',
        // Resource limits
        'FUNCTION_TIMEOUT_MS': (Config.functionTimeoutSeconds * 1000).toString(),
        'FUNCTION_MAX_MEMORY_MB': Config.functionMaxMemoryMb.toString(),
      };

      // Add database connection if configured
      if (Config.functionDatabaseUrl != null) {
        environment['DATABASE_URL'] = Config.functionDatabaseUrl!;
        environment['DB_MAX_CONNECTIONS'] = Config.functionDatabaseMaxConnections
            .toString();
        environment['DB_TIMEOUT_MS'] = Config.functionDatabaseConnectionTimeoutMs
            .toString();
      }

      // Run the function with a timeout and HTTP request environment
      final process = await Process.start(
        'dart',
        ['run', mainFile],
        workingDirectory: functionDir,
        environment: environment,
      );

      final stdout = <String>[];
      final stderr = <String>[];

      process.stdout.transform(utf8.decoder).listen((data) {
        stdout.add(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        stderr.add(data);
      });

      // Wait for process with configurable timeout
      final exitCode = await process.exitCode.timeout(
        Duration(seconds: Config.functionTimeoutSeconds),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );

      // Clean up temp file
      if (await tempInputFile.exists()) {
        await tempInputFile.delete();
      }

      if (exitCode == -1) {
        return {
          'success': false,
          'error': 'Function execution timed out (${Config.functionTimeoutSeconds}s)',
          'result': null,
        };
      }

      if (exitCode != 0) {
        return {
          'success': false,
          'error': 'Function exited with code $exitCode: ${stderr.join()}',
          'result': null,
        };
      }

      // Try to parse output as JSON, otherwise return as string
      final output = stdout.join().trim();
      dynamic result;

      try {
        result = jsonDecode(output);
      } catch (e) {
        result = output;
      }

      return {'success': true, 'error': null, 'result': result};
    } catch (e) {
      return {'success': false, 'error': 'Execution error: $e', 'result': null};
    }
  }

  /// Get current active executions count
  static int get activeExecutions => _activeExecutions;
}
