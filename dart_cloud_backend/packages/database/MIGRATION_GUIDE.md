# Migration Guide: From QueryHelpers to Entity-Based System

This guide helps you migrate from the legacy `QueryHelpers` API to the new entity-based database management system.

## Overview

The new system provides:
- **Type-safe entities** instead of raw maps
- **Query builder** for complex queries
- **Relationship support** for joins and related data
- **Better code organization** with managers
- **Backward compatibility** - old code still works!

## Quick Reference

| Old API | New API |
|---------|---------|
| `QueryHelpers.getUserByUuid(uuid)` | `DatabaseManagers.users.findByUuid(uuid)` |
| `QueryHelpers.getUserByEmail(email)` | `DatabaseManagers.users.findAll(where: {'email': email})` |
| `QueryHelpers.createUser(email, hash)` | `DatabaseManagers.users.insert({'email': email, 'password_hash': hash})` |
| `QueryHelpers.getFunctionByUuid(uuid)` | `DatabaseManagers.functions.findByUuid(uuid)` |
| `QueryHelpers.getFunctionsByUserUuid(uuid)` | `DatabaseManagers.functions.findAll(where: {'user_id': userId})` |
| `QueryHelpers.createFunction(...)` | `DatabaseManagers.functions.insert({...})` |
| `QueryHelpers.updateFunction(...)` | `DatabaseManagers.functions.updateById(id, {...})` |
| `QueryHelpers.deleteFunction(uuid)` | `DatabaseManagers.functions.deleteById(uuid, idColumn: 'uuid')` |

## Step-by-Step Migration

### 1. User Operations

#### Before (QueryHelpers)
```dart
// Get user by UUID
final userMap = await QueryHelpers.getUserByUuid(uuid);
if (userMap != null) {
  final email = userMap['email'] as String;
  final createdAt = userMap['created_at'] as DateTime;
}

// Get user by email
final userMap = await QueryHelpers.getUserByEmail(email);
if (userMap != null) {
  final passwordHash = userMap['password_hash'] as String;
}

// Create user
final uuid = await QueryHelpers.createUser(email, passwordHash);
```

#### After (Entity-Based)
```dart
// Get user by UUID - returns typed entity
final user = await DatabaseManagers.users.findByUuid(uuid);
if (user != null) {
  final email = user.email; // Type-safe!
  final createdAt = user.createdAt;
}

// Get user by email
final users = await DatabaseManagers.users.findAll(
  where: {'email': email},
  limit: 1,
);
final user = users.isNotEmpty ? users.first : null;
if (user != null) {
  final passwordHash = user.passwordHash;
}

// Create user - returns entity with UUID
final user = await DatabaseManagers.users.insert({
  'email': email,
  'password_hash': passwordHash,
});
final uuid = user.uuid;
```

### 2. Function Operations

#### Before (QueryHelpers)
```dart
// Get function
final funcMap = await QueryHelpers.getFunctionByUuid(uuid);
if (funcMap != null) {
  final name = funcMap['name'] as String;
  final status = funcMap['status'] as String;
  final userUuid = funcMap['user_uuid'] as String;
}

// Get user's functions
final functions = await QueryHelpers.getFunctionsByUserUuid(userUuid);
for (final func in functions) {
  print(func['name']);
}

// Create function
final uuid = await QueryHelpers.createFunction(
  userUuid: userUuid,
  name: 'my-function',
  status: 'active',
);

// Update function
final success = await QueryHelpers.updateFunction(
  uuid: uuid,
  name: 'new-name',
  status: 'inactive',
);

// Delete function
final success = await QueryHelpers.deleteFunction(uuid);
```

