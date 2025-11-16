# Database Package - Testing Guide

## Overview

The database package includes comprehensive unit tests that verify SQL query generation and entity behavior **without requiring a database connection**. This makes tests fast, reliable, and easy to run in any environment.

## Test Coverage

### 📊 Statistics
- **Total Test Files**: 3
- **Total Test Cases**: 120+
- **Coverage Areas**: Query Builder, Entities, DatabaseManagerQuery
- **Execution Time**: ~1-2 seconds

## Test Files

### 1. QueryBuilder Tests (`test/query_builder_test.dart`)

**50+ test cases** covering:

#### SELECT Queries
- ✅ Simple SELECT
- ✅ SELECT with specific columns
- ✅ WHERE clauses (=, >, <, >=, <=, LIKE, etc.)
- ✅ Multiple WHERE conditions
- ✅ WHERE IN
- ✅ WHERE NULL / NOT NULL
- ✅ Raw WHERE clauses
- ✅ OR WHERE
- ✅ ORDER BY (single and multiple)
- ✅ LIMIT and OFFSET
- ✅ GROUP BY
- ✅ HAVING

#### JOIN Queries
- ✅ INNER JOIN
- ✅ LEFT JOIN
- ✅ RIGHT JOIN
- ✅ Multiple JOINs
- ✅ Complex queries with JOINs + WHERE + ORDER BY

#### INSERT Queries
- ✅ Single column insert
- ✅ Multiple column insert
- ✅ Parameter binding

#### UPDATE Queries
- ✅ Simple update
- ✅ Multiple column update
- ✅ Update with WHERE clauses

#### DELETE Queries
- ✅ Delete with WHERE
- ✅ Delete with multiple conditions
- ✅ Delete all (no WHERE)

#### Error Handling
- ✅ Missing table name errors
- ✅ Parameter validation

#### Security
- ✅ SQL injection prevention
- ✅ Parameterized queries

### 2. Entity Tests (`test/entity_test.dart`)

**30+ test cases** covering all entity models:

#### UserEntity
- ✅ Table name verification
- ✅ toMap() with all fields
- ✅ toMap() with required fields only
- ✅ fromMap() conversion
- ✅ copyWith() method
- ✅ Null handling

#### FunctionEntity
- ✅ Table name verification
- ✅ toMap() with all fields
- ✅ fromMap() conversion
- ✅ copyWith() method
- ✅ JSONB field handling (analysis_result)

#### FunctionDeploymentEntity
- ✅ Table name verification
- ✅ toMap() conversion
- ✅ fromMap() conversion
- ✅ Boolean field handling (is_active)

#### FunctionLogEntity
- ✅ Table name verification
- ✅ toMap() conversion
- ✅ fromMap() conversion
- ✅ Timestamp handling

#### FunctionInvocationEntity
- ✅ Table name verification
- ✅ toMap() conversion
- ✅ fromMap() conversion
- ✅ Error field handling
- ✅ Duration tracking

#### Edge Cases
- ✅ Null value handling in toMap
- ✅ Null value handling in fromMap
- ✅ copyWith preserving null values

### 3. DatabaseManagerQuery Tests (`test/database_manager_query_test.dart`)

**40+ test cases** covering:

#### Query Generation
- ✅ findAll query generation
- ✅ findById query generation
- ✅ INSERT query generation
- ✅ UPDATE query generation
- ✅ DELETE query generation
- ✅ COUNT query generation

#### Relationship Queries
- ✅ hasMany query pattern
- ✅ belongsTo query pattern
- ✅ JOIN queries for relationships
- ✅ Multiple JOIN queries

#### Complex Queries
- ✅ Multiple JOINs with aggregations
- ✅ WHERE IN clauses
- ✅ Date comparisons
- ✅ NULL checks
- ✅ LIKE operators
- ✅ GROUP BY with HAVING

#### Pagination
- ✅ First page queries
- ✅ Subsequent page queries
- ✅ LIMIT and OFFSET calculation

#### Analytics
- ✅ Aggregation queries (COUNT, AVG, MAX, MIN)
- ✅ GROUP BY queries
- ✅ HAVING clauses

#### Batch Operations
- ✅ Multiple INSERT generation

#### Integration
- ✅ Entity to query builder integration
- ✅ Table name usage from entities

#### Security
- ✅ SQL injection prevention in WHERE
- ✅ SQL injection prevention in INSERT
- ✅ Parameterized query verification

## Running Tests

### Quick Start
```bash
# Run all tests
dart test

# Run with detailed output
dart test --reporter=expanded
```

### Using Test Runner Script
```bash
# Make executable (first time only)
chmod +x test_runner.sh

# Run all tests
./test_runner.sh

# Run specific test suite
./test_runner.sh query-builder
./test_runner.sh entity
./test_runner.sh manager

# Run with coverage
./test_runner.sh coverage

# Watch mode (auto-run on changes)
./test_runner.sh watch
```

### Run Specific Tests
```bash
# Run specific file
dart test test/query_builder_test.dart

# Run specific test group
dart test --name "QueryBuilder - SELECT queries"

# Run specific test
dart test --name "should build simple SELECT query"
```

