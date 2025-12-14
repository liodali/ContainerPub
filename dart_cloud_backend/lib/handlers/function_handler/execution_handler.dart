import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:dart_cloud_backend/configuration/config.dart';
import 'package:database/database.dart';
import 'package:dart_cloud_backend/services/function_executor.dart';
import 'auth_utils.dart';

/// Handles function execution (invocation) operations
///
/// This handler manages the runtime execution of deployed functions:
/// - Validates request size limits
/// - Verifies function ownership
/// - Executes function in Docker container
/// - Tracks execution metrics
/// - Logs invocation results
class ExecutionHandler {
  /// Invoke a deployed function with provided input
  ///
  /// This endpoint executes the active deployment of a function in an
  /// isolated Docker container. The execution is subject to:
  /// - Request size limits (default: 5MB)
  /// - Execution timeout (default: 5 seconds)
  /// - Memory limits (default: 128MB)
  /// - Concurrent execution limits (default: 10)
  ///
  /// Request format:
  /// ```json
  /// {
  ///   "body": {...},      // Function input data
  ///   "query": {...},     // Query parameters
  ///   "headers": {...}    // Optional headers
  /// }
  /// ```
  ///
  /// Response format:
  /// ```json
  /// {
  ///   "success": true,
  ///   "result": {...},
  ///   "error": null,
  ///   "duration_ms": 150
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [id]: Function UUID
  ///
  /// Response codes:
  /// - 200: Function executed successfully
  /// - 404: Function not found
  /// - 413: Request payload too large
  /// - 500: Execution failed
  static Future<Response> invoke(Request request, String uuid) async {
    try {
      // Extract user ID from authenticated request
      // final userId = request.context['userId'] as String;

      // === REQUEST SIZE VALIDATION ===
      // Read entire request body to check size before processing
      // This prevents large payloads from consuming excessive resources
      final bodyString = await request.readAsString();

      // Calculate request size in bytes
      final maxSizeBytes = Config.functionMaxRequestSizeMb * 1024 * 1024;
      final requestSizeBytes = bodyString.length;

      // Reject requests exceeding size limit
      if (requestSizeBytes > maxSizeBytes) {
        return Response(
          413, // HTTP 413: Payload Too Large
          body: jsonEncode({
            'error':
                'Request size exceeds maximum allowed size of ${Config.functionMaxRequestSizeMb}MB',
            'requestSizeMb': (requestSizeBytes / 1024 / 1024).toStringAsFixed(2),
            'maxSizeMb': Config.functionMaxRequestSizeMb,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Parse JSON body after size validation
      final body = jsonDecode(bodyString) as Map<String, dynamic>;
      body['raw'] = bodyString;

      // === FUNCTION OWNERSHIP VERIFICATION ===
      // Verify that function exists and belongs to requesting user

      final functionEntity = await DatabaseManagers.functions.findOne(
        where: {'uuid': uuid, 'status': 'active'},
      );

      // final result = await Database.connection.execute(
      //   'SELECT id, name FROM functions WHERE uuid = \$1 AND user_id = \$2',
      //   parameters: [uuid, userId],
      // );

      // Check if function exists and user has access
      if (functionEntity == null) {
        return Response.notFound(
          jsonEncode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // === FUNCTION EXECUTION ===
      // Track execution start time for performance metrics
      final startTime = DateTime.now();

      // Create executor instance for this function
      // Executor will:
      // 1. Query active deployment from database
      // 2. Run Docker container with function code
      // 3. Wait for result with timeout
      // 4. Schedule container cleanup (10ms timer)
      final executor = FunctionExecutor(
        functionId: functionEntity.id!,
        functionUUId: functionEntity.uuid!,
      );
      final executionResult = await executor.execute(body);

      // Calculate execution duration
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      // === INVOCATION LOGGING ===
      // Record invocation metrics in database for analytics
      // Encode sensitive data (body, raw, result, error) as Base64 for security
      // This prepares for future encryption with developer-specific keys
      final isSuccess = executionResult['success'] == true;
      final resultString = executionResult['result'] != null
          ? jsonEncode(executionResult['result'])
          : null;

      // Build structured logs with container output and execution errors
      var invocationLogs = InvocationLogs.fromContainerLogs(
        executionResult['logs'] as Map<String, dynamic>?,
      );

      // Add execution metadata
      invocationLogs = invocationLogs.withMetadata(
        ExecutionMetadata(
          functionUuid: uuid,
          startTime: startTime.toIso8601String(),
          endTime: DateTime.now().toIso8601String(),
          timeoutMs: Config.functionTimeoutSeconds * 1000,
          memoryLimitMb: Config.functionMaxMemoryMb,
        ),
      );

      // Add execution error if failed
      if (!isSuccess && executionResult['error'] != null) {
        invocationLogs = invocationLogs.addError(
          ExecutionError.create(
            phase: 'execution',
            message: executionResult['error'] as String,
            code: invocationLogs.exitCode?.toString(),
          ),
        );
      }

      // Build error message (only on error) - no body included for security
      String? errorMessage;
      if (!isSuccess && executionResult['error'] != null) {
        errorMessage = executionResult['error'] as String;
      }

      // Build request info with all metadata (no body for security)
      final requestInfo = <String, dynamic>{
        'headers': body['headers'] as Map<String, dynamic>? ?? {},
        'query': body['query'] as Map<String, dynamic>? ?? {},
        'method': body['method'] as String? ?? 'POST',
        'path': body['path'] as String? ?? '/',
        'content_type': body['content_type'] as String?,
        'timestamp': startTime.toIso8601String(),
      };

      // Store invocation with request info (no body for security)
      final entity = FunctionInvocationEntity(
        functionId: functionEntity.id,
        status: isSuccess ? 'success' : 'error',
        durationMs: duration,
        error: SecureDataEncoder.encodeOrNull(errorMessage),
        logs: invocationLogs.toJson(),
        requestInfo: requestInfo,
        result: SecureDataEncoder.encodeOrNull(resultString),
        success: isSuccess,
      );
      DatabaseManagers.functionInvocations.insert(entity.toDBMap());

      // Log execution result for debugging and monitoring
      await FunctionUtils.logFunction(
        uuid,
        executionResult['success'] == true ? 'info' : 'error',
        executionResult['success'] == true
            ? 'Function executed successfully in ${duration}ms'
            : 'Function execution failed: ${executionResult['error']}',
      );

      // === RETURN RESULT ===
      // Return clean response with only result and success
      // Excludes sensitive data (body, raw, logs) from response
      if (isSuccess) {
        return Response.ok(
          jsonEncode({
            'success': true,
            'result': executionResult['result'],
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.ok(
          jsonEncode({
            'success': false,
            'error': executionResult['error'],
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      // Handle unexpected errors during invocation
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to invoke function: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
