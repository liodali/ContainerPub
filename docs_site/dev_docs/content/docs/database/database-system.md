---
title: Database System
description: Entity-based database management system with query builder and relationship support
---

# Database System

The ContainerPub backend uses a comprehensive entity-based database management system built on PostgreSQL. This system provides type-safe CRUD operations, a powerful query builder, and relationship management.

## Overview

**Location**: `dart_cloud_backend/packages/database/`

**Key Features**:

- 🎯 Entity-based models for type safety
- 🔨 Fluent query builder for complex SQL
- 🔗 Relationship support (hasMany, belongsTo, manyToMany)
- 🛡️ SQL injection prevention through parameterized queries
- 🚀 Batch operations and transactions
- 📊 Built-in analytics and aggregation support
- ✅ 120+ unit tests with full coverage

## Architecture

### Core Components

```
database/
├── lib/
│   ├── database.dart              # Main Database class
│   └── src/
│       ├── entity.dart            # Base entity class & annotations
│       ├── query_builder.dart     # SQL query builder
│       ├── database_manager_query.dart  # CRUD manager
│       ├── relationship_manager.dart    # Relationship queries
│       ├── managers.dart          # Pre-configured managers
│       ├── query_helpers.dart     # Legacy helpers (backward compat)
│       ├── entities/              # Database entities (internal use)
│       │   ├── user_entity.dart
│       │   ├── user_information.dart
│       │   ├── organization.dart
│       │   ├── organization_member.dart
│       │   ├── function_entity.dart
│       │   ├── function_deployment_entity.dart
│       │   ├── function_log_entity.dart
│       │   └── function_invocation_entity.dart
│       ├── dto/                   # Data Transfer Objects (API responses)
│       │   ├── user_dto.dart
│       │   └── organization_dto.dart
│       └── managers/              # Relationship managers
│           ├── user_relationships.dart
│           └── organization_relationships.dart
└── test/
    ├── query_builder_test.dart    # 50+ tests
    ├── entity_test.dart           # 30+ tests
    └── database_manager_query_test.dart  # 40+ tests
```

## Database Schema

### Tables

#### 1. `users`

Stores user accounts and authentication data.

| Column        | Type         | Description           |
| ------------- | ------------ | --------------------- |
| id            | SERIAL       | Internal primary key  |
| uuid          | UUID         | Public identifier     |
| email         | VARCHAR(255) | User email (unique)   |
| password_hash | VARCHAR(255) | Hashed password       |
| created_at    | TIMESTAMP    | Account creation time |
| updated_at    | TIMESTAMP    | Last update time      |

**Indexes**: `uuid`, `email`

#### 2. `functions`

Stores cloud function definitions.

| Column               | Type         | Description               |
| -------------------- | ------------ | ------------------------- |
| id                   | SERIAL       | Internal primary key      |
| uuid                 | UUID         | Public identifier         |
| user_id              | INTEGER      | Foreign key to users      |
| name                 | VARCHAR(255) | Function name             |
| status               | VARCHAR(50)  | Function status           |
| active_deployment_id | INTEGER      | Current active deployment |
| analysis_result      | JSONB        | Static analysis results   |
| created_at           | TIMESTAMP    | Creation time             |
| updated_at           | TIMESTAMP    | Last update time          |

**Indexes**: `uuid`, `user_id`, `active_deployment_id`  
**Constraints**: UNIQUE(user_id, name)

#### 3. `function_deployments`

Tracks function deployment versions and history.

| Column      | Type         | Description               |
| ----------- | ------------ | ------------------------- |
| id          | SERIAL       | Internal primary key      |
| uuid        | UUID         | Public identifier         |
| function_id | INTEGER      | Foreign key to functions  |
| version     | INTEGER      | Deployment version number |
| image_tag   | VARCHAR(255) | Container image tag       |
| s3_key      | VARCHAR(500) | S3 storage key            |
| status      | VARCHAR(50)  | Deployment status         |
| is_active   | BOOLEAN      | Currently active flag     |
| build_logs  | TEXT         | Build process logs        |
| deployed_at | TIMESTAMP    | Deployment time           |

