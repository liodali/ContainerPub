import 'package:database/src/entity.dart';

/// Organization team entity - represents a team within an organization
class OrganizationTeam extends Entity {
  final int? id;
  final String? uuid;
  final String name;
  final String description;
  final String organizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrganizationTeam({
    this.id,
    this.uuid,
    required this.name,
    required this.description,
    required this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  OrganizationTeam.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      uuid = map['uuid'],
      name = map['name'],
      description = map['description'] ?? '',
      organizationId = map['organization_id'],
      createdAt = map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt = map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null;

  @override
  String get tableName => 'organization_teams';

  @override
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      'name': name,
      'description': description,
      'organization_id': organizationId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  OrganizationTeam copyWith({
    int? id,
    String? uuid,
    String? name,
    String? description,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizationTeam(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      description: description ?? this.description,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
