# Database Package - Usage Examples

This document provides practical examples of using the database package in real-world scenarios.

## Table of Contents

1. [Basic CRUD Operations](#basic-crud-operations)
2. [Complex Queries](#complex-queries)
3. [Relationship Queries](#relationship-queries)
4. [Transactions](#transactions)
5. [Real-World Scenarios](#real-world-scenarios)

## Basic CRUD Operations

### Creating a New User

```dart
import 'package:database/database.dart';

Future<UserEntity> createUser(String email, String password) async {
  // Hash password (use your preferred hashing library)
  final passwordHash = hashPassword(password);
  
  // Insert user
  final user = await DatabaseManagers.users.insert({
    'email': email,
    'password_hash': passwordHash,
  });
  
  return user;
}
```

### Finding Users

```dart
// Find by UUID
final user = await DatabaseManagers.users.findByUuid('user-uuid-here');

// Find by email (using custom query)
final users = await DatabaseManagers.users.findAll(
  where: {'email': 'user@example.com'},
  limit: 1,
);
final user = users.isNotEmpty ? users.first : null;

// Find all users created in the last 7 days
final recentUsers = await DatabaseManagers.users.raw(
  '''
  SELECT * FROM users 
  WHERE created_at > @since 
  ORDER BY created_at DESC
  ''',
  parameters: {
    'since': DateTime.now().subtract(Duration(days: 7)),
  },
);
```

### Updating a User

```dart
// Update by UUID
await DatabaseManagers.users.updateById(
  userUuid,
  {'email': 'newemail@example.com'},
  idColumn: 'uuid',
);

// Update with conditions
await DatabaseManagers.users.update(
  {'status': 'verified'},
  where: {'email': 'user@example.com'},
);
```

### Deleting a User

```dart
// Delete by UUID
await DatabaseManagers.users.deleteById(userUuid, idColumn: 'uuid');

// Delete with conditions
await DatabaseManagers.users.delete(
  where: {'created_at': oldDate, operator: '<'},
);
```

## Complex Queries

### Functions with User Information

```dart
Future<List<Map<String, dynamic>>> getFunctionsWithUserInfo(int userId) async {
  final manager = DatabaseManagers.functions;
  
  final query = manager.query()
    .select([
      'f.uuid',
      'f.name',
      'f.status',
      'f.created_at',
      'u.email as user_email',
      'COUNT(fd.id) as deployment_count',
    ])
    .join('users u', 'f.user_id', 'u.id', type: 'INNER')
    .leftJoin('function_deployments fd', 'f.id', 'fd.function_id')
    .where('f.user_id', userId)
    .groupBy('f.id, u.email')
    .orderBy('f.created_at', direction: 'DESC');
  
  final result = await manager.rawQuery(
    query.buildSelect(),
    parameters: query.parameters,
  );
  
  return result.map((row) {
    return {
      'uuid': row[0],
      'name': row[1],
      'status': row[2],
      'created_at': row[3],
      'user_email': row[4],
      'deployment_count': row[5],
    };
  }).toList();
}
```

### Active Functions with Latest Deployment

```dart
Future<List<Map<String, dynamic>>> getActiveFunctionsWithDeployment() async {
  return await Database.rawQueryAll(
    '''
    SELECT 
      f.uuid as function_uuid,
      f.name,
      f.status,
      fd.version as latest_version,
      fd.image_tag,
      fd.deployed_at
    FROM functions f
    LEFT JOIN LATERAL (
      SELECT * FROM function_deployments
      WHERE function_id = f.id
      AND is_active = true
      ORDER BY version DESC
      LIMIT 1
    ) fd ON true
    WHERE f.status = 'active'
    ORDER BY f.created_at DESC
    ''',
  );
}
```

### Search Functions by Name

```dart
Future<List<FunctionEntity>> searchFunctions(String searchTerm) async {
  final manager = DatabaseManagers.functions;
  
  final query = manager.query()
    .whereRaw('name ILIKE @search', {'search': '%$searchTerm%'})
    .orderBy('name');
  
  return await manager.executeQuery(query);
}
```

## Relationship Queries

### Get All Deployments for a Function

```dart
Future<List<FunctionDeploymentEntity>> getFunctionDeployments(
  int functionId,
) async {
  return await DatabaseManagers.functionDeployments.findAll(
    where: {'function_id': functionId},
    orderBy: 'version',
    orderDirection: 'DESC',
  );
}
```

### Get Function with All Related Data

```dart
class FunctionWithRelations {
  final FunctionEntity function;
  final UserEntity user;
  final List<FunctionDeploymentEntity> deployments;
  final List<FunctionLogEntity> recentLogs;
  
  FunctionWithRelations({
    required this.function,
    required this.user,
    required this.deployments,
    required this.recentLogs,
  });
}

Future<FunctionWithRelations?> getFunctionWithRelations(
  String functionUuid,
) async {
  // Get function
  final function = await DatabaseManagers.functions.findByUuid(functionUuid);
  if (function == null) return null;
  
  // Get user
  final userData = await DatabaseManagers.users.findById(function.userId!);
  if (userData == null) return null;
  
  // Get deployments
  final deployments = await DatabaseManagers.functionDeployments.findAll(
    where: {'function_id': function.id},
    orderBy: 'version',
    orderDirection: 'DESC',
  );
  
  // Get recent logs
  final logs = await DatabaseManagers.functionLogs.findAll(
    where: {'function_id': function.id},
    orderBy: 'timestamp',
    orderDirection: 'DESC',
    limit: 50,
  );
  
  return FunctionWithRelations(
    function: function,
    user: userData,
    deployments: deployments,
    recentLogs: logs,
  );
}
```

### Get User's Functions with Deployment Stats

```dart
Future<List<Map<String, dynamic>>> getUserFunctionsWithStats(
  int userId,
) async {
  return await Database.rawQueryAll(
    '''
    SELECT 
      f.uuid,
      f.name,
      f.status,
      COUNT(DISTINCT fd.id) as total_deployments,
      COUNT(DISTINCT CASE WHEN fd.is_active THEN fd.id END) as active_deployments,
      MAX(fd.deployed_at) as last_deployment,
      COUNT(DISTINCT fi.id) as total_invocations,
      AVG(fi.duration_ms) as avg_duration_ms
    FROM functions f
    LEFT JOIN function_deployments fd ON f.id = fd.function_id
    LEFT JOIN function_invocations fi ON f.id = fi.function_id
    WHERE f.user_id = @user_id
    GROUP BY f.id, f.uuid, f.name, f.status
    ORDER BY f.created_at DESC
    ''',
    parameters: {'user_id': userId},
  );
}
```

## Transactions

### Create Function with Initial Deployment

```dart
Future<Map<String, dynamic>> createFunctionWithDeployment({
  required int userId,
  required String functionName,
  required String imageTag,
  required String s3Key,
}) async {
  return await Database.transaction((connection) async {
    // Create function
    final functionResult = await connection.execute(
      Sql.named('''
        INSERT INTO functions (user_id, name, status)
        VALUES (@user_id, @name, 'building')
        RETURNING id, uuid
      '''),
      parameters: {
        'user_id': userId,
        'name': functionName,
      },
    );
    
    final functionId = functionResult.first[0] as int;
    final functionUuid = functionResult.first[1].toString();
    
    // Create deployment
    final deploymentResult = await connection.execute(
      Sql.named('''
        INSERT INTO function_deployments 
        (function_id, version, image_tag, s3_key, status)
        VALUES (@function_id, 1, @image_tag, @s3_key, 'building')
        RETURNING id, uuid
      '''),
      parameters: {
        'function_id': functionId,
        'image_tag': imageTag,
        's3_key': s3Key,
      },
    );
    
    final deploymentId = deploymentResult.first[0] as int;
    final deploymentUuid = deploymentResult.first[1].toString();
    
    return {
      'function_id': functionId,
      'function_uuid': functionUuid,
      'deployment_id': deploymentId,
      'deployment_uuid': deploymentUuid,
    };
  });
}
```

### Activate Deployment (Deactivate Others)

```dart
Future<void> activateDeployment(int deploymentId, int functionId) async {
  await Database.transaction((connection) async {
    // Deactivate all deployments for this function
    await connection.execute(
      Sql.named('''
        UPDATE function_deployments
        SET is_active = false
        WHERE function_id = @function_id
      '''),
      parameters: {'function_id': functionId},
    );
    
    // Activate the specified deployment
    await connection.execute(
      Sql.named('''
        UPDATE function_deployments
        SET is_active = true, status = 'deployed'
        WHERE id = @deployment_id
      '''),
      parameters: {'deployment_id': deploymentId},
    );
    
    // Update function's active deployment
    await connection.execute(
      Sql.named('''
        UPDATE functions
        SET active_deployment_id = @deployment_id, status = 'active'
        WHERE id = @function_id
      '''),
      parameters: {
        'deployment_id': deploymentId,
        'function_id': functionId,
      },
    );
  });
}
```

## Real-World Scenarios

### User Registration Flow

```dart
Future<Map<String, dynamic>> registerUser({
  required String email,
  required String password,
}) async {
  // Check if user exists
  final existingUsers = await DatabaseManagers.users.findAll(
    where: {'email': email},
    limit: 1,
  );
  
  if (existingUsers.isNotEmpty) {
    throw Exception('User already exists');
  }
  
  // Hash password
  final passwordHash = hashPassword(password);
  
  // Create user
  final user = await DatabaseManagers.users.insert({
    'email': email,
    'password_hash': passwordHash,
  });
  
  return {
    'uuid': user.uuid,
    'email': user.email,
    'created_at': user.createdAt,
  };
}
```

### Function Deployment Flow

```dart
Future<String> deployFunction({
  required String functionUuid,
  required String imageTag,
  required String s3Key,
}) async {
  // Get function
  final function = await DatabaseManagers.functions.findByUuid(functionUuid);
  if (function == null) {
    throw Exception('Function not found');
  }
  
  // Get next version number
  final deployments = await DatabaseManagers.functionDeployments.findAll(
    where: {'function_id': function.id},
    orderBy: 'version',
    orderDirection: 'DESC',
    limit: 1,
  );
  
  final nextVersion = deployments.isEmpty ? 1 : deployments.first.version + 1;
  
  // Create deployment
  final deployment = await DatabaseManagers.functionDeployments.insert({
    'function_id': function.id,
    'version': nextVersion,
    'image_tag': imageTag,
    's3_key': s3Key,
    'status': 'building',
    'is_active': false,
  });
  
  // Update function status
  await DatabaseManagers.functions.updateById(
    function.id!,
    {'status': 'building'},
  );
  
  return deployment.uuid!;
}
```

### Get Function Logs with Pagination

```dart
class LogsResponse {
  final List<FunctionLogEntity> logs;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
  
  LogsResponse({
    required this.logs,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });
}

Future<LogsResponse> getFunctionLogs({
  required int functionId,
  int page = 1,
  int pageSize = 50,
  String? level,
}) async {
  // Build where clause
  final where = <String, dynamic>{'function_id': functionId};
  if (level != null) {
    where['level'] = level;
  }
  
  // Get total count
  final total = await DatabaseManagers.functionLogs.count(where: where);
  
  // Get logs
  final logs = await DatabaseManagers.functionLogs.findAll(
    where: where,
    orderBy: 'timestamp',
    orderDirection: 'DESC',
    limit: pageSize,
    offset: (page - 1) * pageSize,
  );
  
  return LogsResponse(
    logs: logs,
    total: total,
    page: page,
    pageSize: pageSize,
    hasMore: (page * pageSize) < total,
  );
}
```

### Function Analytics

```dart
class FunctionAnalytics {
  final int totalInvocations;
  final int successfulInvocations;
  final int failedInvocations;
  final double averageDuration;
  final double successRate;
  
  FunctionAnalytics({
    required this.totalInvocations,
    required this.successfulInvocations,
    required this.failedInvocations,
    required this.averageDuration,
    required this.successRate,
  });
}

Future<FunctionAnalytics> getFunctionAnalytics({
  required int functionId,
  DateTime? since,
}) async {
  final sinceDate = since ?? DateTime.now().subtract(Duration(days: 30));
  
  final result = await Database.rawQuerySingle(
    '''
    SELECT 
      COUNT(*) as total,
      COUNT(CASE WHEN status = 'success' THEN 1 END) as successful,
      COUNT(CASE WHEN status = 'error' THEN 1 END) as failed,
      AVG(duration_ms) as avg_duration
    FROM function_invocations
    WHERE function_id = @function_id
    AND timestamp >= @since
    ''',
    parameters: {
      'function_id': functionId,
      'since': sinceDate,
    },
  );
  
  if (result == null) {
    return FunctionAnalytics(
      totalInvocations: 0,
      successfulInvocations: 0,
      failedInvocations: 0,
      averageDuration: 0.0,
      successRate: 0.0,
    );
  }
  
  final total = result['total'] as int;
  final successful = result['successful'] as int;
  final failed = result['failed'] as int;
  final avgDuration = (result['avg_duration'] as num?)?.toDouble() ?? 0.0;
  
  return FunctionAnalytics(
    totalInvocations: total,
    successfulInvocations: successful,
    failedInvocations: failed,
    averageDuration: avgDuration,
    successRate: total > 0 ? (successful / total) * 100 : 0.0,
  );
}
```

### Batch Create Logs

```dart
Future<void> batchCreateLogs({
  required int functionId,
  required List<Map<String, String>> logEntries,
}) async {
  final logsData = logEntries.map((entry) {
    return {
      'function_id': functionId,
      'level': entry['level'],
      'message': entry['message'],
    };
  }).toList();
  
  await DatabaseManagers.functionLogs.batchInsert(logsData);
}
```

### Clean Up Old Logs

```dart
Future<int> cleanupOldLogs({int daysToKeep = 30}) async {
  final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
  
  return await Database.rawExecute(
    '''
    DELETE FROM function_logs
    WHERE timestamp < @cutoff_date
    ''',
    parameters: {'cutoff_date': cutoffDate},
  );
}
```

### Upsert Function Configuration

```dart
Future<FunctionEntity> upsertFunction({
  required int userId,
  required String functionName,
  Map<String, dynamic>? analysisResult,
}) async {
  return await DatabaseManagers.functions.upsert(
    {
      'user_id': userId,
      'name': functionName,
      'status': 'active',
      if (analysisResult != null) 'analysis_result': analysisResult,
    },
    conflictColumns: ['user_id', 'name'],
    updateColumns: ['status', 'analysis_result', 'updated_at'],
  );
}
```

## Performance Tips

1. **Use indexes**: The database already has indexes on frequently queried columns
2. **Limit results**: Always use `limit` for large result sets
3. **Use pagination**: Implement pagination for list views
4. **Batch operations**: Use `batchInsert` for multiple records
5. **Transactions**: Group related operations in transactions
6. **Select specific columns**: Use `.select()` to fetch only needed columns
7. **Connection pooling**: The postgres package handles this automatically

## Error Handling

```dart
Future<UserEntity?> safeGetUser(String uuid) async {
  try {
    return await DatabaseManagers.users.findByUuid(uuid);
  } on PostgreSQLException catch (e) {
    print('Database error: ${e.message}');
    return null;
  } catch (e) {
    print('Unexpected error: $e');
    return null;
  }
}
```