**Indexes**: `uuid`, `function_id`, `is_active`, `version`  
**Constraints**: UNIQUE(function_id, version)

#### 4. `function_logs`

Stores function execution logs.

| Column      | Type        | Description                   |
| ----------- | ----------- | ----------------------------- |
| id          | SERIAL      | Internal primary key          |
| uuid        | UUID        | Public identifier             |
| function_id | INTEGER     | Foreign key to functions      |
| level       | VARCHAR(20) | Log level (info, warn, error) |
| message     | TEXT        | Log message                   |
| timestamp   | TIMESTAMP   | Log timestamp                 |

**Indexes**: `function_id`, `timestamp`

#### 5. `function_invocations`

Tracks function invocation metrics.

| Column      | Type        | Description               |
| ----------- | ----------- | ------------------------- |
| id          | SERIAL      | Internal primary key      |
| uuid        | UUID        | Public identifier         |
| function_id | INTEGER     | Foreign key to functions  |
| status      | VARCHAR(50) | Invocation status         |
| duration_ms | INTEGER     | Execution duration        |
| error       | TEXT        | Error message (if failed) |
| timestamp   | TIMESTAMP   | Invocation time           |

**Indexes**: `function_id`, `timestamp`

#### 6. `user_information`

Stores extended user profile information.

| Column       | Type         | Description                                     |
| ------------ | ------------ | ----------------------------------------------- |
| id           | SERIAL       | Internal primary key                            |
| uuid         | UUID         | Public identifier                               |
| user_id      | UUID         | Foreign key to users(uuid)                      |
| first_name   | VARCHAR(100) | User's first name                               |
| last_name    | VARCHAR(100) | User's last name                                |
| phone_number | VARCHAR(20)  | Contact phone                                   |
| country      | VARCHAR(100) | Country                                         |
| city         | VARCHAR(100) | City                                            |
| address      | TEXT         | Street address                                  |
| zip_code     | VARCHAR(20)  | Postal code                                     |
| avatar       | TEXT         | Avatar URL                                      |
| role         | VARCHAR(50)  | User role (developer, team, sub_team_developer) |
| created_at   | TIMESTAMP    | Creation time                                   |
| updated_at   | TIMESTAMP    | Last update time                                |

**Indexes**: `user_id`, `role`  
**Constraints**: UNIQUE(user_id)

#### 7. `organizations`

Stores organization information.

| Column     | Type         | Description                                     |
| ---------- | ------------ | ----------------------------------------------- |
| id         | SERIAL       | Internal primary key                            |
| uuid       | UUID         | Public identifier                               |
| name       | VARCHAR(255) | Organization name (unique)                      |
| owner_id   | UUID         | Foreign key to users(uuid) - organization owner |
| created_at | TIMESTAMP    | Creation time                                   |
| updated_at | TIMESTAMP    | Last update time                                |

**Indexes**: `owner_id`, `name`  
**Constraints**: UNIQUE(name)

#### 8. `organization_members`

Junction table linking users to organizations (one user = one organization).

| Column          | Type      | Description                        |
| --------------- | --------- | ---------------------------------- |
| id              | SERIAL    | Internal primary key               |
| organization_id | UUID      | Foreign key to organizations(uuid) |
| user_id         | UUID      | Foreign key to users(uuid)         |
| joined_at       | TIMESTAMP | Membership start time              |

**Indexes**: `organization_id`, `user_id`  
**Constraints**: UNIQUE(user_id) - ensures one user belongs to only one organization

## DTO Architecture

### Overview

The system uses Data Transfer Objects (DTOs) to separate internal database operations from external API responses:

- **Internal Layer**: Uses `id` (integer) for database operations and foreign keys
- **External Layer**: Uses `uuid` (string) for all frontend communication
- **Privacy Controls**: Conditional field exposure based on user roles

### User DTOs

