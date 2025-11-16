---
title: Database Quick Reference
description: Quick reference guide for common database operations
---

# Database Quick Reference

Quick reference for the most common database operations in ContainerPub backend.

## Import

```dart
import 'package:database/database.dart';
```

## Managers

```dart
DatabaseManagers.users
DatabaseManagers.functions
DatabaseManagers.functionDeployments
DatabaseManagers.functionLogs
DatabaseManagers.functionInvocations
```

## Common Operations

### Find by UUID

```dart
final user = await DatabaseManagers.users.findByUuid('user-uuid');
final function = await DatabaseManagers.functions.findByUuid('func-uuid');
```

### Find by ID

```dart
final user = await DatabaseManagers.users.findById(123);
```

### Find All with Filters

```dart
final functions = await DatabaseManagers.functions.findAll(
  where: {'user_id': userId, 'status': 'active'},
  orderBy: 'created_at',
  orderDirection: 'DESC',
  limit: 20,
  offset: 0,
);
```

### Find One

```dart
final function = await DatabaseManagers.functions.findOne(
  where: {'name': 'my-function', 'user_id': userId},
);
```

### Insert

```dart
final user = await DatabaseManagers.users.insert({
  'email': 'user@example.com',
  'password_hash': hashedPassword,
});

final function = await DatabaseManagers.functions.insert({
  'user_id': userId,
  'name': 'my-function',
  'status': 'active',
});
```

### Update by ID

```dart
await DatabaseManagers.functions.updateById(
  functionId,
  {'status': 'inactive', 'updated_at': DateTime.now()},
);
```

### Update with Conditions

```dart
await DatabaseManagers.functions.update(
  {'status': 'archived'},
  where: {'user_id': userId, 'status': 'inactive'},
);
```

### Delete by ID

```dart
await DatabaseManagers.functions.deleteById(functionId);
```

### Delete with Conditions

```dart
await DatabaseManagers.functionLogs.delete(
  where: {'function_id': functionId, 'level': 'debug'},
);
```

### Count

```dart
final count = await DatabaseManagers.functions.count(
  where: {'status': 'active'},
);
```

### Exists

```dart
final exists = await DatabaseManagers.functions.exists(
  where: {'name': 'my-function', 'user_id': userId},
);
```

## Query Builder

### Basic Query

```dart
final query = DatabaseManagers.functions.query()
  .where('status', 'active')
  .orderBy('created_at', direction: 'DESC')
  .limit(10);

final results = await DatabaseManagers.functions.executeQuery(query);
```

### Query with Multiple Conditions

```dart
final query = DatabaseManagers.functions.query()
  .where('user_id', userId)
  .where('status', 'active')
  .where('created_at', cutoffDate, operator: '>')
  .whereNotNull('active_deployment_id')
  .orderBy('name')
  .limit(50);
```

### Query with IN

```dart
final query = DatabaseManagers.functions.query()
  .whereIn('status', ['active', 'building', 'deployed']);
```

### Query with JOIN

```dart
final query = DatabaseManagers.functions.query()
  .select(['f.*', 'u.email'])
  .join('users u', 'f.user_id', 'u.id')
  .where('f.status', 'active');
```

### Query with Aggregation

```dart
final query = DatabaseManagers.functions.query()
  .select(['user_id', 'COUNT(*) as count'])
  .groupBy('user_id')
  .having('COUNT(*) > 5');
```

## Relationships

### One-to-Many (hasMany)

```dart
// Get all deployments for a function
final deployments = await DatabaseManagers.functionDeployments.hasMany(
  relatedTable: 'function_deployments',
  foreignKey: 'function_id',
  parentId: functionId,
  orderBy: 'version',
  orderDirection: 'DESC',
);
```

### Belongs-To

```dart
// Get user for a function
final user = await DatabaseManagers.users.findById(function.userId);
```

### JOIN Query

```dart
final results = await DatabaseManagers.functions.joinQuery(
  joinTable: 'users',
  joinCondition: 'functions.user_id = users.id',
  select: ['functions.*', 'users.email'],
  where: {'functions.status': 'active'},
);
```

## Raw SQL

### Query All Rows

```dart
final results = await Database.rawQueryAll(
  '''
  SELECT f.*, u.email
  FROM functions f
  JOIN users u ON f.user_id = u.id
  WHERE f.status = @status
  ''',
  parameters: {'status': 'active'},
);
```

### Query Single Row

```dart
final row = await Database.rawQuerySingle(
  'SELECT * FROM users WHERE email = @email',
  parameters: {'email': 'user@example.com'},
);
```

### Execute Statement

```dart
final affectedRows = await Database.rawExecute(
  'UPDATE functions SET status = @status WHERE user_id = @user_id',
  parameters: {'status': 'archived', 'user_id': userId},
);
```

## Transactions

```dart
await Database.transaction((connection) async {
  // Create function
  final functionResult = await connection.execute(
    Sql.named('INSERT INTO functions (user_id, name) VALUES (@user_id, @name) RETURNING id'),
    parameters: {'user_id': userId, 'name': 'my-function'},
  );
  
  final functionId = functionResult.first[0] as int;
  
  // Create deployment
  await connection.execute(
    Sql.named('INSERT INTO function_deployments (function_id, version) VALUES (@function_id, @version)'),
    parameters: {'function_id': functionId, 'version': 1},
  );
  
  // All or nothing - automatic rollback on error
});
```

## Batch Operations

