# Database UUID Strategy

## Overview

The database uses a dual-identifier approach:
- **Serial IDs** (internal) - For database performance and foreign key relationships
- **UUIDs** (public) - For client-facing operations and external APIs

## Why This Approach?

### Benefits of Serial IDs (Internal)

✅ **Performance:**
- Smaller storage size (4 bytes vs 16 bytes)
- Faster joins and indexes
- Sequential ordering for better B-tree performance
- Reduced memory usage

✅ **Database Efficiency:**
- Native auto-increment support
- Optimal for foreign key relationships
- Better query optimizer performance
- Smaller index sizes

### Benefits of UUIDs (Public)

✅ **Security:**
- Non-sequential - prevents enumeration attacks
- No information leakage about record count
- Harder to guess valid IDs

✅ **Flexibility:**
- Globally unique across systems
- Can be generated client-side if needed
- Easier for distributed systems
- Better for public APIs

## Database Schema

### Table Structure

Each table has both identifiers:

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,              -- Internal use only
  uuid UUID UNIQUE NOT NULL,          -- Public identifier
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Indexes

UUIDs have dedicated indexes for fast lookups:

```sql
CREATE INDEX idx_users_uuid ON users(uuid);
```

### Foreign Keys

Internal relationships use serial IDs:

```sql
CREATE TABLE functions (
  id SERIAL PRIMARY KEY,
  uuid UUID UNIQUE NOT NULL,
  user_id INTEGER NOT NULL REFERENCES users(id),  -- Uses serial ID
  ...
);
```

## Usage Guidelines

### ✅ DO: Use UUIDs for Client-Facing Operations

**API Endpoints:**
```dart
// Good: Use UUID in API
GET /api/functions/{uuid}
DELETE /api/functions/{uuid}

// Bad: Don't expose serial IDs
GET /api/functions/123  // ❌ Exposes internal ID
```

**API Responses:**
```dart
// Good: Return UUID to client
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "name": "my-function",
  "status": "active"
}

// Bad: Don't return serial ID
{
  "id": 123,  // ❌ Internal ID exposed
  "name": "my-function"
}
```

### ✅ DO: Use Serial IDs for Internal Operations

**Database Queries:**
```dart
// Good: Use serial ID for joins
SELECT f.* FROM functions f
JOIN users u ON f.user_id = u.id  -- Fast join with serial ID
WHERE u.uuid = '550e8400-e29b-41d4-a716-446655440000';

// Less efficient: Join on UUIDs
SELECT f.* FROM functions f
JOIN users u ON f.user_uuid = u.uuid  -- Slower
WHERE u.uuid = '550e8400-e29b-41d4-a716-446655440000';
```

**Foreign Key Relationships:**
```dart
// Good: Use serial ID for foreign keys
INSERT INTO functions (user_id, name)
SELECT id, 'my-function' FROM users WHERE uuid = @uuid;

// Bad: Don't use UUID for foreign keys
-- This would require UUID columns and larger indexes
```

## Query Helpers

Use the `QueryHelpers` class for UUID-based operations:

```dart
import 'package:dart_cloud_backend/database/query_helpers.dart';

// Get user by UUID
final user = await QueryHelpers.getUserByUuid(userUuid);

// Get functions for a user
final functions = await QueryHelpers.getFunctionsByUserUuid(userUuid);

// Create function
final functionUuid = await QueryHelpers.createFunction(
  userUuid: userUuid,
  name: 'my-function',
  status: 'active',
);

// Update function
await QueryHelpers.updateFunction(
  uuid: functionUuid,
  status: 'inactive',
);

// Delete function
await QueryHelpers.deleteFunction(functionUuid);
```

## Migration from Pure UUID Schema

If you have existing code using pure UUIDs:

### Before (Pure UUID):
```dart
// Old schema
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ...
);

// Old query
SELECT * FROM users WHERE id = @uuid;
```

### After (Serial + UUID):
```dart
// New schema
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
  ...
);

// New query (use QueryHelpers)
final user = await QueryHelpers.getUserByUuid(uuid);

// Or raw query
SELECT * FROM users WHERE uuid = @uuid;
```

## Performance Comparison

### Storage Size

| Type | Size | Example |
|------|------|---------|
| SERIAL (INTEGER) | 4 bytes | `123` |
| BIGSERIAL (BIGINT) | 8 bytes | `9223372036854775807` |
| UUID | 16 bytes | `550e8400-e29b-41d4-a716-446655440000` |