**Location**: `lib/src/dto/user_dto.dart`

- `UserDto` - Basic user information (uuid, email)
- `UserInformationDto` - User profile details
- `UserProfileDto` - Complete user profile (user + information)

### Organization DTOs

**Location**: `lib/src/dto/organization_dto.dart`

- `OrganizationDto` - Basic organization info
- `OrganizationMemberDto` - Member with user profile
- `OrganizationWithMembersDto` - Organization with all members
- `UserWithOrganizationDto` - User with their organization

### Privacy Features

**Member UUID Exposure**: The `OrganizationMemberDto` conditionally includes member UUIDs:

- **Owner view**: All member UUIDs visible (for management)
- **Non-owner view**: Member UUIDs hidden (privacy protection)

```dart
// Owner request
final dto = OrganizationWithMembersDto.fromEntities(
  organization: org,
  members: members,
  requesterId: ownerId, // Matches organization.ownerId
);
// Result: members[].uuid = "550e8400-..."

// Non-owner request
final dto = OrganizationWithMembersDto.fromEntities(
  organization: org,
  members: members,
  requesterId: nonOwnerId, // Different from organization.ownerId
);
// Result: members[].uuid = null (omitted from JSON)
```

## Usage Patterns

### 1. Basic CRUD Operations

```dart
import 'package:database/database.dart';

// Find by UUID
final user = await DatabaseManagers.users.findByUuid('user-uuid');

// Find with conditions
final functions = await DatabaseManagers.functions.findAll(
  where: {'user_id': userId, 'status': 'active'},
  orderBy: 'created_at',
  orderDirection: 'DESC',
  limit: 10,
);

// Insert
final newFunction = await DatabaseManagers.functions.insert({
  'user_id': userId,
  'name': 'my-function',
  'status': 'active',
});

// Update
await DatabaseManagers.functions.updateById(
  functionId,
  {'status': 'inactive'},
);

// Delete
await DatabaseManagers.functions.deleteById(functionId);

// Count
final count = await DatabaseManagers.functions.count(
  where: {'status': 'active'},
);
```

### 2. Query Builder

```dart
// Complex query with joins
final query = DatabaseManagers.functions.query()
  .select(['f.*', 'u.email', 'COUNT(fd.id) as deployment_count'])
  .join('users u', 'f.user_id', 'u.id')
  .leftJoin('function_deployments fd', 'f.id', 'fd.function_id')
  .where('f.status', 'active')
  .where('f.created_at', cutoffDate, operator: '>')
  .groupBy('f.id, u.email')
  .orderBy('f.created_at', direction: 'DESC')
  .limit(20);

final results = await DatabaseManagers.functions.executeQuery(query);
```

### 3. Relationships

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
final user = await DatabaseManagers.users.findById(function.userId);

// Complex join query
final results = await DatabaseManagers.functions.joinQuery(
  joinTable: 'users',
  joinCondition: 'functions.user_id = users.id',
  select: ['functions.*', 'users.email'],
  where: {'functions.status': 'active'},
);
```

### 4. Raw SQL (for complex queries)

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
```

### 5. Transactions

```dart
await Database.transaction((connection) async {
  // Create function
  final functionResult = await connection.execute(
    Sql.named('INSERT INTO functions ...'),
    parameters: {...},
  );

  // Create initial deployment
  await connection.execute(
    Sql.named('INSERT INTO function_deployments ...'),
    parameters: {...},
  );

  // All or nothing - automatic rollback on error
});
```

### 6. Batch Operations

```dart
// Batch insert logs
final logsData = [
  {'function_id': funcId, 'level': 'info', 'message': 'Log 1'},
  {'function_id': funcId, 'level': 'error', 'message': 'Log 2'},
  {'function_id': funcId, 'level': 'warn', 'message': 'Log 3'},
];

await DatabaseManagers.functionLogs.batchInsert(logsData);
```

## Entity Models

### UserEntity

