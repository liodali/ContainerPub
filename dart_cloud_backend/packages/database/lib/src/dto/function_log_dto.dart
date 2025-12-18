import 'package:database/database.dart';

/// DTO for function log returned to frontend
class FunctionLogDto {
  final String uuid;
  final String level;
  final String message;
  final DateTime? timestamp;

  FunctionLogDto({
    required this.uuid,
    required this.level,
    required this.message,
    this.timestamp,
  });

  factory FunctionLogDto.fromEntity(FunctionLogEntity entity) {
    return FunctionLogDto(
      uuid: entity.uuid!,
      level: entity.level,
      message: entity.message,
      timestamp: entity.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'level': level,
      'message': message,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }
}