### Index Size (1 million records)

| Index Type | Approximate Size |
|------------|------------------|
| SERIAL | ~8 MB |
| UUID | ~32 MB |

### Join Performance

Serial ID joins are typically **2-3x faster** than UUID joins due to:
- Smaller index size
- Better cache locality
- Sequential ordering

## Best Practices

### 1. Always Use UUIDs in APIs

```dart
// ✅ Good
router.get('/api/functions/<uuid>', (Request request, String uuid) async {
  final function = await QueryHelpers.getFunctionByUuid(uuid);
  return Response.json(function);
});

// ❌ Bad
router.get('/api/functions/<id>', (Request request, String id) async {
  // Don't expose serial IDs
});
```

### 2. Use Serial IDs for Internal Queries

```dart
// ✅ Good - Fast join with serial ID
SELECT f.*, u.email
FROM functions f
JOIN users u ON f.user_id = u.id
WHERE f.uuid = @function_uuid;

// ❌ Less efficient - Join on UUIDs
SELECT f.*, u.email
FROM functions f
JOIN users u ON f.user_uuid = u.uuid
WHERE f.uuid = @function_uuid;
```

### 3. Never Expose Serial IDs to Clients

```dart
// ✅ Good
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "name": "my-function"
}

// ❌ Bad
{
  "id": 123,  // Internal ID exposed
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "name": "my-function"
}
```

### 4. Use QueryHelpers for UUID Operations

```dart
// ✅ Good - Use helper methods
final user = await QueryHelpers.getUserByUuid(uuid);

// ⚠️ Acceptable but verbose
final result = await Database.connection.execute(
  Sql.named('SELECT * FROM users WHERE uuid = @uuid'),
  parameters: {'uuid': uuid},
);
```

### 5. Index UUIDs for Performance

```sql
-- Always create indexes on UUID columns
CREATE INDEX idx_users_uuid ON users(uuid);
CREATE INDEX idx_functions_uuid ON functions(uuid);
```

## Security Considerations

### UUID Benefits

✅ **Non-enumerable:** Can't guess valid UUIDs
✅ **No information leakage:** Doesn't reveal record count
✅ **Unpredictable:** Random generation prevents attacks

### Serial ID Risks (if exposed)

❌ **Enumerable:** Easy to iterate through IDs (1, 2, 3...)
❌ **Information leakage:** Reveals approximate record count
❌ **Predictable:** Can guess valid IDs

### Example Attack Prevention

```dart
// ❌ Vulnerable to enumeration
GET /api/users/1
GET /api/users/2
GET /api/users/3
// Attacker can iterate through all users

// ✅ Protected with UUIDs
GET /api/users/550e8400-e29b-41d4-a716-446655440000
GET /api/users/6ba7b810-9dad-11d1-80b4-00c04fd430c8
// Can't guess valid UUIDs
```

## Monitoring

### Check UUID Generation

```sql
-- Verify UUIDs are being generated
SELECT uuid FROM users LIMIT 10;

-- Check for NULL UUIDs (should be none)
SELECT COUNT(*) FROM users WHERE uuid IS NULL;
```

### Check Index Usage

```sql
-- Verify UUID index is being used
EXPLAIN ANALYZE
SELECT * FROM users WHERE uuid = '550e8400-e29b-41d4-a716-446655440000';
```

### Performance Metrics

```sql
-- Compare query performance
-- UUID lookup (should use index)
EXPLAIN ANALYZE
SELECT * FROM functions WHERE uuid = @uuid;

-- Serial ID join (should be fast)
EXPLAIN ANALYZE
SELECT f.* FROM functions f
JOIN users u ON f.user_id = u.id
WHERE u.uuid = @user_uuid;
```

## Summary

| Aspect | Serial ID | UUID |
|--------|-----------|------|
| **Use Case** | Internal operations | Client-facing operations |
| **Storage** | 4 bytes | 16 bytes |
| **Performance** | Faster | Slightly slower |
| **Security** | Enumerable | Non-enumerable |
| **Visibility** | Internal only | Public API |
| **Foreign Keys** | ✅ Use for FKs | ❌ Don't use for FKs |
| **API Responses** | ❌ Never expose | ✅ Always use |
| **Database Joins** | ✅ Optimal | ⚠️ Less efficient |

---

**Remember:** Serial IDs for performance, UUIDs for security and public APIs!
