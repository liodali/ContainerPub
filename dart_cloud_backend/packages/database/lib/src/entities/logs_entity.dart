import 'package:collection/collection.dart';
import 'package:database/database.dart';

enum LogsActionEnum { deploy, build, run, rollback, delete, update, unknown }

class LogsEntity extends Entity {
  final int? id;
  final String uuid;
  final String level;
  final Map<String, dynamic> message;
  final LogsActionEnum action;

  LogsEntity({
    this.id,
    required this.uuid,
    required this.level,
    required this.message,
    required this.action,
  });

  @override
  String get tableName => 'logs';

  @override
  Map<String, dynamic> toDBMap() {
    return {
      if (id != null) 'id': id,
      'uuid': uuid,
      'action': action.name,
      'level': level,
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uuid': uuid,
      'level': level,
      'action': action.name,
      'message': message,
    };
  }

  static LogsEntity fromMap(Map<String, dynamic> map) {
    return LogsEntity(
      id: map['id'] as int?,
      uuid: map['uuid'].toString(),
      level: map['level'].toString(),
      message: map['message'] is Map<String, dynamic>
          ? map['message'] as Map<String, dynamic>
          : {'raw': map['message'].toString()},
      action:
          LogsActionEnum.values.firstWhereOrNull(
            (e) => e.name == map['action'].toString(),
          ) ??
          LogsActionEnum.unknown,
    );
  }
}