```dart
final logsData = [
  {'function_id': funcId, 'level': 'info', 'message': 'Log 1'},
  {'function_id': funcId, 'level': 'error', 'message': 'Log 2'},
  {'function_id': funcId, 'level': 'warn', 'message': 'Log 3'},
];

await DatabaseManagers.functionLogs.batchInsert(logsData);
```

## Upsert

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

## Pagination

```dart
Future<PaginatedResult> getPaginated(int page, int pageSize) async {
  final offset = (page - 1) * pageSize;
  
  final total = await DatabaseManagers.functions.count();
  final items = await DatabaseManagers.functions.findAll(
    orderBy: 'created_at',
    orderDirection: 'DESC',
    limit: pageSize,
    offset: offset,
  );
  
  return PaginatedResult(
    items: items,
    total: total,
    page: page,
    pageSize: pageSize,
    hasMore: (page * pageSize) < total,
  );
}
```

## Common Patterns

### Get Function with User

```dart
final function = await DatabaseManagers.functions.findByUuid(funcUuid);
if (function != null) {
  final user = await DatabaseManagers.users.findById(function.userId!);
  // Use function and user
}
```

### Search by Name

```dart
final functions = await DatabaseManagers.functions.raw(
  'SELECT * FROM functions WHERE name ILIKE @pattern',
  parameters: {'pattern': '%$searchTerm%'},
);
```

### Get Recent Logs

```dart
final logs = await DatabaseManagers.functionLogs.findAll(
  where: {'function_id': functionId},
  orderBy: 'timestamp',
  orderDirection: 'DESC',
  limit: 50,
);
```

### Get Active Deployment

```dart
final deployment = await DatabaseManagers.functionDeployments.findOne(
  where: {'function_id': functionId, 'is_active': true},
);
```

### Analytics Query

```dart
final stats = await Database.rawQuerySingle(
  '''
  SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN status = 'success' THEN 1 END) as successful,
    AVG(duration_ms) as avg_duration
  FROM function_invocations
  WHERE function_id = @function_id
  AND timestamp >= @since
  ''',
  parameters: {
    'function_id': functionId,
    'since': DateTime.now().subtract(Duration(days: 30)),
  },
);
```

## Entity Usage

### Create Entity

```dart
final user = UserEntity(
  email: 'user@example.com',
  passwordHash: hashedPassword,
);

// Insert
final inserted = await DatabaseManagers.users.insert(user.toMap());
```

### Update Entity

```dart
final updated = function.copyWith(status: 'inactive');
await DatabaseManagers.functions.updateById(
  function.id!,
  updated.toMap(),
);
```

### Convert from Database

```dart
final row = await Database.rawQuerySingle('SELECT * FROM users WHERE id = @id', parameters: {'id': 123});
final user = UserEntity.fromMap(row!);
```

## Error Handling

```dart
try {
  final user = await DatabaseManagers.users.findByUuid(uuid);
  if (user == null) {
    throw Exception('User not found');
  }
  // Use user
} on PostgreSQLException catch (e) {
  print('Database error: ${e.message}');
  rethrow;
} catch (e) {
  print('Unexpected error: $e');
  rethrow;
}
```

## Performance Tips

### ✅ DO

```dart
// Use specific columns
final query = manager.query()
  .select(['id', 'name', 'status'])
  .limit(20);

// Use indexes
.where('user_id', userId)  // Indexed column

// Paginate
.limit(20).offset(0)

// Batch operations
await manager.batchInsert(dataList);
```

### ❌ DON'T

```dart
// Don't fetch all records
final all = await manager.findAll();  // No limit!

// Don't use SELECT *
// Use specific columns instead

// Don't query in loops
for (var id in ids) {
  await manager.findById(id);  // N+1 problem
}

// Use whereIn instead:
final query = manager.query().whereIn('id', ids);
```

## Security

### Always Use Parameters

```dart
// ✅ Safe
.where('email', userInput)

// ❌ Dangerous - SQL injection!
.whereRaw("email = '$userInput'")
```

### Use UUIDs in API

```dart
// ✅ Expose UUIDs
return {'id': function.uuid};

// ❌ Don't expose internal IDs
return {'id': function.id};  // Allows enumeration
```

## Testing

```bash
# Run all tests
dart test

# Run specific test file
dart test test/query_builder_test.dart

# Run with coverage
./test_runner.sh coverage
```

## Debugging

### Print Generated SQL

```dart
final query = manager.query().where('status', 'active');
final sql = query.buildSelect();
print('SQL: $sql');
print('Parameters: ${query.parameters}');
```

### Check Query Results

```dart
final results = await manager.findAll(where: {'status': 'active'});
print('Found ${results.length} results');
```

## Common Errors

### "Table name is required"
```dart
// ❌ Missing table
final builder = QueryBuilder();
builder.buildSelect();  // Error!

// ✅ Set table
final builder = QueryBuilder().table('users');
```

### "Parameter not found"
```dart
// Make sure parameter names match
final sql = 'SELECT * FROM users WHERE id = @user_id';
final params = {'user_id': 123};  // Must match @user_id
```

### "Column not found"
```dart
// Check column names (snake_case in DB)
.where('user_id', userId)  // ✅ Correct
.where('userId', userId)   // ❌ Wrong
```

## Resources

- **Full Documentation**: `database/README.md`
- **Examples**: `database/EXAMPLES.md`
- **Migration Guide**: `database/MIGRATION_GUIDE.md`
- **Testing**: `database/TESTING.md`
- **Internal Docs**: `docs_site/dev_docs/content/docs/database-system.md`

---

**Quick Links**:
- [Database System Overview](database-system.md)
- [Implementation Tracking](database-implementation-tracking.md)
- [API Reference](api-reference.md)
