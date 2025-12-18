import '../entities/organization_member.dart';

/// DTO for organization member returned to frontend
class OrganizationMemberSimpleDto {
  final String organizationId;
  final String userId;
  final DateTime? joinedAt;

  OrganizationMemberSimpleDto({
    required this.organizationId,
    required this.userId,
    this.joinedAt,
  });

  factory OrganizationMemberSimpleDto.fromEntity(OrganizationMember entity) {
    return OrganizationMemberSimpleDto(
      organizationId: entity.organizationId,
      userId: entity.userId,
      joinedAt: entity.joinedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'user_id': userId,
      if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    };
  }
}
