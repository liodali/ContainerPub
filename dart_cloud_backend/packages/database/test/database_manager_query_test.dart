import 'package:test/test.dart';
import 'package:database/src/query_builder.dart';
import 'package:database/src/entities/user_entity.dart';
import 'package:database/src/entities/function_entity.dart';

/// These tests verify SQL query generation without requiring a database connection
void main() {
  group('DatabaseManagerQuery - Query Generation', () {
    test('should generate correct SELECT query for findAll', () {
      final builder = QueryBuilder()
          .table('users')
          .where('status', 'active')
          .orderBy('created_at', direction: 'DESC')
          .limit(10);

      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM users WHERE status = @param_0 ORDER BY created_at DESC LIMIT 10',
        ),
      );
      expect(builder.parameters['param_0'], equals('active'));
    });

    test('should generate correct SELECT query with multiple WHERE clauses', () {
      final builder = QueryBuilder()
          .table('functions')
          .where('user_id', 123)
          .where('status', 'active')
          .orderBy('name')
          .limit(20)
          .offset(40);

      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM functions WHERE user_id = @param_0 AND status = @param_1 ORDER BY name ASC LIMIT 20 OFFSET 40',
        ),
      );
      expect(builder.parameters['param_0'], equals(123));
      expect(builder.parameters['param_1'], equals('active'));
    });

    test('should generate correct INSERT query', () {
      final builder = QueryBuilder().table('users');
      final data = {
        'email': 'test@example.com',
        'password_hash': 'hashed_password',
      };

      final sql = builder.buildInsert(data);

      expect(sql, contains('INSERT INTO users (email, password_hash)'));
      expect(sql, contains('VALUES (@param_0, @param_1)'));
      expect(sql, contains('RETURNING *'));
      expect(builder.parameters['param_0'], equals('test@example.com'));
      expect(builder.parameters['param_1'], equals('hashed_password'));
    });

    test('should generate correct UPDATE query', () {
      final builder = QueryBuilder()
          .table('functions')
          .where('uuid', 'func-uuid');

      final data = {
        'name': 'new-name',
        'status': 'inactive',
      };

      final sql = builder.buildUpdate(data);

      expect(sql, contains('UPDATE functions SET'));
      expect(sql, contains('name = @param_1'));
      expect(sql, contains('status = @param_2'));
      expect(sql, contains('WHERE uuid = @param_0'));
      expect(sql, contains('RETURNING *'));
      expect(builder.parameters['param_1'], equals('new-name'));
      expect(builder.parameters['param_2'], equals('inactive'));
      expect(builder.parameters['param_0'], equals('func-uuid'));
    });

    test('should generate correct DELETE query', () {
      final builder = QueryBuilder()
          .table('function_logs')
          .where('function_id', 123)
          .where('level', 'debug');

      final sql = builder.buildDelete();

      expect(
        sql,
        equals(
          'DELETE FROM function_logs WHERE function_id = @param_0 AND level = @param_1',
        ),
      );
      expect(builder.parameters['param_0'], equals(123));
      expect(builder.parameters['param_1'], equals('debug'));
    });

    test('should generate correct COUNT query', () {
      final builder = QueryBuilder()
          .table('functions')
          .select(['COUNT(*) as count'])
          .where('status', 'active');

      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT COUNT(*) as count FROM functions WHERE status = @param_0',
        ),
      );
    });
  });

  group('DatabaseManagerQuery - Relationship Queries', () {
    test('should generate correct hasMany query', () {
      final builder = QueryBuilder()
          .table('function_deployments')
          .where('function_id', 123)
          .orderBy('version', direction: 'DESC');

      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM function_deployments WHERE function_id = @param_0 ORDER BY version DESC',
        ),
      );
      expect(builder.parameters['param_0'], equals(123));
    });

    test('should generate correct belongsTo query', () {
      final builder = QueryBuilder().table('users').where('id', 456).limit(1);

      final sql = builder.buildSelect();

      expect(
        sql,
        equals('SELECT * FROM users WHERE id = @param_0 LIMIT 1'),
      );
      expect(builder.parameters['param_0'], equals(456));
    });

    test('should generate correct JOIN query for relationships', () {
      final builder = QueryBuilder()
          .table('functions f')
          .select(['f.*', 'u.email', 'u.uuid as user_uuid'])
          .join('users u', 'f.user_id', 'u.id')
          .where('f.uuid', 'func-uuid');

      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT f.*, u.email, u.uuid as user_uuid FROM functions f INNER JOIN users u ON f.user_id = u.id WHERE f.uuid = @param_0',
        ),
      );
    });
  });

  group('DatabaseManagerQuery - Complex Queries', () {
    test('should generate query with multiple JOINs', () {
      final builder = QueryBuilder()
          .table('functions f')
          .select(['f.*', 'u.email', 'COUNT(fd.id) as deployment_count'])
          .join('users u', 'f.user_id', 'u.id')
          .leftJoin('function_deployments fd', 'f.id', 'fd.function_id')
          .where('f.status', 'active')
          .groupBy('f.id, u.email')
          .orderBy('f.created_at', direction: 'DESC');

      final sql = builder.buildSelect();

      expect(
        sql,
        contains(
          'SELECT f.*, u.email, COUNT(fd.id) as deployment_count FROM functions f',
        ),
      );
      expect(sql, contains('INNER JOIN users u ON f.user_id = u.id'));
      expect(
        sql,
        contains('LEFT JOIN function_deployments fd ON f.id = fd.function_id'),
      );
      expect(sql, contains('WHERE f.status = @param_0'));
      expect(sql, contains('GROUP BY f.id, u.email'));
      expect(sql, contains('ORDER BY f.created_at DESC'));
    });

    test('should generate query with WHERE IN', () {
      final builder = QueryBuilder()
          .table('functions')
          .whereIn('status', ['active', 'building', 'deployed'])
          .orderBy('created_at', direction: 'DESC');

      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM functions WHERE status = ANY(@param_0) ORDER BY created_at DESC',
        ),
      );
      expect(
        builder.parameters['param_0'],
        equals(['active', 'building', 'deployed']),
      );
    });

    test('should generate query with date comparison', () {
      final cutoffDate = DateTime(2024, 1, 1);
      final builder = QueryBuilder()
          .table('function_logs')
          .where('timestamp', cutoffDate, operator: '>')
          .orderBy('timestamp', direction: 'DESC')
          .limit(100);

      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM function_logs WHERE timestamp > @param_0 ORDER BY timestamp DESC LIMIT 100',
        ),
      );
      expect(builder.parameters['param_0'], equals(cutoffDate));
    });

    test('should generate query with NULL checks', () {
      final builder = QueryBuilder()
          .table('functions')
          .whereNotNull('active_deployment_id')
          .where('status', 'active');

      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM functions WHERE active_deployment_id IS NOT NULL AND status = @param_0',
        ),
      );
    });

    test('should generate query with LIKE operator', () {
      final builder = QueryBuilder()
          .table('functions')
          .where('name', '%search-term%', operator: 'ILIKE')
          .orderBy('name');

      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM functions WHERE name ILIKE @param_0 ORDER BY name ASC',
        ),
      );
      expect(builder.parameters['param_0'], equals('%search-term%'));
    });
  });

  group('DatabaseManagerQuery - Batch Operations', () {
    test('should generate multiple INSERT queries for batch', () {
      final logsData = [
        {'function_id': 123, 'level': 'info', 'message': 'Log 1'},
        {'function_id': 123, 'level': 'error', 'message': 'Log 2'},
        {'function_id': 123, 'level': 'warn', 'message': 'Log 3'},
      ];

      for (final data in logsData) {
        final builder = QueryBuilder().table('function_logs');
        final sql = builder.buildInsert(data);

        expect(sql, contains('INSERT INTO function_logs'));
        expect(sql, contains('function_id, level, message'));
        expect(sql, contains('RETURNING *'));
      }
    });
  });


  group('DatabaseManagerQuery - Pagination', () {
    test('should generate correct pagination query for page 1', () {
      final pageSize = 20;
      final page = 1;
      final offset = (page - 1) * pageSize;

      final builder = QueryBuilder()
          .table('functions')
          .where('status', 'active')
          .orderBy('created_at', direction: 'DESC')
          .limit(pageSize)
          .offset(offset);

      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM functions WHERE status = @param_0 ORDER BY created_at DESC LIMIT 20 OFFSET 0',
        ),
      );
    });

    test('should generate correct pagination query for page 3', () {
      final pageSize = 20;
      final page = 3;
      final offset = (page - 1) * pageSize;

      final builder = QueryBuilder()
          .table('functions')
          .orderBy('name')
          .limit(pageSize)
          .offset(offset);

      final sql = builder.buildSelect();

      expect(
        sql,
        equals('SELECT * FROM functions ORDER BY name ASC LIMIT 20 OFFSET 40'),
      );
    });
  });

  group('DatabaseManagerQuery - Analytics Queries', () {
    test('should generate aggregation query', () {
      final builder = QueryBuilder()
          .table('function_invocations')
          .select([
            'COUNT(*) as total',
            'AVG(duration_ms) as avg_duration',
            'MAX(duration_ms) as max_duration',
            'MIN(duration_ms) as min_duration',
          ])
          .where('function_id', 123)
          .where('status', 'success');

      final sql = builder.buildSelect();

      expect(
        sql,
        contains('SELECT COUNT(*) as total, AVG(duration_ms) as avg_duration'),
      );
      expect(
        sql,
        contains('WHERE function_id = @param_0 AND status = @param_1'),
      );
    });

    test('should generate GROUP BY query with HAVING', () {
      final builder = QueryBuilder()
          .table('functions')
          .select(['user_id', 'COUNT(*) as function_count'])
          .groupBy('user_id')
          .having('COUNT(*) > 5')
          .orderBy('function_count', direction: 'DESC');

      final sql = builder.buildSelect();

      expect(sql, contains('GROUP BY user_id'));
      expect(sql, contains('HAVING COUNT(*) > 5'));
      expect(sql, contains('ORDER BY function_count DESC'));
    });
  });

  group('Entity Integration with Query Builder', () {
    test('should convert UserEntity to map for INSERT', () {
      final user = UserEntity(
        email: 'test@example.com',
        passwordHash: 'hashed_password',
      );

      final map = user.toMap();
      final builder = QueryBuilder().table('users');
      final sql = builder.buildInsert(map);

      expect(sql, contains('INSERT INTO users (email, password_hash)'));
      expect(builder.parameters['param_0'], equals('test@example.com'));
      expect(builder.parameters['param_1'], equals('hashed_password'));
    });

    test('should convert FunctionEntity to map for UPDATE', () {
      final function = FunctionEntity(
        name: 'my-function',
        status: 'active',
      );

      final map = function.toMap();
      final builder = QueryBuilder().table('functions').where('id', 123);

      final sql = builder.buildUpdate(map);

      expect(sql, contains('UPDATE functions SET'));
      expect(sql, contains('name = @param_1'));
      expect(sql, contains('status = @param_2'));
    });

    test('should use entity table name in queries', () {
      final user = UserEntity(email: 'test@example.com');
      final builder = QueryBuilder().table(user.tableName);

      final sql = builder.buildSelect();

      expect(sql, equals('SELECT * FROM users'));
    });
  });

  group('Query Builder - SQL Injection Prevention', () {
    test('should use parameterized queries for WHERE values', () {
      final maliciousInput = "'; DROP TABLE users; --";
      final builder = QueryBuilder()
          .table('users')
          .where('email', maliciousInput);

      final sql = builder.buildSelect();

      // Should use parameter, not inline the value
      expect(sql, equals('SELECT * FROM users WHERE email = @param_0'));
      expect(builder.parameters['param_0'], equals(maliciousInput));
      expect(sql, isNot(contains('DROP TABLE')));
    });

    test('should use parameterized queries for INSERT values', () {
      final maliciousInput = "'; DROP TABLE users; --";
      final builder = QueryBuilder().table('users');
      final sql = builder.buildInsert({
        'email': maliciousInput,
      });

      expect(sql, contains('@param_0'));
      expect(builder.parameters['param_0'], equals(maliciousInput));
      expect(sql, isNot(contains('DROP TABLE')));
    });
  });
}
