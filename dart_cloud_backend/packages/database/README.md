# Database Package

A comprehensive database management package with entity-based query management, query builder, and raw SQL support for PostgreSQL.

## Features

- **Entity-Based Management**: Type-safe entity models for all database tables
- **Query Builder**: Fluent API for constructing SQL queries
- **DatabaseManagerQuery**: CRUD operations with relationship support
- **Raw SQL Support**: Direct SQL execution for complex queries
- **Relationship Queries**: HasMany, BelongsTo, and ManyToMany relationships
- **Transaction Support**: Built-in transaction management
- **Batch Operations**: Efficient batch inserts and updates
- **Legacy Support**: Backward compatible with QueryHelpers

## Getting Started

Initialize the database connection:

```dart
import 'package:database/database.dart';

await Database.initialize('postgresql://user:password@localhost:5432/dbname');
```

## Usage

### 1. Entity-Based Queries

Use `DatabaseManagers` for type-safe CRUD operations:

```dart
import 'package:database/database.dart';

// Find user by UUID
final user = await DatabaseManagers.users.findByUuid('user-uuid');

// Find all functions for a user
final functions = await DatabaseManagers.functions.findAll(
  where: {'user_id': userId},
  orderBy: 'created_at',
  orderDirection: 'DESC',
  limit: 10,
);

// Insert a new function
final newFunction = await DatabaseManagers.functions.insert({
  'user_id': userId,
  'name': 'my-function',
  'status': 'active',
});

// Update a function
await DatabaseManagers.functions.updateById(
  functionId,
  {'status': 'inactive'},
);

// Delete a function
await DatabaseManagers.functions.deleteById(functionId);

// Count records
final count = await DatabaseManagers.functions.count(
  where: {'status': 'active'},
);
```

### 2. Query Builder

Build complex queries with the fluent API:

```dart
// Custom query with joins
final manager = DatabaseManagers.functions;
final query = manager.query()
  .select(['f.*', 'u.email'])
  .join('users u', 'f.user_id', 'u.id')
  .where('f.status', 'active')
  .where('u.email', 'user@example.com', operator: 'LIKE')
  .orderBy('f.created_at', direction: 'DESC')
  .limit(10);

final results = await manager.executeQuery(query);

// WHERE IN clause
final query2 = manager.query()
  .whereIn('status', ['active', 'building', 'deployed']);

// Complex conditions
final query3 = manager.query()
  .where('created_at', DateTime.now().subtract(Duration(days: 7)), operator: '>')
  .whereNotNull('active_deployment_id')
  .orderBy('created_at', direction: 'DESC');
```

### 3. Relationship Queries

Query related records across tables:

```dart
// One-to-Many: Get all deployments for a function
final deployments = await DatabaseManagers.functionDeployments.hasMany(
  relatedTable: 'function_deployments',
  foreignKey: 'function_id',
  parentId: functionId,
  orderBy: 'version',
  orderDirection: 'DESC',
);

// Belongs-To: Get user for a function
final userData = await DatabaseManagers.functions.belongsTo(
  relatedTable: 'users',
  foreignKey: 'user_id',
  foreignKeyValue: function.userId,
);

// Many-to-Many example (if you have pivot tables)
final related = await DatabaseManagers.functions.manyToMany(
  relatedTable: 'tags',
  pivotTable: 'function_tags',
  foreignKey: 'function_id',
  relatedKey: 'tag_id',
  parentId: functionId,
);
```

### 4. Raw SQL Queries

Execute raw SQL for complex operations:

```dart
// Using Database class
final results = await Database.rawQueryAll(
  '''
  SELECT f.*, COUNT(fd.id) as deployment_count
  FROM functions f
  LEFT JOIN function_deployments fd ON f.id = fd.function_id
  WHERE f.user_id = @user_id
  GROUP BY f.id
  HAVING COUNT(fd.id) > @min_deployments
  ''',
  parameters: {
    'user_id': userId,
    'min_deployments': 5,
  },
);

// Single row query
final row = await Database.rawQuerySingle(
  'SELECT * FROM users WHERE email = @email',
  parameters: {'email': 'user@example.com'},
);

// Execute statement (INSERT, UPDATE, DELETE)
final affectedRows = await Database.rawExecute(
  'UPDATE functions SET status = @status WHERE user_id = @user_id',
  parameters: {'status': 'archived', 'user_id': userId},
);

// Using manager's raw method (returns entities)
final functions = await DatabaseManagers.functions.raw(
  'SELECT * FROM functions WHERE status = @status',
  parameters: {'status': 'active'},
);
```

### 5. Transactions

Execute multiple operations atomically:

```dart
// Using Database class
await Database.transaction((connection) async {
  await connection.execute('INSERT INTO users ...');
  await connection.execute('INSERT INTO functions ...');
  // If any operation fails, all changes are rolled back
});

// Using DatabaseManagerQuery
await DatabaseManagerQuery.transaction((connection) async {
  // Perform multiple operations
});
```

