import 'package:database/database.dart';

/// Mixin for organization-related relationship queries
/// Organizations can have multiple users (members)
mixin OrganizationRelationships on RelationshipManager {
  /// Get organization with its members
  Future<OrganizationWithMembers?> getOrganizationWithMembers({
    required String organizationId,
  }) async {
    // Get organization
    final org = await DatabaseManagers.organizations.findByUuid(organizationId);
    if (org == null) return null;

    // Get members with user information
    final memberResults = await executeJoinQuery(
      baseTable: 'organization_members',
      joins: [
        JoinConfig(
          table: 'users',
          on: 'organization_members.user_id = users.uuid',
          type: JoinType.inner,
        ),
        JoinConfig(
          table: 'user_information',
          on: 'users.uuid = user_information.user_id',
          type: JoinType.left,
        ),
      ],
      where: {'organization_members.organization_id': organizationId},
      orderBy: 'organization_members.joined_at',
      orderDirection: 'DESC',
    );

    final members = memberResults.map((m) {
      return OrganizationMemberWithInfo(
        user: UserEntity.fromMap(m),
        information: m['first_name'] != null
            ? UserInformation.fromMap(m)
            : null,
        joinedAt: m['joined_at'] != null
            ? DateTime.parse(m['joined_at'].toString())
            : null,
      );
    }).toList();

    return OrganizationWithMembers(
      organization: org,
      members: members,
    );
  }

  /// Add user to organization
  Future<bool> addUserToOrganization({
    required String organizationId,
    required String userId,
  }) async {
    try {
      await DatabaseManagers.organizationMembers.insert({
        'organization_id': organizationId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove user from organization
  Future<bool> removeUserFromOrganization({
    required String userId,
  }) async {
    final count = await DatabaseManagers.organizationMembers.delete(
      where: {'user_id': userId},
    );
    return count > 0;
  }

  /// Get organization for a user
  Future<Organization?> getUserOrganization({
    required String userId,
  }) async {
    final results = await executeJoinQuery(
      baseTable: 'organization_members',
      joins: [
        JoinConfig(
          table: 'organizations',
          on: 'organization_members.organization_id = organizations.uuid',
          type: JoinType.inner,
        ),
      ],
      where: {'organization_members.user_id': userId},
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Organization.fromMap(results.first);
  }

  /// Check if user is member of organization
  Future<bool> isUserInOrganization({
    required String userId,
  }) async {
    final exists = await DatabaseManagers.organizationMembers.exists(
      where: {'user_id': userId},
    );
    return exists;
  }

  /// Get organization member count
  Future<int> getOrganizationMemberCount({
    required String organizationId,
  }) async {
    return await DatabaseManagers.organizationMembers.count(
      where: {'organization_id': organizationId},
    );
  }
}

/// Organization with its members
class OrganizationWithMembers {
  final Organization organization;
  final List<OrganizationMemberWithInfo> members;

  OrganizationWithMembers({
    required this.organization,
    required this.members,
  });

  Map<String, dynamic> toJson() {
    return {
      'organization': organization.toMap(),
      'members': members.map((m) => m.toJson()).toList(),
      'member_count': members.length,
    };
  }
}

/// Organization member with user information
class OrganizationMemberWithInfo {
  final UserEntity user;
  final UserInformation? information;
  final DateTime? joinedAt;

  OrganizationMemberWithInfo({
    required this.user,
    this.information,
    this.joinedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'user': user.toMap(),
      if (information != null) 'information': information!.toMap(),
      if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    };
  }
}
