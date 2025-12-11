import '../entity.dart';

/// Function invocation entity representing the function_invocations table
class FunctionInvocationEntity extends Entity {
  final int? id;
  final String? uuid;
  final int? functionId;
  final String status;
  final int? durationMs;
  final String? error;
  final Map<String, dynamic>? logs;
  final DateTime? timestamp;

  FunctionInvocationEntity({
    this.id,
    this.uuid,
    this.functionId,
    required this.status,
    this.durationMs,
    this.error,
    this.logs,
    this.timestamp,
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
      if (logs != null) 'logs': logs,
      if (timestamp != null) 'timestamp': timestamp,
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
    );
  }
}
