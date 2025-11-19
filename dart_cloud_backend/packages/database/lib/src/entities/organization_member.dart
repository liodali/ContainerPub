import 'package:database/src/entity.dart';

/// Organization member entity - represents a user belonging to an organization
class OrganizationMember extends Entity {
  final int? id;
  final String organizationId;
  final String userId;
  final DateTime? joinedAt;

  OrganizationMember({
    this.id,
    required this.organizationId,
    required this.userId,
    this.joinedAt,
  });

  OrganizationMember.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      organizationId = map['organization_id'],
      userId = map['user_id'],
      joinedAt = map['joined_at'] != null
          ? DateTime.parse(map['joined_at'].toString())
          : null;

  @override
  String get tableName => 'organization_members';

  @override
  Map<String, dynamic> toMap() {
    return {
      'organization_id': organizationId,
      'user_id': userId,
      if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    };
  }

  OrganizationMember copyWith({
    int? id,
    String? organizationId,
    String? userId,
    DateTime? joinedAt,
  }) {
    return OrganizationMember(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
