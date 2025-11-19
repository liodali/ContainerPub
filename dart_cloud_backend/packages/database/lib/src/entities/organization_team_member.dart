import 'package:database/src/entity.dart';

/// Organization team member entity - junction table for team membership
class OrganizationTeamMember extends Entity {
  final int? id;
  final String teamId;
  final String userId;
  final DateTime? joinedAt;

  OrganizationTeamMember({
    this.id,
    required this.teamId,
    required this.userId,
    this.joinedAt,
  });

  OrganizationTeamMember.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      teamId = map['team_id'],
      userId = map['user_id'],
      joinedAt = map['joined_at'] != null
          ? DateTime.parse(map['joined_at'].toString())
          : null;

  @override
  String get tableName => 'organization_team_members';

  @override
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'team_id': teamId,
      'user_id': userId,
      if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    };
  }
}
