import 'package:database/src/entities/organization.dart';
import 'package:database/src/entities/user_information.dart';
import 'package:database/src/entities/organization_team.dart';
import 'package:database/src/entities/organization_team_member.dart';

import 'database_manager_query.dart';
import 'relationship_manager.dart';
import 'managers/user_relationships.dart';
import 'managers/organization_relationships.dart';
import 'entities/user_entity.dart';
import 'entities/function_entity.dart';
import 'entities/function_deployment_entity.dart';
import 'entities/function_log_entity.dart';
import 'entities/function_invocation_entity.dart';

/// Database managers for each entity with relationship support
class DatabaseManagers
    with RelationshipManager, UserRelationships, OrganizationRelationships {
  /// User manager
  static final users = DatabaseManagerQuery<UserEntity>(
    tableName: 'users',
    fromMap: UserEntity.fromMap,
  );

  /// User information manager
  static final userInformation = DatabaseManagerQuery<UserInformation>(
    tableName: 'user_information',
    fromMap: UserInformation.fromMap,
  );

  /// Organization manager
  static final organizations = DatabaseManagerQuery<Organization>(
    tableName: 'organizations',
    fromMap: Organization.fromMap,
  );

  /// Organization team manager
  static final organizationTeams = DatabaseManagerQuery<OrganizationTeam>(
    tableName: 'organization_teams',
    fromMap: OrganizationTeam.fromMap,
  );

  /// Organization team member manager
  static final organizationTeamMembers =
      DatabaseManagerQuery<OrganizationTeamMember>(
        tableName: 'organization_team_members',
        fromMap: OrganizationTeamMember.fromMap,
      );

  /// Function manager
  static final functions = DatabaseManagerQuery<FunctionEntity>(
    tableName: 'functions',
    fromMap: FunctionEntity.fromMap,
  );

  /// Function deployment manager
  static final functionDeployments =
      DatabaseManagerQuery<FunctionDeploymentEntity>(
        tableName: 'function_deployments',
        fromMap: FunctionDeploymentEntity.fromMap,
      );

  /// Function log manager
  static final functionLogs = DatabaseManagerQuery<FunctionLogEntity>(
    tableName: 'function_logs',
    fromMap: FunctionLogEntity.fromMap,
  );

  /// Function invocation manager
  static final functionInvocations =
      DatabaseManagerQuery<FunctionInvocationEntity>(
        tableName: 'function_invocations',
        fromMap: FunctionInvocationEntity.fromMap,
      );

  /// Singleton instance for relationship methods
  static final _instance = DatabaseManagers._();

  DatabaseManagers._();

  /// Get the singleton instance with relationship methods
  static DatabaseManagers get instance => _instance;
}
