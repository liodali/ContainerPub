# Analyzer Plugin Tests

This directory contains comprehensive tests for the Dart Cloud Function Analyzer Plugin.

## Test Structure

The tests are organized into groups, one for each lint rule:

### 1. MissingCloudFunctionAnnotationRule Tests

Tests the detection of classes extending `CloudDartFunction` without the `@cloudFunction` annotation.

**Test Cases:**
- ✅ Detects missing annotation on CloudDartFunction classes
- ✅ Passes when annotation is present
- ✅ Ignores classes not extending CloudDartFunction

### 2. MultipleCloudFunctionAnnotationRule Tests

Tests the detection of duplicate `@cloudFunction` annotations.

**Test Cases:**
- ✅ Detects multiple annotations on the same class
- ✅ Passes when only one annotation is present

### 3. NoMainFunctionRule Tests

Tests the detection of `main()` functions in cloud function files.

**Test Cases:**
- ✅ Detects main() in files containing CloudDartFunction classes
- ✅ Passes when no main() exists
- ✅ Ignores main() in regular (non-cloud-function) files

### 4. Plugin Registration Tests

Tests the plugin's basic configuration and registration.

**Test Cases:**
- ✅ Plugin has correct name
- ✅ Plugin is properly instantiated

## Running Tests

To run all tests:

```bash
dart test
```

To run a specific test file:

```bash
dart test test/dart_cloud_function_analyzer_plugin_test.dart
```

To run tests with coverage:

```bash
dart test --coverage=coverage
dart pub global activate coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

## Test Implementation

The tests use custom AST visitors (`_TestMissingAnnotationVisitor`, `_TestMultipleAnnotationVisitor`, `_TestNoMainFunctionVisitor`) that mimic the behavior of the actual lint rules. This approach:

1. **Parses Dart code** using `parseString()` from the analyzer package
2. **Visits AST nodes** using custom visitors that implement the same logic as the rules
3. **Asserts expected behavior** using the `test` package

## Adding New Tests

When adding new lint rules, follow this pattern:

1. Create a new test group for the rule
2. Write test cases for:
   - Positive cases (should trigger the rule)
   - Negative cases (should not trigger the rule)
   - Edge cases
3. Create a test visitor that implements the rule's logic
4. Use `parseString()` to parse test code
5. Assert the visitor's findings

Example:

```dart
group('MyNewRule', () {
  test('should detect the issue', () async {
    const code = '''
    // Your test code here
    ''';
    
    final result = await parseString(content: code);
    final visitor = _TestMyNewRuleVisitor();
    result.unit.accept(visitor);
    
    expect(visitor.foundIssue, isTrue);
  });
});
```

## CI/CD Integration

These tests are designed to run in CI/CD pipelines. Ensure:

- All tests pass before merging
- Test coverage remains above 80%
- No flaky tests are introduced
