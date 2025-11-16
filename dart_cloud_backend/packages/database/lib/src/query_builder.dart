import 'package:postgres/postgres.dart';

/// Query builder for constructing SQL queries
class QueryBuilder {
  String? _table;
  final List<String> _select = [];
  final List<String> _joins = [];
  final List<String> _where = [];
  final Map<String, dynamic> _parameters = {};
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;
  String? _groupBy;
  final List<String> _having = [];

  int _paramCounter = 0;

  QueryBuilder();

  /// Set the table to query from
  QueryBuilder table(String tableName) {
    _table = tableName;
    return this;
  }

  /// Add columns to select
  QueryBuilder select(List<String> columns) {
    _select.addAll(columns);
    return this;
  }

  /// Add a WHERE clause
  QueryBuilder where(String column, dynamic value, {String operator = '='}) {
    final paramName = 'param_${_paramCounter++}';
    _where.add('$column $operator @$paramName');
    _parameters[paramName] = value;
    return this;
  }

  /// Add a WHERE IN clause
  QueryBuilder whereIn(String column, List<dynamic> values) {
    final paramName = 'param_${_paramCounter++}';
    _where.add('$column = ANY(@$paramName)');
    _parameters[paramName] = values;
    return this;
  }

  /// Add a WHERE NULL clause
  QueryBuilder whereNull(String column) {
    _where.add('$column IS NULL');
    return this;
  }

  /// Add a WHERE NOT NULL clause
  QueryBuilder whereNotNull(String column) {
    _where.add('$column IS NOT NULL');
    return this;
  }

  /// Add a raw WHERE clause
  QueryBuilder whereRaw(String condition, Map<String, dynamic>? params) {
    _where.add(condition);
    if (params != null) {
      _parameters.addAll(params);
    }
    return this;
  }

  /// Add an OR WHERE clause
  QueryBuilder orWhere(String column, dynamic value, {String operator = '='}) {
    final paramName = 'param_${_paramCounter++}';
    if (_where.isEmpty) {
      _where.add('$column $operator @$paramName');
    } else {
      _where.add('OR $column $operator @$paramName');
    }
    _parameters[paramName] = value;
    return this;
  }

  /// Add a JOIN clause
  QueryBuilder join(
    String table,
    String firstColumn,
    String secondColumn, {
    String type = 'INNER',
  }) {
    _joins.add('$type JOIN $table ON $firstColumn = $secondColumn');
    return this;
  }

  /// Add a LEFT JOIN clause
  QueryBuilder leftJoin(String table, String firstColumn, String secondColumn) {
    return join(table, firstColumn, secondColumn, type: 'LEFT');
  }

  /// Add a RIGHT JOIN clause
  QueryBuilder rightJoin(
    String table,
    String firstColumn,
    String secondColumn,
  ) {
    return join(table, firstColumn, secondColumn, type: 'RIGHT');
  }

  /// Add an ORDER BY clause
  QueryBuilder orderBy(String column, {String direction = 'ASC'}) {
    _orderBy.add('$column $direction');
    return this;
  }

  /// Add a GROUP BY clause
  QueryBuilder groupBy(String column) {
    _groupBy = column;
    return this;
  }

  /// Add a HAVING clause
  QueryBuilder having(String condition) {
    _having.add(condition);
    return this;
  }

  /// Set LIMIT
  QueryBuilder limit(int count) {
    _limit = count;
    return this;
  }

  /// Set OFFSET
  QueryBuilder offset(int count) {
    _offset = count;
    return this;
  }

  /// Build the SELECT query
  String buildSelect() {
    if (_table == null) {
      throw StateError('Table name is required');
    }

    final buffer = StringBuffer();

    // SELECT clause
    if (_select.isEmpty) {
      buffer.write('SELECT * FROM $_table');
    } else {
      buffer.write('SELECT ${_select.join(', ')} FROM $_table');
    }

    // JOIN clauses
    if (_joins.isNotEmpty) {
      buffer.write(' ${_joins.join(' ')}');
    }

    // WHERE clause
    if (_where.isNotEmpty) {
      final whereClause = _where
          .asMap()
          .map(
            (index, whereClauseElement) => MapEntry(
              index,
              index == 0
                  ? whereClauseElement
                  : whereClauseElement.startsWith('OR')
                  ? whereClauseElement
                  : 'AND $whereClauseElement',
            ),
          )
          .values
          .join(' ');
      buffer.write(' WHERE $whereClause');
    }

    // GROUP BY clause
    if (_groupBy != null) {
      buffer.write(' GROUP BY $_groupBy');
    }

    // HAVING clause
    if (_having.isNotEmpty) {
      buffer.write(' HAVING ${_having.join(' AND ')}');
    }

    // ORDER BY clause
    if (_orderBy.isNotEmpty) {
      buffer.write(' ORDER BY ${_orderBy.join(', ')}');
    }

    // LIMIT clause
    if (_limit != null) {
      buffer.write(' LIMIT $_limit');
    }

    // OFFSET clause
    if (_offset != null) {
      buffer.write(' OFFSET $_offset');
    }

    return buffer.toString();
  }

  /// Build an INSERT query
  String buildInsert(Map<String, dynamic> data) {
    if (_table == null) {
      throw StateError('Table name is required');
    }

    final columns = data.keys.toList();
    final paramNames = <String>[];

    for (var i = 0; i < columns.length; i++) {
      final paramName = 'param_${_paramCounter++}';
      paramNames.add('@$paramName');
      _parameters[paramName] = data[columns[i]];
    }

    return '''
      INSERT INTO $_table (${columns.join(', ')})
      VALUES (${paramNames.join(', ')})
      RETURNING *
    ''';
  }

  /// Build an UPDATE query
  String buildUpdate(Map<String, dynamic> data) {
    if (_table == null) {
      throw StateError('Table name is required');
    }

    final setClauses = <String>[];
    for (final entry in data.entries) {
      final paramName = 'param_${_paramCounter++}';
      setClauses.add('${entry.key} = @$paramName');
      _parameters[paramName] = entry.value;
    }

    final buffer = StringBuffer();
    buffer.write('UPDATE $_table SET ${setClauses.join(', ')}');

    if (_where.isNotEmpty) {
      buffer.write(' WHERE ${_where.join(' AND ')}');
    }

    buffer.write(' RETURNING *');

    return buffer.toString();
  }

  /// Build a DELETE query
  String buildDelete() {
    if (_table == null) {
      throw StateError('Table name is required');
    }

    final buffer = StringBuffer();
    buffer.write('DELETE FROM $_table');

    if (_where.isNotEmpty) {
      buffer.write(' WHERE ${_where.join(' AND ')}');
    }

    return buffer.toString();
  }

  /// Get the parameters map
  Map<String, dynamic> get parameters => _parameters;

  /// Create a Sql.named object for postgres package
  Sql toSql(String query) {
    return Sql.named(query);
  }
}