```dart
class UserEntity extends Entity {
  final int? id;
  final String? uuid;
  final String email;
  final String? passwordHash;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Methods: toMap(), fromMap(), copyWith()
}
```

### FunctionEntity

```dart
class FunctionEntity extends Entity {
  final int? id;
  final String? uuid;
  final int? userId;
  final String name;
  final String? status;
  final int? activeDeploymentId;
  final Map<String, dynamic>? analysisResult;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Methods: toMap(), fromMap(), copyWith()
}
```

## Database Managers

Pre-configured managers for each table:

```dart
DatabaseManagers.users              // UserEntity
DatabaseManagers.functions          // FunctionEntity
DatabaseManagers.functionDeployments // FunctionDeploymentEntity
DatabaseManagers.functionLogs       // FunctionLogEntity
DatabaseManagers.functionInvocations // FunctionInvocationEntity
```

Each manager provides:

- `findById(id)` / `findByUuid(uuid)`
- `findAll({where, orderBy, limit, offset})`
- `findOne({where})`
- `insert(data)`
- `update(data, {where})`
- `updateById(id, data)`
- `delete({where})`
- `deleteById(id)`
- `count({where})`
- `exists({where})`
- `raw(sql, {parameters})`
- `hasMany(...)` / `belongsTo(...)` / `manyToMany(...)`
- `batchInsert(dataList)`
- `upsert(data, {conflictColumns})`

## Performance Considerations

### Indexes

All tables have optimized indexes:

- **UUID indexes** for fast public ID lookups
- **Foreign key indexes** for efficient joins
- **Timestamp indexes** for time-based queries
- **Composite indexes** for common query patterns

### Query Optimization

1. **Use specific columns**: `select(['id', 'name'])` instead of `SELECT *`
2. **Add LIMIT**: Always paginate large result sets
3. **Use indexes**: Query on indexed columns
4. **Batch operations**: Use `batchInsert` for multiple records
5. **Transactions**: Group related operations
6. **Connection pooling**: Handled automatically by postgres package

### Example: Optimized Query

```dart
// ❌ Bad: No limit, SELECT *
final all = await DatabaseManagers.functions.findAll();

// ✅ Good: Limited, specific columns, indexed WHERE
final query = DatabaseManagers.functions.query()
  .select(['id', 'uuid', 'name', 'status'])
  .where('user_id', userId)  // Indexed column
  .where('status', 'active')
  .orderBy('created_at', direction: 'DESC')
  .limit(20)
  .offset(0);
```

## Security

### SQL Injection Prevention

All queries use **parameterized statements**:

```dart
// ✅ Safe: Parameters are bound
.where('email', userInput)
// Generates: WHERE email = @param_0
// Parameters: {'param_0': userInput}

// ❌ Never do this:
// .whereRaw("email = '$userInput'")  // Vulnerable!
```

### UUID Strategy

- **Internal IDs** (SERIAL): Used for foreign keys and joins (performance)
- **Public UUIDs**: Exposed in API responses (security)
- **Benefits**:
  - Prevents ID enumeration attacks
  - Allows ID generation before insertion
  - Enables distributed systems

## Testing

### Unit Tests

**Location**: `dart_cloud_backend/packages/database/test/`

**Coverage**: 120+ test cases

- Query Builder: 50+ tests
- Entities: 30+ tests
- DatabaseManagerQuery: 40+ tests

**Run tests**:

```dart
cd dart_cloud_backend/packages/database
dart test

# With coverage
./test_runner.sh coverage

# Specific suite
dart test test/query_builder_test.dart
```

### Test Philosophy

Tests verify **SQL generation** without database connection:

- ✅ Fast (1-2 seconds)
- ✅ No setup required
- ✅ Deterministic
- ✅ CI/CD friendly

## Migration from QueryHelpers

The system maintains backward compatibility with the legacy `QueryHelpers` API:

```dart
// Old API (still works)
final user = await QueryHelpers.getUserByUuid(uuid);

// New API (recommended)
final user = await DatabaseManagers.users.findByUuid(uuid);
```

