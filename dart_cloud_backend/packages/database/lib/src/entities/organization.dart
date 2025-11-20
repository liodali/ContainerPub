import 'package:database/src/entity.dart';

class Organization extends Entity {
  final int? id;
  final String? uuid;
  final String name;
  final String ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Organization({
    this.id,
    this.uuid,
    required this.name,
    required this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  Organization.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      uuid = map['uuid'],
      name = map['name'],
      ownerId = map['owner_id'],
      createdAt = map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt = map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null;

  @override
  String get tableName => 'organizations';

  @override
  Map<String, dynamic> toMap() {
    return {
      if (uuid != null) 'uuid': uuid,
      'name': name,
      'owner_id': ownerId,
    };
  }

  @override
  Map<String, dynamic> toDBMap() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'owner_id': ownerId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }


  Organization copyWith({
    int? id,
    String? uuid,
    String? name,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Organization(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
