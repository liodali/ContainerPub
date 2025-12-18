import '../entities/organization_team_member.dart';

/// DTO for organization team member returned to frontend
class OrganizationTeamMemberDto {
  final String teamId;
  final String userId;
  final DateTime? joinedAt;

  OrganizationTeamMemberDto({
    required this.teamId,
    required this.userId,
    this.joinedAt,
  });

  factory OrganizationTeamMemberDto.fromEntity(OrganizationTeamMember entity) {
    return OrganizationTeamMemberDto(
      teamId: entity.teamId,
      userId: entity.userId,
      joinedAt: entity.joinedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'user_id': userId,
      if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    };
  }
}
