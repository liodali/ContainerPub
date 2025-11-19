import 'package:database/database.dart';

/// Mixin for organization-related relationship queries
mixin OrganizationRelationships on RelationshipManager {
  /// Get organization with its teams
  Future<OrganizationWithTeams?> getOrganizationWithTeams({
    required String organizationId,
  }) async {
    // Get organization
    final org = await DatabaseManagers.organizations.findByUuid(organizationId);
    if (org == null) return null;

    // Get teams
    final teamResults = await executeJoinQuery(
      baseTable: 'organization_teams',
      joins: [],
      where: {'organization_teams.organization_id': organizationId},
      orderBy: 'organization_teams.created_at',
      orderDirection: 'DESC',
    );

    final teams = teamResults.map((t) => OrganizationTeam.fromMap(t)).toList();

    return OrganizationWithTeams(
      organization: org,
      teams: teams,
    );
  }

  /// Get team with its members (users)
  Future<TeamWithMembers?> getTeamWithMembers({
    required String teamId,
  }) async {
    // Get team
    final teamResults = await executeJoinQuery(
      baseTable: 'organization_teams',
      joins: [],
      where: {'organization_teams.uuid': teamId},
      limit: 1,
    );

    if (teamResults.isEmpty) return null;
    final team = OrganizationTeam.fromMap(teamResults.first);

    // Get team members with user information
    final memberResults = await executeJoinQuery(
      baseTable: 'organization_team_members',
      joins: [
        JoinConfig(
          table: 'users',
          on: 'organization_team_members.user_id = users.uuid',
          type: JoinType.inner,
        ),
        JoinConfig(
          table: 'user_information',
          on: 'users.uuid = user_information.user_id',
          type: JoinType.left,
        ),
      ],
      where: {'organization_team_members.team_id': teamId},
      orderBy: 'organization_team_members.joined_at',
      orderDirection: 'DESC',
    );

    final members = memberResults.map((m) {
      return TeamMemberWithInfo(
        user: UserEntity.fromMap(m),
        information: m['first_name'] != null
            ? UserInformation.fromMap(m)
            : null,
        joinedAt: m['joined_at'] != null
            ? DateTime.parse(m['joined_at'].toString())
            : null,
      );
    }).toList();

    return TeamWithMembers(
      team: team,
      members: members,
    );
  }

  /// Get organization with all teams and their members
  Future<OrganizationComplete?> getOrganizationComplete({
    required String organizationId,
  }) async {
    // Get organization
    final org = await DatabaseManagers.organizations.findByUuid(organizationId);
    if (org == null) return null;

    // Get teams with members
    final teamResults = await executeJoinQuery(
      baseTable: 'organization_teams',
      joins: [],
      where: {'organization_teams.organization_id': organizationId},
      orderBy: 'organization_teams.created_at',
      orderDirection: 'DESC',
    );

    final teamsWithMembers = <TeamWithMembers>[];

    for (final teamData in teamResults) {
      final team = OrganizationTeam.fromMap(teamData);
      final teamWithMembers = await getTeamWithMembers(teamId: team.uuid!);
      if (teamWithMembers != null) {
        teamsWithMembers.add(teamWithMembers);
      }
    }

    return OrganizationComplete(
      organization: org,
      teams: teamsWithMembers,
    );
  }

  /// Add user to team
  Future<bool> addUserToTeam({
    required String teamId,
    required String userId,
  }) async {
    try {
      await DatabaseManagers.organizationTeamMembers.insert({
        'team_id': teamId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove user from team
  Future<bool> removeUserFromTeam({
    required String teamId,
    required String userId,
  }) async {
    final count = await DatabaseManagers.organizationTeamMembers.delete(
      where: {
        'team_id': teamId,
        'user_id': userId,
      },
    );
    return count > 0;
  }

  /// Get all teams for a user
  Future<List<OrganizationTeam>> getUserTeams({
    required String userId,
  }) async {
    final results = await executeJoinQuery(
      baseTable: 'organization_team_members',
      joins: [
        JoinConfig(
          table: 'organization_teams',
          on: 'organization_team_members.team_id = organization_teams.uuid',
          type: JoinType.inner,
        ),
      ],
      where: {'organization_team_members.user_id': userId},
      orderBy: 'organization_team_members.joined_at',
      orderDirection: 'DESC',
    );

    return results.map((r) => OrganizationTeam.fromMap(r)).toList();
  }

  /// Check if user is member of team
  Future<bool> isUserInTeam({
    required String teamId,
    required String userId,
  }) async {
    final exists = await DatabaseManagers.organizationTeamMembers.exists(
      where: {
        'team_id': teamId,
        'user_id': userId,
      },
    );
    return exists;
  }

  /// Get team member count
  Future<int> getTeamMemberCount({
    required String teamId,
  }) async {
    return await DatabaseManagers.organizationTeamMembers.count(
      where: {'team_id': teamId},
    );
  }
}

/// Organization with its teams
class OrganizationWithTeams {
  final Organization organization;
  final List<OrganizationTeam> teams;

  OrganizationWithTeams({
    required this.organization,
    required this.teams,
  });

  Map<String, dynamic> toJson() {
    return {
      'organization': organization.toMap(),
      'teams': teams.map((t) => t.toMap()).toList(),
      'team_count': teams.length,
    };
  }
}

/// Team with its members
class TeamWithMembers {
  final OrganizationTeam team;
  final List<TeamMemberWithInfo> members;

  TeamWithMembers({
    required this.team,
    required this.members,
  });

  Map<String, dynamic> toJson() {
    return {
      'team': team.toMap(),
      'members': members.map((m) => m.toJson()).toList(),
      'member_count': members.length,
    };
  }
}

/// Team member with user information
class TeamMemberWithInfo {
  final UserEntity user;
  final UserInformation? information;
  final DateTime? joinedAt;

  TeamMemberWithInfo({
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

/// Complete organization with teams and members
class OrganizationComplete {
  final Organization organization;
  final List<TeamWithMembers> teams;

  OrganizationComplete({
    required this.organization,
    required this.teams,
  });

  int get totalMembers {
    return teams.fold(0, (sum, team) => sum + team.members.length);
  }

  Map<String, dynamic> toJson() {
    return {
      'organization': organization.toMap(),
      'teams': teams.map((t) => t.toJson()).toList(),
      'team_count': teams.length,
      'total_members': totalMembers,
    };
  }
}
