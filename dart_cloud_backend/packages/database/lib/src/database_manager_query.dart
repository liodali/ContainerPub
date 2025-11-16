import 'package:database/database.dart' show Database;
import 'package:postgres/postgres.dart';
import 'entity.dart';
import 'query_builder.dart';

/// Database manager with query builder support
class DatabaseManagerQuery<T extends Entity> {
  final String tableName;
  final T Function(Map<String, dynamic>) fromMap;

  DatabaseManagerQuery({
    required this.tableName,
    required this.fromMap,
  });

  /// Create a new query builder
  QueryBuilder query() {
    return QueryBuilder().table(tableName);
  }

  /// Find a single record by ID
  Future<T?> findById(dynamic id, {String idColumn = 'id'}) async {
    final builder = query().where(idColumn, id).limit(1);
    final result = await Database.connection.execute(
      builder.toSql(builder.buildSelect()),
      parameters: builder.parameters,
    );

    if (result.isEmpty) return null;
    return fromMap(_rowToMap(result.first));
  }

  /// Find a single record by UUID
  Future<T?> findByUuid(String uuid) async {
    return findById(uuid, idColumn: 'uuid');
  }

  /// Find all records matching the query
  Future<List<T>> findAll({
    Map<String, dynamic>? where,
    String? orderBy,
    String orderDirection = 'ASC',
    int? limit,
    int? offset,
  }) async {
    final builder = query();

    if (where != null) {
      for (final entry in where.entries) {
        builder.where(entry.key, entry.value);
      }
    }

    if (orderBy != null) {
      builder.orderBy(orderBy, direction: orderDirection);
    }

    if (limit != null) {
      builder.limit(limit);
    }

    if (offset != null) {
      builder.offset(offset);
    }

    final result = await Database.connection.execute(
      builder.toSql(builder.buildSelect()),
      parameters: builder.parameters,
    );

    return result.map((row) => fromMap(_rowToMap(row))).toList();
  }

  /// Find first record matching the query
  Future<T?> findOne({Map<String, dynamic>? where}) async {
    final results = await findAll(where: where, limit: 1);
    return results.isEmpty ? null : results.first;
  }

  /// Insert a new record
  Future<T> insert(Map<String, dynamic> data) async {
    final builder = query();
    final sql = builder.buildInsert(data);

    final result = await Database.connection.execute(
      builder.toSql(sql),
      parameters: builder.parameters,
    );

    return fromMap(_rowToMap(result.first));
  }

  /// Update records matching the query
  Future<List<T>> update(
    Map<String, dynamic> data, {
    Map<String, dynamic>? where,
  }) async {
    final builder = query();

    if (where != null) {
      for (final entry in where.entries) {
        builder.where(entry.key, entry.value);
      }
    }

    final sql = builder.buildUpdate(data);

    final result = await Database.connection.execute(
      builder.toSql(sql),
      parameters: builder.parameters,
    );

    return result.map((row) => fromMap(_rowToMap(row))).toList();
  }

  /// Update a single record by ID
  Future<T?> updateById(
    dynamic id,
    Map<String, dynamic> data, {
    String idColumn = 'id',
  }) async {
    final results = await update(data, where: {idColumn: id});
    return results.isEmpty ? null : results.first;
  }

  /// Delete records matching the query
  Future<int> delete({Map<String, dynamic>? where}) async {
    final builder = query();

    if (where != null) {
      for (final entry in where.entries) {
        builder.where(entry.key, entry.value);
      }
    }

    final sql = builder.buildDelete();

    final result = await Database.connection.execute(
      builder.toSql(sql),
      parameters: builder.parameters,
    );

    return result.affectedRows;
  }

  /// Delete a single record by ID
  Future<bool> deleteById(dynamic id, {String idColumn = 'id'}) async {
    final count = await delete(where: {idColumn: id});
    return count > 0;
  }

  /// Count records matching the query
  Future<int> count({Map<String, dynamic>? where}) async {
    final builder = query().select(['COUNT(*) as count']);

    if (where != null) {
      for (final entry in where.entries) {
        builder.where(entry.key, entry.value);
      }
    }

    final result = await Database.connection.execute(
      builder.toSql(builder.buildSelect()),
      parameters: builder.parameters,
    );

    return result.first[0] as int;
  }

  /// Check if any records exist matching the query
  Future<bool> exists({Map<String, dynamic>? where}) async {
    final count = await this.count(where: where);
    return count > 0;
  }

  /// Execute a custom query with the query builder
  Future<List<T>> executeQuery(QueryBuilder builder) async {
    final result = await Database.connection.execute(
      builder.toSql(builder.buildSelect()),
      parameters: builder.parameters,
    );

    return result.map((row) => fromMap(_rowToMap(row))).toList();
  }

  /// Execute a raw SQL query and return entities
  Future<List<T>> raw(String sql, {Map<String, dynamic>? parameters}) async {
    final result = await Database.connection.execute(
      Sql.named(sql),
      parameters: parameters ?? {},
    );

    return result.map((row) => fromMap(_rowToMap(row))).toList();
  }

