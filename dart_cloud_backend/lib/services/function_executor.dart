import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:dart_cloud_backend/configuration/config.dart';
import 'package:dart_cloud_backend/services/docker_service.dart';
import 'package:database/database.dart';

class FunctionExecutor {
  final String functionId;
  static int _activeExecutions = 0;
  static final Map<String, Timer> _containerCleanupTimers = {};

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
    try {
      // Prepare HTTP-like request structure
      final httpRequest = {
        'body': input['body'] ?? {},
        'query': input['query'] ?? {},
        'headers': input['headers'] ?? {},
        'method': input['method'] ?? 'POST',
        'raw': input['raw'] ?? null,
      };

      // Get active deployment image tag from database
      final result = await Database.connection.execute(
        '''
        SELECT fd.image_tag
        FROM functions f
        JOIN function_deployments fd ON f.active_deployment_id = fd.id
        WHERE f.id = \$1 AND fd.is_active = true
        ''',
        parameters: [functionId],
      );

      if (result.isEmpty) {
        return {
          'success': false,
          'error': 'No active deployment found for function',
          'result': null,
        };
      }

      final imageTag = result.first[0] as String;

      // Run the function in a Docker container
      final timeoutMs = Config.functionTimeoutSeconds * 1000;
      final executionResult = await DockerService.runContainer(
        imageTag: imageTag,
        input: httpRequest,
        timeoutMs: timeoutMs,
      );

      // Schedule container cleanup after 10ms
      _scheduleContainerCleanup(functionId, imageTag);

      return executionResult;
    } catch (e) {
      return {'success': false, 'error': 'Execution error: $e', 'result': null};
    }
  }

  /// Schedule container cleanup after 10ms
  static void _scheduleContainerCleanup(String functionId, String imageTag) {
    // Cancel existing timer if any
    _containerCleanupTimers[functionId]?.cancel();

    // Schedule new cleanup timer for 10ms
    _containerCleanupTimers[functionId] = Timer(
      const Duration(milliseconds: 10),
      () {
        // Cleanup is handled by Docker's --rm flag
        // This timer just ensures we track cleanup timing
        _containerCleanupTimers.remove(functionId);
      },
    );
  }

  /// Get current active executions count
  static int get activeExecutions => _activeExecutions;
}