**Migration benefits**:

- Type safety
- Better IDE support
- More features
- Cleaner code

See `MIGRATION_GUIDE.md` for detailed migration steps.

## Common Patterns

### Pattern 1: Get Function with Related Data

```dart
Future<FunctionWithRelations?> getFunctionDetails(String uuid) async {
  final function = await DatabaseManagers.functions.findByUuid(uuid);
  if (function == null) return null;

  final user = await DatabaseManagers.users.findById(function.userId!);
  final deployments = await DatabaseManagers.functionDeployments.findAll(
    where: {'function_id': function.id},
    orderBy: 'version',
    orderDirection: 'DESC',
  );

  return FunctionWithRelations(
    function: function,
    user: user!,
    deployments: deployments,
  );
}
```

### Pattern 2: Pagination

```dart
Future<PaginatedResult<FunctionEntity>> getFunctionsPaginated({
  required int page,
  required int pageSize,
  Map<String, dynamic>? filters,
}) async {
  final offset = (page - 1) * pageSize;

  final total = await DatabaseManagers.functions.count(where: filters);
  final items = await DatabaseManagers.functions.findAll(
    where: filters,
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

### Pattern 3: Analytics

```dart
Future<FunctionStats> getFunctionStats(int functionId) async {
  final result = await Database.rawQuerySingle(
    '''
    SELECT
      COUNT(*) as total_invocations,
      COUNT(CASE WHEN status = 'success' THEN 1 END) as successful,
      AVG(duration_ms) as avg_duration,
      MAX(duration_ms) as max_duration
    FROM function_invocations
    WHERE function_id = @function_id
    AND timestamp >= @since
    ''',
    parameters: {
      'function_id': functionId,
      'since': DateTime.now().subtract(Duration(days: 30)),
    },
  );

  return FunctionStats.fromMap(result!);
}
```

## Troubleshooting

### Common Issues

**Issue**: Query returns empty results

```dart
// Check: Are you using the right ID type?
// ❌ Wrong: Using UUID where internal ID expected
.where('user_id', userUuid)  // userUuid is string

// ✅ Correct: Use internal ID
final user = await DatabaseManagers.users.findByUuid(userUuid);
.where('user_id', user.id)  // user.id is int
```

**Issue**: Slow queries

```dart
// Add indexes, use LIMIT, select specific columns
// Check EXPLAIN output for query plan
```

**Issue**: Transaction rollback

```dart
// Ensure all operations use the connection parameter
await Database.transaction((connection) async {
  // ✅ Use connection
  await connection.execute(...);

  // ❌ Don't use Database.connection directly
  // await Database.connection.execute(...);
});
```

## Future Enhancements

Planned improvements:

- [ ] Query result caching
- [ ] Read replicas support
- [ ] Migration system
- [ ] Soft deletes
- [ ] Audit logging
- [ ] Full-text search integration
- [ ] GraphQL query generation

## Resources

- **Package README**: `dart_cloud_backend/packages/database/README.md`
- **Examples**: `dart_cloud_backend/packages/database/EXAMPLES.md`
- **Testing Guide**: `dart_cloud_backend/packages/database/TESTING.md`
- **Migration Guide**: `dart_cloud_backend/packages/database/MIGRATION_GUIDE.md`
- **Tests**: `dart_cloud_backend/packages/database/test/`

## Contributing

When modifying the database system:

1. **Update entities** if schema changes
2. **Add tests** for new query patterns
3. **Update documentation** in all relevant files
4. **Run tests** before committing: `dart test`
5. **Check coverage**: `./test_runner.sh coverage`
6. **Update migration guide** if breaking changes

## Summary

The database system provides:

- ✅ Type-safe entity models
- ✅ Powerful query builder
- ✅ Relationship management
- ✅ SQL injection prevention
- ✅ Comprehensive testing
- ✅ Excellent performance
- ✅ Easy to use and extend

For detailed API documentation, see the package README and inline code documentation.
