import 'dart:convert';

import '../entity.dart';
import '../utils/secure_data_encoder.dart';
import '../models/invocation_logs.dart';

/// Function invocation entity representing the function_invocations table
///
/// Stores function execution data with request metadata (headers, query) and
/// execution logs. Body is NOT stored for security reasons.
///
/// Fields:
/// - [requestInfo]: Request metadata including headers, query, method, path (JSONB)
/// - [result]: Base64 encoded function execution result
/// - [success]: Boolean indicating if execution was successful
/// - [error]: Base64 encoded error message
/// - [logs]: Container logs and execution errors (JSONB)
class FunctionInvocationEntity extends Entity {
  final int? id;
  final String? uuid;
  final int? functionId;
  final String status;
  final int? durationMs;
  final String? error;
  final Map<String, dynamic>? logs;
  final DateTime? timestamp;

  /// Request metadata including headers, query, method, path (stored as JSONB)
  final Map<String, dynamic>? requestInfo;

  /// Base64 encoded function result - protected for future encryption
  final String? result;

  /// Indicates if the function execution was successful
  final bool? success;

  FunctionInvocationEntity({
    this.id,
    this.uuid,
    this.functionId,
    required this.status,
    this.durationMs,
    this.error,
    this.logs,
    this.timestamp,
    this.requestInfo,
    this.result,
    this.success,
  });

  @override
  String get tableName => 'function_invocations';

  @override
  Map<String, dynamic> toMap() {
    return {
      if (uuid != null) 'uuid': uuid,
      if (functionId != null) 'function_id': functionId,
      'status': status,
      if (durationMs != null) 'duration_ms': durationMs,
      if (error != null) 'error': error,
      if (logs != null) 'logs': logs,
      if (timestamp != null) 'timestamp': timestamp,
      if (requestInfo != null) 'request_info': requestInfo,
      if (result != null) 'result': result,
      if (success != null) 'success': success,
    };
  }

  @override
  Map<String, dynamic> toDBMap() {
    return {
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (functionId != null) 'function_id': functionId,
      'status': status,
      if (durationMs != null) 'duration_ms': durationMs,
      if (error != null) 'error': error,
      if (logs != null) 'logs': json.encode(logs),
      if (timestamp != null) 'timestamp': timestamp,
      if (requestInfo != null) 'request_info': json.encode(requestInfo),
      if (result != null) 'result': result,
      if (success != null) 'success': success,
    };
  }

  static FunctionInvocationEntity fromMap(Map<String, dynamic> map) {
    return FunctionInvocationEntity(
      id: map['id'] as int?,
      uuid: map['uuid']?.toString(),
      functionId: map['function_id'] as int?,
      status: map['status'] as String,
      durationMs: map['duration_ms'] as int?,
      error: map['error'] as String?,
      logs: map['logs'] as Map<String, dynamic>?,
      timestamp: map['timestamp'] as DateTime?,
      requestInfo: map['request_info'] as Map<String, dynamic>?,
      result: map['result'] as String?,
      success: map['success'] as bool?,
    );
  }

  FunctionInvocationEntity copyWith({
    int? id,
    String? uuid,
    int? functionId,
    String? status,
    int? durationMs,
    String? error,
    Map<String, dynamic>? logs,
    DateTime? timestamp,
    Map<String, dynamic>? requestInfo,
    String? result,
    bool? success,
  }) {
    return FunctionInvocationEntity(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      functionId: functionId ?? this.functionId,
      status: status ?? this.status,
      durationMs: durationMs ?? this.durationMs,
      error: error ?? this.error,
      logs: logs ?? this.logs,
      timestamp: timestamp ?? this.timestamp,
      requestInfo: requestInfo ?? this.requestInfo,
      result: result ?? this.result,
      success: success ?? this.success,
    );
  }

  /// Decodes the result from Base64
  /// Returns null if result is null
  String? get decodedResult {
    return SecureDataEncoder.decodeOrNull(result);
  }

  /// Decodes the error from Base64
  /// Returns null if error is null
  String? get decodedError {
    return SecureDataEncoder.decodeOrNull(error);
  }

  /// Parses the logs field into a structured InvocationLogs object
  /// Returns null if logs is null
  InvocationLogs? get structuredLogs {
    if (logs == null) return null;
    return InvocationLogs.fromJson(logs!);
  }

  /// Gets container stdout from logs
  String? get containerStdout => structuredLogs?.stdout;

  /// Gets container stderr from logs
  String? get containerStderr => structuredLogs?.stderr;

  /// Gets container exit code from logs
  int? get containerExitCode => structuredLogs?.exitCode;

  /// Gets all execution errors from logs
  List<ExecutionError> get executionErrors =>
      structuredLogs?.executionErrors ?? [];

  /// Checks if there were any errors during execution
  bool get hasExecutionErrors => structuredLogs?.hasErrors ?? false;

  /// Checks if execution timed out
  bool get isTimeout => structuredLogs?.isTimeout ?? false;

  /// Gets structured function logs from CloudLogger
  /// Returns null if no function logs are present
  FunctionLogs? get functionLogs => structuredLogs?.functionLogs;

  /// Gets function error logs
  List<FunctionLogEntry> get functionErrors => functionLogs?.errors ?? [];

  /// Gets function debug logs
  List<FunctionLogEntry> get functionDebugLogs => functionLogs?.debug ?? [];

  /// Gets function info logs
  List<FunctionLogEntry> get functionInfoLogs => functionLogs?.info ?? [];

  /// Checks if there are any function error logs
  bool get hasFunctionErrors => functionLogs?.hasErrors ?? false;

  /// Gets total count of function logs (error + debug + info)
  int get functionLogCount => functionLogs?.totalCount ?? 0;

  /// Creates an invocation entity with encoded sensitive data
  ///
  /// Use this factory to ensure all sensitive data is properly encoded
  /// before storage.
  static FunctionInvocationEntity createWithEncodedData({
    int? id,
    String? uuid,
    int? functionId,
    required String status,
    int? durationMs,
    String? error,
    Map<String, dynamic>? logs,
    DateTime? timestamp,
    Map<String, dynamic>? requestInfo,
    String? resultData,
    bool? success,
  }) {
    return FunctionInvocationEntity(
      id: id,
      uuid: uuid,
      functionId: functionId,
      status: status,
      durationMs: durationMs,
      error: SecureDataEncoder.encodeOrNull(error),
      logs: logs,
      timestamp: timestamp,
      requestInfo: requestInfo,
      result: SecureDataEncoder.encodeOrNull(resultData),
      success: success,
    );
  }
}
extension ExtFunctionInvocations on FunctionInvocationEntity {
  static const String functionIdNameField = 'function_id';
  static const String uuidNameField = 'uuid';
  static const String statusNameField = 'status';
  static const String durationMsNameField = 'duration_ms';
  static const String errorNameField = 'error';
  static const String logsNameField = 'logs';
  static const String timestampNameField = 'timestamp';
  static const String requestInfoNameField = 'request_info';
  static const String resultNameField = 'result';
  static const String successNameField = 'success';
}