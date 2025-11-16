import 'database_manager_query.dart';
import 'entities/user_entity.dart';
import 'entities/function_entity.dart';
import 'entities/function_deployment_entity.dart';
import 'entities/function_log_entity.dart';
import 'entities/function_invocation_entity.dart';

/// Database managers for each entity
class DatabaseManagers {
  /// User manager
  static final users = DatabaseManagerQuery<UserEntity>(
    tableName: 'users',
    fromMap: UserEntity.fromMap,
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
}
