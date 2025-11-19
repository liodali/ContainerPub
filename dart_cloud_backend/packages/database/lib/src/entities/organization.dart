import 'package:database/src/entity.dart';

class Organization extends Entity {
  final int? id;
  final String? uuid;
  final String name;
  final String userId;

  Organization({
    this.id,
    this.uuid,
    required this.name,
    required this.userId,
  });

  Organization.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      uuid = map['uuid'],
      name = map['name'],
      userId = map['user_id'];

  @override
  String get tableName => 'user_organizations';

  @override
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      'name': name,
      'user_id': userId,
    };
  }
}
