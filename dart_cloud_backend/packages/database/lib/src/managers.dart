import 'package:database/src/entities/logs_entity.dart';
import 'package:database/src/entities/organization.dart';
import 'package:database/src/entities/user_information.dart';
import 'package:database/src/entities/organization_member.dart';
import 'package:database/src/entities/api_key_entity.dart';
import 'package:database/src/entities/email_verification_otp_entity.dart';

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

  /// Organization member manager
  static final organizationMembers = DatabaseManagerQuery<OrganizationMember>(
    tableName: 'organization_members',
    fromMap: OrganizationMember.fromMap,
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
    tableName: 'function_deploy_logs',
    fromMap: FunctionLogEntity.fromMap,
  );

  /// Function invocation manager
  static final functionInvocations =
      DatabaseManagerQuery<FunctionInvocationEntity>(
        tableName: 'function_invocations',
        fromMap: FunctionInvocationEntity.fromMap,
      );

  /// Function log manager
  static final logs = DatabaseManagerQuery<LogsEntity>(
    tableName: 'logs',
    fromMap: LogsEntity.fromMap,
  );

  /// API key manager
  static final apiKeys = DatabaseManagerQuery<ApiKeyEntity>(
    tableName: 'api_keys',
    fromMap: ApiKeyEntity.fromMap,
  );

  /// Email verification OTP manager
  static final emailVerificationOtps =
      DatabaseManagerQuery<EmailVerificationOtpEntity>(
        tableName: 'email_verification_otps',
        fromMap: EmailVerificationOtpEntity.fromMap,
      );

  /// Singleton instance for relationship methods
  static final _instance = DatabaseManagers._();

  DatabaseManagers._();

  /// Get the singleton instance with relationship methods
  static DatabaseManagers get instance => _instance;
}