### 6. Batch Operations

Efficiently insert multiple records:

```dart
final logsData = [
  {'function_id': funcId, 'level': 'info', 'message': 'Log 1'},
  {'function_id': funcId, 'level': 'error', 'message': 'Log 2'},
  {'function_id': funcId, 'level': 'warn', 'message': 'Log 3'},
];

await DatabaseManagers.functionLogs.batchInsert(logsData);
```

### 7. Upsert Operations

Insert or update on conflict:

```dart
final function = await DatabaseManagers.functions.upsert(
  {
    'user_id': userId,
    'name': 'my-function',
    'status': 'active',
  },
  conflictColumns: ['user_id', 'name'],
  updateColumns: ['status', 'updated_at'],
);
```

### 8. Working with Entities

Create and manipulate entity objects:

```dart
// Create entity
final user = UserEntity(
  email: 'user@example.com',
  passwordHash: hashedPassword,
);

// Convert to map for database operations
final userMap = user.toMap();

// Create from database result
final userFromDb = UserEntity.fromMap(dbRow);

// Copy with modifications
final updatedUser = user.copyWith(
  email: 'newemail@example.com',
);
```

## Entity Models

Available entity models:
- `UserEntity` - users table
- `FunctionEntity` - functions table
- `FunctionDeploymentEntity` - function_deployments table
- `FunctionLogEntity` - function_logs table
- `FunctionInvocationEntity` - function_invocations table

## Database Managers

Access pre-configured managers:
- `DatabaseManagers.users`
- `DatabaseManagers.functions`
- `DatabaseManagers.functionDeployments`
- `DatabaseManagers.functionLogs`
- `DatabaseManagers.functionInvocations`

## Legacy Support

The package maintains backward compatibility with `QueryHelpers`:

```dart
// Old API still works
final user = await QueryHelpers.getUserByUuid(uuid);
final functions = await QueryHelpers.getFunctionsByUserUuid(userUuid);
```

## Advanced Features

### Custom Managers

Create custom managers for your own entities:

```dart
final customManager = DatabaseManagerQuery<MyEntity>(
  tableName: 'my_table',
  fromMap: MyEntity.fromMap,
);
```

### Join Queries

Perform complex joins:

```dart
final results = await DatabaseManagers.functions.joinQuery(
  joinTable: 'users',
  joinCondition: 'functions.user_id = users.id',
  select: ['functions.*', 'users.email'],
  where: {'functions.status': 'active'},
  joinType: 'LEFT',
);
```

## API Reference

### DatabaseManagerQuery Methods

- `findById(id)` - Find by ID
- `findByUuid(uuid)` - Find by UUID
- `findAll({where, orderBy, limit, offset})` - Find multiple records
- `findOne({where})` - Find first matching record
- `insert(data)` - Insert new record
- `update(data, {where})` - Update records
- `updateById(id, data)` - Update by ID
- `delete({where})` - Delete records
- `deleteById(id)` - Delete by ID
- `count({where})` - Count records
- `exists({where})` - Check if records exist
- `raw(sql, {parameters})` - Execute raw SQL
- `hasMany(...)` - One-to-many relationship
- `belongsTo(...)` - Belongs-to relationship
- `manyToMany(...)` - Many-to-many relationship
- `batchInsert(dataList)` - Batch insert
- `upsert(data, {conflictColumns})` - Insert or update

### Database Static Methods

- `initialize(databaseUrl)` - Initialize connection
- `rawQuery(sql, {parameters})` - Execute raw query
- `rawQuerySingle(sql, {parameters})` - Get single row
- `rawQueryAll(sql, {parameters})` - Get all rows
- `rawExecute(sql, {parameters})` - Execute statement
- `transaction(callback)` - Run transaction
- `batchExecute(queries)` - Execute multiple queries
- `close()` - Close connection

## Best Practices

1. **Use Entity Managers** for standard CRUD operations
2. **Use Query Builder** for complex queries with joins and conditions
3. **Use Raw SQL** only for very complex queries or performance-critical operations
4. **Always use transactions** for operations that modify multiple tables
5. **Use batch operations** for inserting/updating multiple records
6. **Leverage relationships** instead of manual joins when possible

## Migration from QueryHelpers

If you're using the old `QueryHelpers` API:

```dart
// Old way
final user = await QueryHelpers.getUserByUuid(uuid);

// New way (recommended)
final user = await DatabaseManagers.users.findByUuid(uuid);

// Old way
final functions = await QueryHelpers.getFunctionsByUserUuid(userUuid);

// New way (recommended)
final functions = await DatabaseManagers.functions.findAll(
  where: {'user_id': userId},
);
```

Both APIs work, but the new entity-based approach provides better type safety and more features.
