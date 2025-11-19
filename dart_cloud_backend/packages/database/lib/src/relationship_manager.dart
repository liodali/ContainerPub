import 'package:database/database.dart' show Database;
import 'package:postgres/postgres.dart';

/// Relationship manager mixin for handling complex queries with joins
mixin RelationshipManager {
  /// Execute a query with multiple joins and return raw results
  Future<List<Map<String, dynamic>>> executeJoinQuery({
    required String baseTable,
    required List<JoinConfig> joins,
    List<String>? select,
    Map<String, dynamic>? where,
    String? orderBy,
    String orderDirection = 'ASC',
    int? limit,
    int? offset,
  }) async {
    final selectClause = select?.join(', ') ?? '*';
    final joinClauses = joins.map((j) => j.toSql()).join(' ');

    final whereClauses = <String>[];
    final parameters = <String, dynamic>{};

    if (where != null) {
      var paramIndex = 0;
      for (final entry in where.entries) {
        final paramName = 'param_$paramIndex';
        whereClauses.add('${entry.key} = @$paramName');
        parameters[paramName] = entry.value;
        paramIndex++;
      }
    }

    final whereClause = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final orderClause = orderBy != null
        ? 'ORDER BY $orderBy $orderDirection'
        : '';

    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final sql =
        '''
      SELECT $selectClause
      FROM $baseTable
      $joinClauses
      $whereClause
      $orderClause
      $limitClause
      $offsetClause
    ''';

    final result = await Database.connection.execute(
      Sql.named(sql),
      parameters: parameters,
    );

    return result.map((row) => _rowToMap(row)).toList();
  }

  /// Execute a query to get one-to-one relationship
  Future<Map<String, dynamic>?> getOneToOne({
    required String baseTable,
    required String relatedTable,
    required String baseKey,
    required String relatedKey,
    required dynamic keyValue,
    List<String>? select,
  }) async {
    final results = await executeJoinQuery(
      baseTable: baseTable,
      joins: [
        JoinConfig(
          table: relatedTable,
          on: '$baseTable.$baseKey = $relatedTable.$relatedKey',
          type: JoinType.inner,
        ),
      ],
      select: select,
      where: {'$baseTable.$baseKey': keyValue},
      limit: 1,
    );

    return results.isEmpty ? null : results.first;
  }

  /// Execute a query to get one-to-many relationship
  Future<List<Map<String, dynamic>>> getOneToMany({
    required String baseTable,
    required String relatedTable,
    required String foreignKey,
    required dynamic parentId,
    List<String>? select,
    String? orderBy,
    String orderDirection = 'ASC',
  }) async {
    return await executeJoinQuery(
      baseTable: relatedTable,
      joins: [
        JoinConfig(
          table: baseTable,
          on: '$relatedTable.$foreignKey = $baseTable.id',
          type: JoinType.inner,
        ),
      ],
      select: select,
      where: {'$baseTable.id': parentId},
      orderBy: orderBy,
      orderDirection: orderDirection,
    );
  }

  /// Execute a query to get many-to-many relationship
  Future<List<Map<String, dynamic>>> getManyToMany({
    required String baseTable,
    required String relatedTable,
    required String pivotTable,
    required String baseForeignKey,
    required String relatedForeignKey,
    required dynamic baseId,
    List<String>? select,
    String? orderBy,
    String orderDirection = 'ASC',
  }) async {
    return await executeJoinQuery(
      baseTable: baseTable,
      joins: [
        JoinConfig(
          table: pivotTable,
          on: '$baseTable.id = $pivotTable.$baseForeignKey',
          type: JoinType.inner,
        ),
        JoinConfig(
          table: relatedTable,
          on: '$pivotTable.$relatedForeignKey = $relatedTable.id',
          type: JoinType.inner,
        ),
      ],
      select: select,
      where: {'$baseTable.id': baseId},
      orderBy: orderBy,
      orderDirection: orderDirection,
    );
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
}

/// Join configuration for building complex queries
class JoinConfig {
  final String table;
  final String on;
  final JoinType type;
  final String? alias;

  JoinConfig({
    required this.table,
    required this.on,
    this.type = JoinType.inner,
    this.alias,
  });

  String toSql() {
    final tableRef = alias != null ? '$table AS $alias' : table;
    return '${type.sql} JOIN $tableRef ON $on';
  }
}

/// Join types
enum JoinType {
  inner('INNER'),
  left('LEFT'),
  right('RIGHT'),
  full('FULL')
  ;

  const JoinType(this.sql);
  final String sql;
}
