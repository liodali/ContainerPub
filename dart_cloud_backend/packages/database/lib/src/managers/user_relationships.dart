import 'package:database/database.dart';

/// Mixin for user-related relationship queries
mixin UserRelationships on RelationshipManager {
  /// Get user with their information and organization
  Future<UserWithInformationAndOrganization?> getUserComplete({
    required String userId,
  }) async {
    final results = await executeJoinQuery(
      baseTable: 'users',
      joins: [
        JoinConfig(
          table: 'user_information',
          on: 'users.uuid = user_information.user_id',
          type: JoinType.left,
        ),
        JoinConfig(
          table: 'organizations',
          on: 'users.uuid = organizations.user_id',
          type: JoinType.left,
        ),
      ],
      where: {'users.uuid': userId},
      limit: 1,
    );

    if (results.isEmpty) return null;

    return UserWithInformationAndOrganization.fromMap(results.first);
  }

  /// Get user with their information only
  Future<UserWithInformation?> getUserWithInformation({
    required String userId,
  }) async {
    final results = await executeJoinQuery(
      baseTable: 'users',
      joins: [
        JoinConfig(
          table: 'user_information',
          on: 'users.uuid = user_information.user_id',
          type: JoinType.inner,
        ),
      ],
      where: {'users.uuid': userId},
      limit: 1,
    );

    if (results.isEmpty) return null;

    return UserWithInformation.fromMap(results.first);
  }

  /// Get user with their organization only
  Future<UserWithOrganization?> getUserWithOrganization({
    required String userId,
  }) async {
    final results = await executeJoinQuery(
      baseTable: 'users',
      joins: [
        JoinConfig(
          table: 'organizations',
          on: 'users.uuid = organizations.user_id',
          type: JoinType.inner,
        ),
      ],
      where: {'users.uuid': userId},
      limit: 1,
    );

    if (results.isEmpty) return null;

    return UserWithOrganization.fromMap(results.first);
  }

  /// Get all users with their information
  Future<List<UserWithInformation>> getAllUsersWithInformation({
    Role? role,
    int? limit,
    int? offset,
  }) async {
    final where = <String, dynamic>{};
    if (role != null) {
      where['user_information.role'] = role.value;
    }

    final results = await executeJoinQuery(
      baseTable: 'users',
      joins: [
        JoinConfig(
          table: 'user_information',
          on: 'users.uuid = user_information.user_id',
          type: JoinType.inner,
        ),
      ],
      where: where.isNotEmpty ? where : null,
      orderBy: 'users.created_at',
      orderDirection: 'DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((r) => UserWithInformation.fromMap(r)).toList();
  }

  /// Get users by organization
  Future<List<UserWithInformation>> getUsersByOrganization({
    required String organizationId,
    int? limit,
    int? offset,
  }) async {
    final results = await executeJoinQuery(
      baseTable: 'users',
      joins: [
        JoinConfig(
          table: 'user_information',
          on: 'users.uuid = user_information.user_id',
          type: JoinType.inner,
        ),
        JoinConfig(
          table: 'organizations',
          on: 'users.uuid = organizations.user_id',
          type: JoinType.inner,
        ),
      ],
      where: {'organizations.uuid': organizationId},
      orderBy: 'users.created_at',
      orderDirection: 'DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((r) => UserWithInformation.fromMap(r)).toList();
  }

  /// Get developers (users with developer role)
  Future<List<UserWithInformation>> getDevelopers({
    int? limit,
    int? offset,
  }) async {
    return getAllUsersWithInformation(
      role: Role.developer,
      limit: limit,
      offset: offset,
    );
  }

  /// Get team members (users with team role)
  Future<List<UserWithInformation>> getTeamMembers({
    int? limit,
    int? offset,
  }) async {
    return getAllUsersWithInformation(
      role: Role.team,
      limit: limit,
      offset: offset,
    );
  }
}

/// User with information (one-to-one relationship)
class UserWithInformation {
  final UserEntity user;
  final UserInformation information;

  UserWithInformation({
    required this.user,
    required this.information,
  });

  factory UserWithInformation.fromMap(Map<String, dynamic> map) {
    return UserWithInformation(
      user: UserEntity.fromMap(map),
      information: UserInformation.fromMap(map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toMap(),
      'information': information.toMap(),
    };
  }
}

/// User with organization (one-to-one relationship)
class UserWithOrganization {
  final UserEntity user;
  final Organization organization;

  UserWithOrganization({
    required this.user,
    required this.organization,
  });

  factory UserWithOrganization.fromMap(Map<String, dynamic> map) {
    return UserWithOrganization(
      user: UserEntity.fromMap(map),
      organization: Organization.fromMap(map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toMap(),
      'organization': organization.toMap(),
    };
  }
}
