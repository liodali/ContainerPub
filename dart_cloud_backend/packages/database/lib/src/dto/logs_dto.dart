import 'package:database/database.dart';

/// DTO for logs returned to frontend
class LogsDto {
  final String uuid;
  final String level;
  final Map<String, dynamic> message;
  final String action;

  LogsDto({
    required this.uuid,
    required this.level,
    required this.message,
    required this.action,
  });

  factory LogsDto.fromEntity(LogsEntity entity) {
    return LogsDto(
      uuid: entity.uuid,
      level: entity.level,
      message: entity.message,
      action: entity.action.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'level': level,
      'message': message,
      'action': action,
    };
  }
}
