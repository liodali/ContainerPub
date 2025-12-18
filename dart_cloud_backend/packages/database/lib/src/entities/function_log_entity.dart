import '../entity.dart';

/// Function log entity representing the function_logs table
class FunctionLogEntity extends Entity {
  final int? id;
  final String? uuid;
  final int? functionId;
  final String level;
  final String message;
  final DateTime? timestamp;

  FunctionLogEntity({
    this.id,
    this.uuid,
    this.functionId,
    required this.level,
    required this.message,
    this.timestamp,
  });

  @override
  String get tableName => 'function_deploy_logs';

  @override
  Map<String, dynamic> toMap() {
    return {
      if (uuid != null) 'uuid': uuid,
      if (functionId != null) 'function_id': functionId,
      'level': level,
      'message': message,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }

  @override
  Map<String, dynamic> toDBMap() {
    return {
      'id': id,
      'uuid': uuid,
      'function_id': functionId,
      'level': level,
      'message': message,
      'timestamp': timestamp,
    };
  }

  static FunctionLogEntity fromMap(Map<String, dynamic> map) {
    return FunctionLogEntity(
      id: map['id'] as int?,
      uuid: map['uuid']?.toString(),
      functionId: map['function_id'] as int?,
      level: map['level'] as String,
      message: map['message'] as String,
      timestamp: map['timestamp'] as DateTime?,
    );
  }

  FunctionLogEntity copyWith({
    int? id,
    String? uuid,
    int? functionId,
    String? level,
    String? message,
    DateTime? timestamp,
  }) {
    return FunctionLogEntity(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      functionId: functionId ?? this.functionId,
      level: level ?? this.level,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