## Example Test Output

```
✓ QueryBuilder - SELECT queries should build simple SELECT query
✓ QueryBuilder - SELECT queries should build SELECT with specific columns
✓ QueryBuilder - SELECT queries should build SELECT with WHERE clause
✓ QueryBuilder - SELECT queries should build SELECT with multiple WHERE clauses
...

✓ UserEntity should have correct table name
✓ UserEntity should convert to map correctly
✓ UserEntity should create from map correctly
...

✓ DatabaseManagerQuery - Query Generation should generate correct SELECT query for findAll
✓ DatabaseManagerQuery - Query Generation should generate correct INSERT query
...

All tests passed!
```

## What These Tests Verify

### ✅ SQL Correctness
Every test verifies that generated SQL:
- Has correct syntax
- Uses proper table/column names
- Includes all necessary clauses
- Orders clauses correctly (SELECT, FROM, JOIN, WHERE, GROUP BY, HAVING, ORDER BY, LIMIT, OFFSET)

### ✅ Parameter Safety
Tests ensure:
- All values are parameterized (not inline)
- Parameters have unique names
- SQL injection is prevented
- Parameters match expected values

### ✅ Entity Behavior
Tests verify:
- Correct table names
- Proper field mapping (snake_case ↔ camelCase)
- Null handling
- Type conversions
- copyWith functionality

### ✅ Query Builder Features
Tests cover:
- All query types (SELECT, INSERT, UPDATE, DELETE)
- All WHERE operators
- All JOIN types
- Aggregations and grouping
- Pagination
- Method chaining

## Example Test Cases

### Query Builder Test
```dart
test('should build SELECT with WHERE clause', () {
  final builder = QueryBuilder()
      .table('users')
      .where('email', 'test@example.com');
  final sql = builder.buildSelect();

  expect(sql, equals('SELECT * FROM users WHERE email = @param_0'));
  expect(builder.parameters['param_0'], equals('test@example.com'));
});
```

### Entity Test
```dart
test('should convert to map correctly', () {
  final user = UserEntity(
    id: 1,
    email: 'test@example.com',
  );

  final map = user.toMap();

  expect(map['id'], equals(1));
  expect(map['email'], equals('test@example.com'));
});
```

### Manager Query Test
```dart
test('should generate correct SELECT query for findAll', () {
  final builder = QueryBuilder()
      .table('users')
      .where('status', 'active')
      .orderBy('created_at', direction: 'DESC')
      .limit(10);

  final sql = builder.buildSelect();

  expect(sql, contains('WHERE status = @param_0'));
  expect(sql, contains('ORDER BY created_at DESC'));
  expect(sql, contains('LIMIT 10'));
});
```

## Benefits of These Tests

### 🚀 Fast Execution
- No database setup required
- No network I/O
- Pure logic testing
- Runs in 1-2 seconds

### 🔒 Reliable
- Deterministic results
- No external dependencies
- No flaky tests
- Works offline

### 🛡️ Security Verification
- Ensures SQL injection prevention
- Verifies parameterized queries
- Validates input sanitization

### 📝 Documentation
- Tests serve as usage examples
- Show expected SQL patterns
- Demonstrate API usage

### 🔄 CI/CD Friendly
- Fast enough for every commit
- No infrastructure needed
- Easy to integrate
- Clear pass/fail results

## Coverage Report

Generate coverage report:
```bash
./test_runner.sh coverage

# View coverage
open coverage/lcov.info
```

## Adding New Tests

When adding new features:

1. **Add to query_builder_test.dart** for new SQL patterns
2. **Add to entity_test.dart** for new entity models
3. **Add to database_manager_query_test.dart** for new query logic

Template:
```dart
group('New Feature', () {
  test('should do something', () {
    // Arrange
    final builder = QueryBuilder().table('table_name');
    
    // Act
    final sql = builder.newMethod();
    
    // Assert
    expect(sql, equals('expected SQL'));
    expect(builder.parameters, hasExpectedValues);
  });
});
```

## Continuous Integration

Add to your CI pipeline:

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - name: Install dependencies
        run: |
          cd dart_cloud_backend/packages/database
          dart pub get
      - name: Run tests
        run: |
          cd dart_cloud_backend/packages/database
          dart test
```

## Troubleshooting

### Tests fail after code changes
1. Check if SQL generation logic changed
2. Update test expectations if intentional
3. Verify parameter binding is correct

### New feature not covered
1. Add tests before implementing
2. Follow TDD approach
3. Ensure >90% coverage

### Slow test execution
1. Tests should run in <5 seconds
2. Check for accidental database connections
3. Ensure no network calls

## Best Practices

✅ **DO**:
- Write tests before implementing features
- Keep tests focused and isolated
- Use descriptive test names
- Test edge cases and error conditions
- Maintain high coverage

❌ **DON'T**:
- Connect to real databases in unit tests
- Make network calls
- Use sleep/delays
- Share state between tests
- Skip error cases

## Next Steps

For integration testing with a real database:
1. Create separate integration test suite
2. Use test database
3. Test actual query execution
4. Verify data persistence
5. Test transactions

See `integration_tests/` directory (if available) for database integration tests.
