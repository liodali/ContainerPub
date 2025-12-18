import 'dart:async';
import 'package:dart_cloud_backend/handlers/logs_utils/functions_utils.dart';
import 'package:dart_cloud_backend/services/docker/docker_service.dart';
import 'package:dart_cloud_backend/configuration/config.dart';
import 'package:database/database.dart';

class FunctionExecutor {
  final int functionId;
  final String functionUUId;
  static int _activeExecutions = 0;
  static final Map<String, Timer> _containerCleanupTimers = {};

  FunctionExecutor({
    required this.functionId,
    required this.functionUUId,
  });

  /// Execute function with HTTP request structure
  /// Input should contain 'body' and 'query' fields
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input) async {
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
        return _executeFunction(input);
      } finally {
        _activeExecutions--;
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Execution error: $e',
        'result': null,
      };
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
      final deployment = await DatabaseManagers.functionDeployments.findOne(
        where: {
          'function_id': functionId,
          'is_active': true,
        },
      );

      if (deployment == null) {
        return {
          'success': false,
          'error': 'No active deployment found for function',
          'result': null,
        };
      }

      final imageTag = deployment.imageTag;
      final version = deployment.version;
      // Check if image exists before running
      final imageExists = await DockerService.isContainerImageExist(
        imageTag,
      );
      if (!imageExists) {
        return {
          'success': false,
          'error':
              'Function image does not exist. Please rollback to another previous version or redeploy the function.',
          'result': null,
        };
      }
      // Run the function in a Docker container
      final timeoutMs = Config.functionTimeoutSeconds * 1000;

      final executionResult = await DockerService.runContainerStatic(
        imageTag: imageTag,
        input: httpRequest,
        timeoutMs: timeoutMs,
        functionUUID: functionUUId,
        version: version,
      );

      // Schedule container cleanup after 10ms
      _scheduleContainerCleanup(functionUUId, imageTag);

      return executionResult;
    } catch (e, trace) {
      FunctionUtils.logDeploymentFunction(
        functionUUId,
        'error',
        'Function execution failed: $e,trace:$trace',
      );
      return {
        'success': false,
        'error': 'Function Execution Failed',
        'result': null,
      };
    }
  }

  /// Schedule container cleanup after 10ms
  static void _scheduleContainerCleanup(String functionUUId, String imageTag) {
    // Cancel existing timer if any
    _containerCleanupTimers[functionUUId]?.cancel();

    // Schedule new cleanup timer for 10ms
    _containerCleanupTimers[functionUUId] = Timer(
      const Duration(milliseconds: 10),
      () {
        // Cleanup is handled by Docker's --rm flag
        // This timer just ensures we track cleanup timing
        _containerCleanupTimers.remove(functionUUId);
      },
    );
  }

  /// Get current active executions count
  static int get activeExecutions => _activeExecutions;
}
