import 'dart:convert';

/// Log entry with timestamp and optional metadata
class FunctionLogEntry {
  final String message;
  final String timestamp;
  final Map<String, dynamic>? metadata;

  const FunctionLogEntry({
    required this.message,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'message': message,
    'timestamp': timestamp,
    if (metadata != null && metadata!.isNotEmpty) 'metadata': metadata,
  };

  factory FunctionLogEntry.fromJson(Map<String, dynamic> json) =>
      FunctionLogEntry(
        message: json['message'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Structured function logs with error, debug, and info sections
///
/// This mirrors the output format of CloudLogger from dart_cloud_logger package
class FunctionLogs {
  final List<FunctionLogEntry> errors;
  final List<FunctionLogEntry> debug;
  final List<FunctionLogEntry> info;

  const FunctionLogs({
    this.errors = const [],
    this.debug = const [],
    this.info = const [],
  });

  Map<String, dynamic> toJson() => {
    'error': errors.map((e) => e.toJson()).toList(),
    'debug': debug.map((e) => e.toJson()).toList(),
    'info': info.map((e) => e.toJson()).toList(),
  };

  factory FunctionLogs.fromJson(Map<String, dynamic> json) => FunctionLogs(
    errors:
        (json['error'] as List<dynamic>?)
            ?.map((e) => FunctionLogEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    debug:
        (json['debug'] as List<dynamic>?)
            ?.map((e) => FunctionLogEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    info:
        (json['info'] as List<dynamic>?)
            ?.map((e) => FunctionLogEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );

  bool get isEmpty => errors.isEmpty && debug.isEmpty && info.isEmpty;
  bool get isNotEmpty => !isEmpty;
  int get totalCount => errors.length + debug.length + info.length;
  bool get hasErrors => errors.isNotEmpty;
}

/// Structured logs model for function invocations
///
/// Captures container execution logs and errors in a structured format:
/// - [containerLogs]: Raw output from the container (stdout, stderr, exit_code)
/// - [executionErrors]: Errors that occurred during execution pipeline
/// - [metadata]: Additional execution metadata (timing, memory, etc.)
/// - [functionLogs]: Structured logs from CloudLogger (error, debug, info sections)
class InvocationLogs {
  /// Container stdout output (from executed function)
  final String? stdout;

  /// Container stderr output (errors from function)
  final String? stderr;

  /// Container exit code (-1 for timeout)
  final int? exitCode;

  /// Timestamp when container finished execution
  final String? containerTimestamp;

  /// List of execution errors that occurred during the pipeline
  /// (e.g., deployment lookup errors, container start errors)
  final List<ExecutionError> executionErrors;

  /// Execution metadata
  final ExecutionMetadata? metadata;

  /// Structured function logs from CloudLogger
  /// Contains error, debug, and info sections with timestamps
  final FunctionLogs? functionLogs;

  const InvocationLogs({
    this.stdout,
    this.stderr,
    this.exitCode,
    this.containerTimestamp,
    this.executionErrors = const [],
    this.metadata,
    this.functionLogs,
  });

  /// Create from container execution result logs
  factory InvocationLogs.fromContainerLogs(
    Map<String, dynamic>? containerLogs,
  ) {
    if (containerLogs == null) {
      return const InvocationLogs();
    }

    // Parse function logs from container logs if present
    FunctionLogs? funcLogs;
    final functionLogsJson =
        containerLogs['function_logs'] as Map<String, dynamic>?;
    if (functionLogsJson != null) {
      funcLogs = FunctionLogs.fromJson(functionLogsJson);
    }

    return InvocationLogs(
      stdout: containerLogs['logs'] as String?,
      stderr: containerLogs['stderr'] as String?,
      exitCode: containerLogs['exit_code'] as int?,
      containerTimestamp: containerLogs['timestamp'] as String?,
      functionLogs: funcLogs,
    );
  }

  /// Add an execution error to the logs
  InvocationLogs addError(ExecutionError error) {
    return InvocationLogs(
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
      containerTimestamp: containerTimestamp,
      executionErrors: [...executionErrors, error],
      metadata: metadata,
      functionLogs: functionLogs,
    );
  }

  /// Add multiple execution errors
  InvocationLogs addErrors(List<ExecutionError> errors) {
    return InvocationLogs(
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
      containerTimestamp: containerTimestamp,
      executionErrors: [...executionErrors, ...errors],
      metadata: metadata,
      functionLogs: functionLogs,
    );
  }

  /// Set execution metadata
  InvocationLogs withMetadata(ExecutionMetadata meta) {
    return InvocationLogs(
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
      containerTimestamp: containerTimestamp,
      executionErrors: executionErrors,
      metadata: meta,
      functionLogs: functionLogs,
    );
  }

  /// Convert to JSON map for database storage
  Map<String, dynamic> toJson() {
    return {
      'container': {
        if (stdout != null) 'stdout': stdout,
        if (stderr != null) 'stderr': stderr,
        if (exitCode != null) 'exit_code': exitCode,
        if (containerTimestamp != null) 'timestamp': containerTimestamp,
      },
      if (executionErrors.isNotEmpty)
        'errors': executionErrors.map((e) => e.toJson()).toList(),
      if (metadata != null) 'metadata': metadata!.toJson(),
      if (functionLogs != null) 'function_logs': functionLogs!.toJson(),
    };
  }

  /// Create from JSON map (from database)
  factory InvocationLogs.fromJson(Map<String, dynamic> json) {
    final container = json['container'] as Map<String, dynamic>? ?? {};
    final errorsJson = json['errors'] as List<dynamic>? ?? [];
    final metadataJson = json['metadata'] as Map<String, dynamic>?;
    final functionLogsJson = json['function_logs'] as Map<String, dynamic>?;

    return InvocationLogs(
      stdout: container['stdout'] as String?,
      stderr: container['stderr'] as String?,
      exitCode: container['exit_code'] as int?,
      containerTimestamp: container['timestamp'] as String?,
      executionErrors: errorsJson
          .map((e) => ExecutionError.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: metadataJson != null
          ? ExecutionMetadata.fromJson(metadataJson)
          : null,
      functionLogs: functionLogsJson != null
          ? FunctionLogs.fromJson(functionLogsJson)
          : null,
    );
  }

  /// Check if there are any errors (container or execution or function logs)
  bool get hasErrors =>
      (stderr != null && stderr!.isNotEmpty) ||
      executionErrors.isNotEmpty ||
      (functionLogs?.hasErrors ?? false);

  /// Check if container timed out
  bool get isTimeout => exitCode == -1;

  /// Get all error messages combined
  List<String> get allErrorMessages {
    final messages = <String>[];
    if (stderr != null && stderr!.isNotEmpty) {
      messages.add('Container stderr: $stderr');
    }
    for (final error in executionErrors) {
      messages.add('${error.phase}: ${error.message}');
    }
    // Include function log errors
    if (functionLogs != null) {
      for (final error in functionLogs!.errors) {
        messages.add('Function error: ${error.message}');
      }
    }
    return messages;
  }

  @override
  String toString() => jsonEncode(toJson());
}

/// Represents an error that occurred during execution
class ExecutionError {
  /// Phase where the error occurred (e.g., 'deployment_lookup', 'container_start', 'execution')
  final String phase;

  /// Error message
  final String message;

  /// Error code (if applicable)
  final String? code;

  /// Timestamp when error occurred
  final String timestamp;

  /// Stack trace (if available)
  final String? stackTrace;

  const ExecutionError({
    required this.phase,
    required this.message,
    this.code,
    required this.timestamp,
    this.stackTrace,
  });

  /// Create an error for a specific phase
  factory ExecutionError.create({
    required String phase,
    required String message,
    String? code,
    String? stackTrace,
  }) {
    return ExecutionError(
      phase: phase,
      message: message,
      code: code,
      timestamp: DateTime.now().toIso8601String(),
      stackTrace: stackTrace,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase': phase,
      'message': message,
      if (code != null) 'code': code,
      'timestamp': timestamp,
      if (stackTrace != null) 'stack_trace': stackTrace,
    };
  }

  factory ExecutionError.fromJson(Map<String, dynamic> json) {
    return ExecutionError(
      phase: json['phase'] as String,
      message: json['message'] as String,
      code: json['code'] as String?,
      timestamp: json['timestamp'] as String,
      stackTrace: json['stack_trace'] as String?,
    );
  }
}

/// Execution metadata
class ExecutionMetadata {
  /// Function UUID
  final String? functionUuid;

  /// Deployment image tag used
  final String? imageTag;

  /// Execution start time
  final String? startTime;

  /// Execution end time
  final String? endTime;

  /// Memory limit used (MB)
  final int? memoryLimitMb;

  /// Timeout used (ms)
  final int? timeoutMs;

  const ExecutionMetadata({
    this.functionUuid,
    this.imageTag,
    this.startTime,
    this.endTime,
    this.memoryLimitMb,
    this.timeoutMs,
  });

  Map<String, dynamic> toJson() {
    return {
      if (functionUuid != null) 'function_uuid': functionUuid,
      if (imageTag != null) 'image_tag': imageTag,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (memoryLimitMb != null) 'memory_limit_mb': memoryLimitMb,
      if (timeoutMs != null) 'timeout_ms': timeoutMs,
    };
  }

  factory ExecutionMetadata.fromJson(Map<String, dynamic> json) {
    return ExecutionMetadata(
      functionUuid: json['function_uuid'] as String?,
      imageTag: json['image_tag'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      memoryLimitMb: json['memory_limit_mb'] as int?,
      timeoutMs: json['timeout_ms'] as int?,
    );
  }
}
