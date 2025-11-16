import 'package:test/test.dart';
import 'package:database/src/query_builder.dart';

void main() {
  group('QueryBuilder - SELECT queries', () {
    test('should build simple SELECT query', () {
      final builder = QueryBuilder().table('users');
      final sql = builder.buildSelect();

      expect(sql, equals('SELECT * FROM users'));
      expect(builder.parameters, isEmpty);
    });

    test('should build SELECT with specific columns', () {
      final builder = QueryBuilder().table('users').select([
        'id',
        'email',
        'created_at',
      ]);
      final sql = builder.buildSelect();

      expect(sql, equals('SELECT id, email, created_at FROM users'));
    });

    test('should build SELECT with WHERE clause', () {
      final builder = QueryBuilder()
          .table('users')
          .where('email', 'test@example.com');
      final sql = builder.buildSelect();

      expect(sql, equals('SELECT * FROM users WHERE email = @param_0'));
      expect(builder.parameters['param_0'], equals('test@example.com'));
    });

    test('should build SELECT with multiple WHERE clauses', () {
      final builder = QueryBuilder()
          .table('functions')
          .where('user_id', 123)
          .where('status', 'active');
      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM functions WHERE user_id = @param_0 AND status = @param_1',
        ),
      );
      expect(builder.parameters['param_0'], equals(123));
      expect(builder.parameters['param_1'], equals('active'));
    });

    test('should build SELECT with custom operator', () {
      final builder = QueryBuilder()
          .table('functions')
          .where('created_at', DateTime(2024, 1, 1), operator: '>');
      final sql = builder.buildSelect();

      expect(
        sql,
        equals('SELECT * FROM functions WHERE created_at > @param_0'),
      );
      expect(builder.parameters['param_0'], equals(DateTime(2024, 1, 1)));
    });

    test('should build SELECT with WHERE IN clause', () {
      final builder = QueryBuilder().table('functions').whereIn('status', [
        'active',
        'building',
        'deployed',
      ]);
      final sql = builder.buildSelect();

      expect(
        sql,
        equals('SELECT * FROM functions WHERE status = ANY(@param_0)'),
      );
      expect(
        builder.parameters['param_0'],
        equals(['active', 'building', 'deployed']),
      );
    });

    test('should build SELECT with WHERE NULL', () {
      final builder = QueryBuilder()
          .table('functions')
          .whereNull('active_deployment_id');
      final sql = builder.buildSelect();

      expect(
        sql,
        equals('SELECT * FROM functions WHERE active_deployment_id IS NULL'),
      );
    });

    test('should build SELECT with WHERE NOT NULL', () {
      final builder = QueryBuilder()
          .table('functions')
          .whereNotNull('active_deployment_id');
      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM functions WHERE active_deployment_id IS NOT NULL',
        ),
      );
    });

    test('should build SELECT with raw WHERE clause', () {
      final builder = QueryBuilder().table('users').whereRaw(
        'email ILIKE @pattern',
        {'pattern': '%@example.com'},
      );
      final sql = builder.buildSelect();

      expect(sql, equals('SELECT * FROM users WHERE email ILIKE @pattern'));
      expect(builder.parameters['pattern'], equals('%@example.com'));
    });

    test('should build SELECT with OR WHERE clause', () {
      final builder = QueryBuilder()
          .table('functions')
          .where('status', 'active')
          .orWhere('status', 'building');
      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM functions WHERE status = @param_0 OR status = @param_1',
        ),
      );
    });

    test('should build SELECT with ORDER BY', () {
      final builder = QueryBuilder()
          .table('users')
          .orderBy('created_at', direction: 'DESC');
      final sql = builder.buildSelect();

      expect(sql, equals('SELECT * FROM users ORDER BY created_at DESC'));
    });

    test('should build SELECT with multiple ORDER BY', () {
      final builder = QueryBuilder()
          .table('functions')
          .orderBy('status')
          .orderBy('created_at', direction: 'DESC');
      final sql = builder.buildSelect();

      expect(
        sql,
        equals('SELECT * FROM functions ORDER BY status ASC, created_at DESC'),
      );
    });

    test('should build SELECT with LIMIT', () {
      final builder = QueryBuilder().table('users').limit(10);
      final sql = builder.buildSelect();

      expect(sql, equals('SELECT * FROM users LIMIT 10'));
    });

    test('should build SELECT with OFFSET', () {
      final builder = QueryBuilder().table('users').offset(20);
      final sql = builder.buildSelect();

      expect(sql, equals('SELECT * FROM users OFFSET 20'));
    });

    test('should build SELECT with LIMIT and OFFSET', () {
      final builder = QueryBuilder().table('users').limit(10).offset(20);
      final sql = builder.buildSelect();

      expect(sql, equals('SELECT * FROM users LIMIT 10 OFFSET 20'));
    });

    test('should build SELECT with GROUP BY', () {
      final builder = QueryBuilder()
          .table('functions')
          .select(['user_id', 'COUNT(*) as count'])
          .groupBy('user_id');
      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT user_id, COUNT(*) as count FROM functions GROUP BY user_id',
        ),
      );
    });

    test('should build SELECT with HAVING', () {
      final builder = QueryBuilder()
          .table('functions')
          .select(['user_id', 'COUNT(*) as count'])
          .groupBy('user_id')
          .having('COUNT(*) > 5');
      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT user_id, COUNT(*) as count FROM functions GROUP BY user_id HAVING COUNT(*) > 5',
        ),
      );
    });
  });

  group('QueryBuilder - JOIN queries', () {
    test('should build SELECT with INNER JOIN', () {
      final builder = QueryBuilder()
          .table('functions')
          .join('users', 'functions.user_id', 'users.id');
      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM functions INNER JOIN users ON functions.user_id = users.id',
        ),
      );
    });

    test('should build SELECT with LEFT JOIN', () {
      final builder = QueryBuilder()
          .table('functions')
          .leftJoin(
            'function_deployments',
            'functions.id',
            'function_deployments.function_id',
          );
      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM functions LEFT JOIN function_deployments ON functions.id = function_deployments.function_id',
        ),
      );
    });

    test('should build SELECT with RIGHT JOIN', () {
      final builder = QueryBuilder()
          .table('functions')
          .rightJoin('users', 'functions.user_id', 'users.id');
      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM functions RIGHT JOIN users ON functions.user_id = users.id',
        ),
      );
    });

    test('should build SELECT with multiple JOINs', () {
      final builder = QueryBuilder()
          .table('functions f')
          .join('users u', 'f.user_id', 'u.id')
          .leftJoin('function_deployments fd', 'f.id', 'fd.function_id');
      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT * FROM functions f INNER JOIN users u ON f.user_id = u.id LEFT JOIN function_deployments fd ON f.id = fd.function_id',
        ),
      );
    });

    test('should build complex query with JOIN, WHERE, ORDER BY, LIMIT', () {
      final builder = QueryBuilder()
          .table('functions f')
          .select(['f.*', 'u.email'])
          .join('users u', 'f.user_id', 'u.id')
          .where('f.status', 'active')
          .where('u.email', '%@example.com', operator: 'LIKE')
          .orderBy('f.created_at', direction: 'DESC')
          .limit(10);
      final sql = builder.buildSelect();

      expect(
        sql,
        equals(
          'SELECT f.*, u.email FROM functions f INNER JOIN users u ON f.user_id = u.id WHERE f.status = @param_0 AND u.email LIKE @param_1 ORDER BY f.created_at DESC LIMIT 10',
        ),
      );
      expect(builder.parameters['param_0'], equals('active'));
      expect(builder.parameters['param_1'], equals('%@example.com'));
    });
  });

  group('QueryBuilder - INSERT queries', () {
    test('should build INSERT query', () {
      final builder = QueryBuilder().table('users');
      final sql = builder.buildInsert({
        'email': 'test@example.com',
        'password_hash': 'hashed_password',
      });

      expect(
        sql.trim(),
        equals(
          'INSERT INTO users (email, password_hash)\n      VALUES (@param_0, @param_1)\n      RETURNING *',
        ),
      );
      expect(builder.parameters['param_0'], equals('test@example.com'));
      expect(builder.parameters['param_1'], equals('hashed_password'));
    });

    test('should build INSERT query with multiple columns', () {
      final builder = QueryBuilder().table('functions');
      final sql = builder.buildInsert({
        'user_id': 123,
        'name': 'my-function',
        'status': 'active',
      });

      expect(sql, contains('INSERT INTO functions (user_id, name, status)'));
      expect(sql, contains('VALUES (@param_0, @param_1, @param_2)'));
      expect(builder.parameters['param_0'], equals(123));
      expect(builder.parameters['param_1'], equals('my-function'));
      expect(builder.parameters['param_2'], equals('active'));
    });
  });

  group('QueryBuilder - UPDATE queries', () {
    test('should build UPDATE query', () {
      final builder = QueryBuilder().table('users').where('id', 123);
      final sql = builder.buildUpdate({'email': 'new@example.com'});

      expect(
        sql,
        equals(
          'UPDATE users SET email = @param_1 WHERE id = @param_0 RETURNING *',
        ),
      );
      expect(builder.parameters['param_1'], equals('new@example.com'));
      expect(builder.parameters['param_0'], equals(123));
    });

    test('should build UPDATE query with multiple columns', () {
      final builder = QueryBuilder()
          .table('functions')
          .where('uuid', 'func-uuid');
      final sql = builder.buildUpdate({
        'name': 'new-name',
        'status': 'inactive',
      });

      expect(sql, contains('UPDATE functions SET'));
      expect(sql, contains('name = @param_1'));
      expect(sql, contains('status = @param_2'));
      expect(sql, contains('WHERE uuid = @param_0'));
      expect(builder.parameters['param_0'], equals('func-uuid'));
    });

    test('should build UPDATE query with multiple WHERE clauses', () {
      final builder = QueryBuilder()
          .table('functions')
          .where('user_id', 123)
          .where('status', 'active');
      final sql = builder.buildUpdate({'status': 'archived'});

      expect(sql, contains('WHERE user_id = @param_0 AND status = @param_1'));
    });
  });

  group('QueryBuilder - DELETE queries', () {
    test('should build DELETE query', () {
      final builder = QueryBuilder().table('users').where('id', 123);
      final sql = builder.buildDelete();

      expect(sql, equals('DELETE FROM users WHERE id = @param_0'));
      expect(builder.parameters['param_0'], equals(123));
    });

    test('should build DELETE query with multiple WHERE clauses', () {
      final builder = QueryBuilder()
          .table('function_logs')
          .where('function_id', 456)
          .where('level', 'debug');
      final sql = builder.buildDelete();

      expect(
        sql,
        equals(
          'DELETE FROM function_logs WHERE function_id = @param_0 AND level = @param_1',
        ),
      );
      expect(builder.parameters['param_0'], equals(456));
      expect(builder.parameters['param_1'], equals('debug'));
    });

    test('should build DELETE query without WHERE (dangerous!)', () {
      final builder = QueryBuilder().table('temp_data');
      final sql = builder.buildDelete();

      expect(sql, equals('DELETE FROM temp_data'));
    });
  });

  group('QueryBuilder - Error handling', () {
    test('should throw error when building SELECT without table', () {
      final builder = QueryBuilder();
      expect(() => builder.buildSelect(), throwsStateError);
    });

    test('should throw error when building INSERT without table', () {
      final builder = QueryBuilder();
      expect(() => builder.buildInsert({'col': 'val'}), throwsStateError);
    });

    test('should throw error when building UPDATE without table', () {
      final builder = QueryBuilder();
      expect(() => builder.buildUpdate({'col': 'val'}), throwsStateError);
    });

    test('should throw error when building DELETE without table', () {
      final builder = QueryBuilder();
      expect(() => builder.buildDelete(), throwsStateError);
    });
  });

  group('QueryBuilder - Parameter handling', () {
    test('should generate unique parameter names', () {
      final builder = QueryBuilder()
          .table('users')
          .where('email', 'test1@example.com')
          .where('status', 'active')
          .where('created_at', DateTime(2024, 1, 1), operator: '>');

      expect(
        builder.parameters.keys,
        containsAll(['param_0', 'param_1', 'param_2']),
      );
      expect(builder.parameters['param_0'], equals('test1@example.com'));
      expect(builder.parameters['param_1'], equals('active'));
      expect(builder.parameters['param_2'], equals(DateTime(2024, 1, 1)));
    });

    test('should handle null values in parameters', () {
      final builder = QueryBuilder()
          .table('functions')
          .where('active_deployment_id', null);
      final sql = builder.buildSelect();

      expect(sql, contains('active_deployment_id = @param_0'));
      expect(builder.parameters['param_0'], isNull);
    });
  });

  group('QueryBuilder - Chaining', () {
    test('should support method chaining', () {
      final builder = QueryBuilder()
          .table('functions')
          .select(['id', 'name'])
          .where('status', 'active')
          .orderBy('created_at', direction: 'DESC')
          .limit(10)
          .offset(20);

      expect(builder, isA<QueryBuilder>());
      final sql = builder.buildSelect();
      expect(sql, contains('SELECT id, name FROM functions'));
      expect(sql, contains('WHERE status = @param_0'));
      expect(sql, contains('ORDER BY created_at DESC'));
      expect(sql, contains('LIMIT 10'));
      expect(sql, contains('OFFSET 20'));
    });
  });
}