#### After (Entity-Based)
```dart
// Get function - typed entity
final function = await DatabaseManagers.functions.findByUuid(uuid);
if (function != null) {
  final name = function.name; // Type-safe
  final status = function.status;
  // Note: user_uuid not included in entity, need separate query
  final user = await DatabaseManagers.users.findById(function.userId!);
}

// Get user's functions
final functions = await DatabaseManagers.functions.findAll(
  where: {'user_id': userId},
  orderBy: 'created_at',
  orderDirection: 'DESC',
);
for (final func in functions) {
  print(func.name); // Type-safe
}

// Create function
final function = await DatabaseManagers.functions.insert({
  'user_id': userId,
  'name': 'my-function',
  'status': 'active',
});
final uuid = function.uuid;

// Update function
final updated = await DatabaseManagers.functions.updateById(
  functionId,
  {
    'name': 'new-name',
    'status': 'inactive',
  },
);

// Delete function
final success = await DatabaseManagers.functions.deleteById(
  uuid,
  idColumn: 'uuid',
);
```

### 3. Function Logs

#### Before (QueryHelpers)
```dart
// Get logs
final logs = await QueryHelpers.getFunctionLogsByFunctionUuid(
  functionUuid,
  limit: 50,
  offset: 0,
);

// Create log
final logUuid = await QueryHelpers.createFunctionLog(
  functionUuid: functionUuid,
  level: 'info',
  message: 'Log message',
);
```

#### After (Entity-Based)
```dart
// Get logs - more flexible
final logs = await DatabaseManagers.functionLogs.findAll(
  where: {'function_id': functionId},
  orderBy: 'timestamp',
  orderDirection: 'DESC',
  limit: 50,
  offset: 0,
);

// Filter by level
final errorLogs = await DatabaseManagers.functionLogs.findAll(
  where: {
    'function_id': functionId,
    'level': 'error',
  },
  limit: 50,
);

// Create log
final log = await DatabaseManagers.functionLogs.insert({
  'function_id': functionId,
  'level': 'info',
  'message': 'Log message',
});
final logUuid = log.uuid;
```

### 4. Function Invocations

#### Before (QueryHelpers)
```dart
// Get invocations
final invocations = await QueryHelpers.getFunctionInvocationsByFunctionUuid(
  functionUuid,
  limit: 100,
);

// Create invocation
final uuid = await QueryHelpers.createFunctionInvocation(
  functionUuid: functionUuid,
  status: 'success',
  durationMs: 150,
);
```

#### After (Entity-Based)
```dart
// Get invocations
final invocations = await DatabaseManagers.functionInvocations.findAll(
  where: {'function_id': functionId},
  orderBy: 'timestamp',
  orderDirection: 'DESC',
  limit: 100,
);

// Filter by status
final errors = await DatabaseManagers.functionInvocations.findAll(
  where: {
    'function_id': functionId,
    'status': 'error',
  },
);

// Create invocation
final invocation = await DatabaseManagers.functionInvocations.insert({
  'function_id': functionId,
  'status': 'success',
  'duration_ms': 150,
});
```

## New Capabilities

### 1. Query Builder for Complex Queries

```dart
// This wasn't possible with QueryHelpers!
final manager = DatabaseManagers.functions;
final query = manager.query()
  .select(['f.*', 'u.email'])
  .join('users u', 'f.user_id', 'u.id')
  .where('f.status', 'active')
  .where('f.created_at', cutoffDate, operator: '>')
  .orderBy('f.created_at', direction: 'DESC')
  .limit(10);

final results = await manager.executeQuery(query);
```

### 2. Relationship Queries

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

### 3. Batch Operations

```dart
// Insert multiple logs at once
await DatabaseManagers.functionLogs.batchInsert([
  {'function_id': funcId, 'level': 'info', 'message': 'Log 1'},
  {'function_id': funcId, 'level': 'info', 'message': 'Log 2'},
  {'function_id': funcId, 'level': 'info', 'message': 'Log 3'},
]);
```

### 4. Count and Exists

```dart
// Count active functions
final count = await DatabaseManagers.functions.count(
  where: {'status': 'active'},
);

// Check if function exists
final exists = await DatabaseManagers.functions.exists(
  where: {'name': 'my-function', 'user_id': userId},
);
```

