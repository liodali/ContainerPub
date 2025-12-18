import 'package:database/database.dart';

/// DTO for function invocation returned to frontend
class FunctionInvocationDto {
  final String uuid;
  final String status;
  final int? durationMs;
  final String? error;
  final Map<String, dynamic>? logs;
  final DateTime? timestamp;
  final Map<String, dynamic>? requestInfo;
  final String? result;
  final bool? success;

  FunctionInvocationDto({
    required this.uuid,
    required this.status,
    this.durationMs,
    this.error,
    this.logs,
    this.timestamp,
    this.requestInfo,
    this.result,
    this.success,
  });

  factory FunctionInvocationDto.fromEntity(FunctionInvocationEntity entity) {
    return FunctionInvocationDto(
      uuid: entity.uuid!,
      status: entity.status,
      durationMs: entity.durationMs,
      error: entity.error,
      logs: entity.logs,
      timestamp: entity.timestamp,
      requestInfo: entity.requestInfo,
      result: entity.result,
      success: entity.success,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'status': status,
      if (durationMs != null) 'duration_ms': durationMs,
      if (error != null) 'error': error,
      if (logs != null) 'logs': logs,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (requestInfo != null) 'request_info': requestInfo,
      if (result != null) 'result': result,
      if (success != null) 'success': success,
    };
  }
}