  /// Execute a raw SQL query and return raw results
  Future<Result> rawQuery(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    return await Database.connection.execute(
      Sql.named(sql),
      parameters: parameters ?? {},
    );
  }

  /// Perform a JOIN query with another table
  Future<List<Map<String, dynamic>>> joinQuery({
    required String joinTable,
    required String joinCondition,
    List<String>? select,
    Map<String, dynamic>? where,
    String joinType = 'INNER',
  }) async {
    final builder = query();

    if (select != null) {
      builder.select(select);
    }

    builder.join(
      joinTable,
      joinCondition.split('=')[0].trim(),
      joinCondition.split('=')[1].trim(),
      type: joinType,
    );

    if (where != null) {
      for (final entry in where.entries) {
        builder.where(entry.key, entry.value);
      }
    }

    final result = await Database.connection.execute(
      builder.toSql(builder.buildSelect()),
      parameters: builder.parameters,
    );

    return result.map((row) => _rowToMap(row)).toList();
  }

  /// Get related records (one-to-many)
  Future<List<Map<String, dynamic>>> hasMany({
    required String relatedTable,
    required String foreignKey,
    required dynamic parentId,
    String? orderBy,
    String orderDirection = 'ASC',
  }) async {
    final builder = QueryBuilder()
        .table(relatedTable)
        .where(foreignKey, parentId);

    if (orderBy != null) {
      builder.orderBy(orderBy, direction: orderDirection);
    }

    final result = await Database.connection.execute(
      builder.toSql(builder.buildSelect()),
      parameters: builder.parameters,
    );

    return result.map((row) => _rowToMap(row)).toList();
  }

  /// Get related record (belongs-to)
  Future<Map<String, dynamic>?> belongsTo({
    required String relatedTable,
    required String foreignKey,
    required dynamic foreignKeyValue,
  }) async {
    final builder = QueryBuilder()
        .table(relatedTable)
        .where('id', foreignKeyValue)
        .limit(1);

    final result = await Database.connection.execute(
      builder.toSql(builder.buildSelect()),
      parameters: builder.parameters,
    );

    if (result.isEmpty) return null;
    return _rowToMap(result.first);
  }

  /// Get related records (many-to-many)
  Future<List<Map<String, dynamic>>> manyToMany({
    required String relatedTable,
    required String pivotTable,
    required String foreignKey,
    required String relatedKey,
    required dynamic parentId,
  }) async {
    final sql =
        '''
      SELECT $relatedTable.*
      FROM $relatedTable
      INNER JOIN $pivotTable ON $relatedTable.id = $pivotTable.$relatedKey
      WHERE $pivotTable.$foreignKey = @parent_id
    ''';

    final result = await Database.connection.execute(
      Sql.named(sql),
      parameters: {'parent_id': parentId},
    );

    return result.map((row) => _rowToMap(row)).toList();
  }

  /// Convert a database row to a map
  Map<String, dynamic> _rowToMap(ResultRow row) {
    final map = <String, dynamic>{};
    for (var i = 0; i < row.length; i++) {
      final columnName = row.schema.columns[i].columnName ?? 'column_$i';
      map[columnName] = row[i];
    }
    return map;
  }

  /// Begin a transaction
  static Future<void> transaction(
    Future<void> Function(Connection connection) callback,
  ) async {
    await Database.connection.runTx((ctx) async {
      await callback(ctx as Connection);
    });
  }

  /// Batch insert multiple records
  Future<void> batchInsert(List<Map<String, dynamic>> dataList) async {
    await Database.connection.runTx((ctx) async {
      for (final data in dataList) {
        final builder = query();
        final sql = builder.buildInsert(data);
        await ctx.execute(
          builder.toSql(sql),
          parameters: builder.parameters,
        );
      }
    });
  }

  /// Upsert (insert or update on conflict)
  Future<T> upsert(
    Map<String, dynamic> data, {
    required List<String> conflictColumns,
    List<String>? updateColumns,
  }) async {
    final columns = data.keys.toList();
    final values = data.values.toList();
    final paramNames = <String>[];
    final parameters = <String, dynamic>{};

    for (var i = 0; i < columns.length; i++) {
      final paramName = 'param_$i';
      paramNames.add('@$paramName');
      parameters[paramName] = values[i];
    }

    final updateCols = updateColumns ?? columns;
    final updateSet = updateCols
        .where((col) => !conflictColumns.contains(col))
        .map((col) => '$col = EXCLUDED.$col')
        .join(', ');

    final sql =
        '''
      INSERT INTO $tableName (${columns.join(', ')})
      VALUES (${paramNames.join(', ')})
      ON CONFLICT (${conflictColumns.join(', ')})
      DO UPDATE SET $updateSet
      RETURNING *
    ''';

    final result = await Database.connection.execute(
      Sql.named(sql),
      parameters: parameters,
    );

    return fromMap(_rowToMap(result.first));
  }
}