### 5. Upsert

```dart
// Insert or update on conflict
final function = await DatabaseManagers.functions.upsert(
  {
    'user_id': userId,
    'name': 'my-function',
    'status': 'active',
  },
  conflictColumns: ['user_id', 'name'],
);
```

## Common Patterns

### Pattern 1: Get Function with User

#### Before
```dart
final funcMap = await QueryHelpers.getFunctionByUuid(funcUuid);
if (funcMap != null) {
  final userUuid = funcMap['user_uuid'] as String;
  final userMap = await QueryHelpers.getUserByUuid(userUuid);
}
```

#### After
```dart
final function = await DatabaseManagers.functions.findByUuid(funcUuid);
if (function != null) {
  final user = await DatabaseManagers.users.findById(function.userId!);
}

// Or use a join query
final results = await DatabaseManagers.functions.joinQuery(
  joinTable: 'users',
  joinCondition: 'functions.user_id = users.id',
  select: ['functions.*', 'users.email', 'users.uuid as user_uuid'],
  where: {'functions.uuid': funcUuid},
);
```

### Pattern 2: Pagination

#### Before
```dart
final logs = await QueryHelpers.getFunctionLogsByFunctionUuid(
  funcUuid,
  limit: pageSize,
  offset: (page - 1) * pageSize,
);
```

#### After
```dart
final logs = await DatabaseManagers.functionLogs.findAll(
  where: {'function_id': functionId},
  orderBy: 'timestamp',
  orderDirection: 'DESC',
  limit: pageSize,
  offset: (page - 1) * pageSize,
);

// Plus you can get the total count
final total = await DatabaseManagers.functionLogs.count(
  where: {'function_id': functionId},
);
```

### Pattern 3: Complex Filtering

#### Before
```dart
// Not easily possible with QueryHelpers
// Had to write raw SQL
```

#### After
```dart
final query = DatabaseManagers.functions.query()
  .where('status', 'active')
  .where('created_at', cutoffDate, operator: '>')
  .whereNotNull('active_deployment_id')
  .orderBy('created_at', direction: 'DESC');

final functions = await DatabaseManagers.functions.executeQuery(query);
```

## Gradual Migration Strategy

You don't need to migrate everything at once! Here's a recommended approach:

### Phase 1: New Code Only
- Use entity-based system for all new features
- Keep existing code using QueryHelpers
- Both systems work side-by-side

### Phase 2: High-Traffic Endpoints
- Migrate frequently-used endpoints
- Test thoroughly
- Monitor performance

### Phase 3: Complete Migration
- Migrate remaining code
- Consider deprecating QueryHelpers
- Update documentation

## Testing Your Migration

```dart
// Test that both APIs return the same data
void testMigration() async {
  final uuid = 'test-uuid';
  
  // Old API
  final oldResult = await QueryHelpers.getUserByUuid(uuid);
  
  // New API
  final newResult = await DatabaseManagers.users.findByUuid(uuid);
  
  // Compare
  assert(oldResult['uuid'] == newResult.uuid);
  assert(oldResult['email'] == newResult.email);
  
  print('✓ Migration test passed');
}
```

## Benefits of Migration

1. **Type Safety**: Catch errors at compile time
2. **Better IDE Support**: Auto-completion and refactoring
3. **More Features**: Query builder, relationships, batch operations
4. **Cleaner Code**: Less manual type casting
5. **Better Performance**: Optimized queries
6. **Easier Testing**: Mock entities instead of maps

## Need Help?

- Check `README.md` for full API documentation
- See `EXAMPLES.md` for real-world usage examples
- QueryHelpers remains available for backward compatibility

## Summary

The new entity-based system is:
- ✅ More powerful
- ✅ Type-safe
- ✅ Backward compatible
- ✅ Well documented
- ✅ Production ready

Start using it today for new code, and migrate existing code at your own pace!
