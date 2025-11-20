import 'package:test/test.dart';
import 'package:database/src/entities/user_entity.dart';
import 'package:database/src/entities/function_entity.dart';
import 'package:database/src/entities/function_deployment_entity.dart';
import 'package:database/src/entities/function_log_entity.dart';
import 'package:database/src/entities/function_invocation_entity.dart';

void main() {
  group('UserEntity', () {
    test('should have correct table name', () {
      final user = UserEntity(email: 'test@example.com');
      expect(user.tableName, equals('users'));
    });

    test('should convert to map correctly', () {
      final user = UserEntity(
        id: 1,
        uuid: 'user-uuid',
        email: 'test@example.com',
        passwordHash: 'hashed_password',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final map = user.toDBMap();

      expect(map['id'], equals(1));
      expect(map['uuid'], equals('user-uuid'));
      expect(map['email'], equals('test@example.com'));
      expect(map['password_hash'], equals('hashed_password'));
      expect(map['created_at'], equals(DateTime(2024, 1, 1)));
      expect(map['updated_at'], equals(DateTime(2024, 1, 2)));
    });

    test('should convert to map with only required fields', () {
      final user = UserEntity(email: 'test@example.com');
      final map = user.toDBMap();

      expect(map['email'], equals('test@example.com'));
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('uuid'), isFalse);
      expect(map.containsKey('password_hash'), isFalse);
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'uuid': 'user-uuid',
        'email': 'test@example.com',
        'password_hash': 'hashed_password',
        'created_at': DateTime(2024, 1, 1),
        'updated_at': DateTime(2024, 1, 2),
      };

      final user = UserEntity.fromMap(map);

      expect(user.id, equals(1));
      expect(user.uuid, equals('user-uuid'));
      expect(user.email, equals('test@example.com'));
      expect(user.passwordHash, equals('hashed_password'));
      expect(user.createdAt, equals(DateTime(2024, 1, 1)));
      expect(user.updatedAt, equals(DateTime(2024, 1, 2)));
    });

    test('should support copyWith', () {
      final user = UserEntity(
        id: 1,
        uuid: 'user-uuid',
        email: 'test@example.com',
      );

      final updated = user.copyWith(email: 'new@example.com');

      expect(updated.id, equals(1));
      expect(updated.uuid, equals('user-uuid'));
      expect(updated.email, equals('new@example.com'));
    });
  });

  group('FunctionEntity', () {
    test('should have correct table name', () {
      final function = FunctionEntity(name: 'my-function');
      expect(function.tableName, equals('functions'));
    });

    test('should convert to map correctly', () {
      final function = FunctionEntity(
        id: 1,
        uuid: 'func-uuid',
        userId: 123,
        name: 'my-function',
        status: 'active',
        activeDeploymentId: 456,
        analysisResult: {'valid': true},
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final map = function.toDBMap();

      expect(map['id'], equals(1));
      expect(map['uuid'], equals('func-uuid'));
      expect(map['user_id'], equals(123));
      expect(map['name'], equals('my-function'));
      expect(map['status'], equals('active'));
      expect(map['active_deployment_id'], equals(456));
      expect(map['analysis_result'], equals({'valid': true}));
      expect(map['created_at'], equals(DateTime(2024, 1, 1)));
      expect(map['updated_at'], equals(DateTime(2024, 1, 2)));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'uuid': 'func-uuid',
        'user_id': 123,
        'name': 'my-function',
        'status': 'active',
        'active_deployment_id': 456,
        'analysis_result': {'valid': true},
        'created_at': DateTime(2024, 1, 1),
        'updated_at': DateTime(2024, 1, 2),
      };

      final function = FunctionEntity.fromMap(map);

      expect(function.id, equals(1));
      expect(function.uuid, equals('func-uuid'));
      expect(function.userId, equals(123));
      expect(function.name, equals('my-function'));
      expect(function.status, equals('active'));
      expect(function.activeDeploymentId, equals(456));
      expect(function.analysisResult, equals({'valid': true}));
    });

    test('should support copyWith', () {
      final function = FunctionEntity(
        id: 1,
        name: 'my-function',
        status: 'active',
      );

      final updated = function.copyWith(status: 'inactive');

      expect(updated.id, equals(1));
      expect(updated.name, equals('my-function'));
      expect(updated.status, equals('inactive'));
    });
  });

  group('FunctionDeploymentEntity', () {
    test('should have correct table name', () {
      final deployment = FunctionDeploymentEntity(
        version: 1,
        imageTag: 'v1.0.0',
        s3Key: 'path/to/file',
      );
      expect(deployment.tableName, equals('function_deployments'));
    });

    test('should convert to map correctly', () {
      final deployment = FunctionDeploymentEntity(
        id: 1,
        uuid: 'deploy-uuid',
        functionId: 123,
        version: 1,
        imageTag: 'v1.0.0',
        s3Key: 'path/to/file',
        status: 'deployed',
        isActive: true,
        buildLogs: 'Build successful',
        deployedAt: DateTime(2024, 1, 1),
      );

      final map = deployment.toDBMap();

      expect(map['id'], equals(1));
      expect(map['uuid'], equals('deploy-uuid'));
      expect(map['function_id'], equals(123));
      expect(map['version'], equals(1));
      expect(map['image_tag'], equals('v1.0.0'));
      expect(map['s3_key'], equals('path/to/file'));
      expect(map['status'], equals('deployed'));
      expect(map['is_active'], equals(true));
      expect(map['build_logs'], equals('Build successful'));
      expect(map['deployed_at'], equals(DateTime(2024, 1, 1)));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'uuid': 'deploy-uuid',
        'function_id': 123,
        'version': 1,
        'image_tag': 'v1.0.0',
        's3_key': 'path/to/file',
        'status': 'deployed',
        'is_active': true,
        'build_logs': 'Build successful',
        'deployed_at': DateTime(2024, 1, 1),
      };

      final deployment = FunctionDeploymentEntity.fromMap(map);

      expect(deployment.version, equals(1));
      expect(deployment.imageTag, equals('v1.0.0'));
      expect(deployment.s3Key, equals('path/to/file'));
      expect(deployment.isActive, equals(true));
    });
  });

  group('FunctionLogEntity', () {
    test('should have correct table name', () {
      final log = FunctionLogEntity(level: 'info', message: 'Test log');
      expect(log.tableName, equals('function_logs'));
    });

    test('should convert to map correctly', () {
      final log = FunctionLogEntity(
        id: 1,
        uuid: 'log-uuid',
        functionId: 123,
        level: 'error',
        message: 'An error occurred',
        timestamp: DateTime(2024, 1, 1),
      );

      final map = log.toDBMap();

      expect(map['id'], equals(1));
      expect(map['uuid'], equals('log-uuid'));
      expect(map['function_id'], equals(123));
      expect(map['level'], equals('error'));
      expect(map['message'], equals('An error occurred'));
      expect(map['timestamp'], equals(DateTime(2024, 1, 1)));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'uuid': 'log-uuid',
        'function_id': 123,
        'level': 'warn',
        'message': 'Warning message',
        'timestamp': DateTime(2024, 1, 1),
      };

      final log = FunctionLogEntity.fromMap(map);

      expect(log.level, equals('warn'));
      expect(log.message, equals('Warning message'));
      expect(log.functionId, equals(123));
    });
  });

  group('FunctionInvocationEntity', () {
    test('should have correct table name', () {
      final invocation = FunctionInvocationEntity(status: 'success');
      expect(invocation.tableName, equals('function_invocations'));
    });

    test('should convert to map correctly', () {
      final invocation = FunctionInvocationEntity(
        id: 1,
        uuid: 'inv-uuid',
        functionId: 123,
        status: 'success',
        durationMs: 150,
        error: null,
        timestamp: DateTime(2024, 1, 1),
      );

      final map = invocation.toDBMap();

      expect(map['id'], equals(1));
      expect(map['uuid'], equals('inv-uuid'));
      expect(map['function_id'], equals(123));
      expect(map['status'], equals('success'));
      expect(map['duration_ms'], equals(150));
      expect(map.containsKey('error'), isFalse);
      expect(map['timestamp'], equals(DateTime(2024, 1, 1)));
    });

    test('should handle error field correctly', () {
      final invocation = FunctionInvocationEntity(
        status: 'error',
        error: 'Connection timeout',
      );

      final map = invocation.toDBMap();

      expect(map['status'], equals('error'));
      expect(map['error'], equals('Connection timeout'));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'uuid': 'inv-uuid',
        'function_id': 123,
        'status': 'error',
        'duration_ms': 5000,
        'error': 'Timeout',
        'timestamp': DateTime(2024, 1, 1),
      };

      final invocation = FunctionInvocationEntity.fromMap(map);

      expect(invocation.status, equals('error'));
      expect(invocation.durationMs, equals(5000));
      expect(invocation.error, equals('Timeout'));
    });
  });

  group('Entity - Edge cases', () {
    test('should handle null values in toDBMap', () {
      final user = UserEntity(email: 'test@example.com');
      final map = user.toDBMap();

      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('uuid'), isFalse);
      expect(map.containsKey('password_hash'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
      expect(map.containsKey('updated_at'), isFalse);
    });

    test('should handle null values in fromMap', () {
      final map = {
        'email': 'test@example.com',
      };

      final user = UserEntity.fromMap(map);

      expect(user.email, equals('test@example.com'));
      expect(user.id, isNull);
      expect(user.uuid, isNull);
      expect(user.passwordHash, isNull);
      expect(user.createdAt, isNull);
      expect(user.updatedAt, isNull);
    });

    test('should preserve null values in copyWith when not specified', () {
      final function = FunctionEntity(
        id: 1,
        name: 'my-function',
        status: null,
      );

      final updated = function.copyWith(name: 'new-name');

      expect(updated.id, equals(1));
      expect(updated.name, equals('new-name'));
      expect(updated.status, isNull);
    });
  });
}
