# Testing Guide for Dart Cloud Function Analyzer Plugin

This document provides a comprehensive guide for testing the analyzer plugin.

## Quick Start

Run all tests:
```bash
cd tools/dart_packages/dart_cloud_function_analyzer_plugin
dart test
```

## Test Coverage

The plugin includes comprehensive tests covering all three lint rules:

### Test Statistics

- **Total Test Groups**: 4
- **Total Test Cases**: 10
- **Coverage**: All lint rules and plugin registration

### Test Breakdown

| Rule | Test Cases | Coverage |
|------|-----------|----------|
| MissingCloudFunctionAnnotationRule | 3 | ✅ 100% |
| MultipleCloudFunctionAnnotationRule | 2 | ✅ 100% |
| NoMainFunctionRule | 3 | ✅ 100% |
| Plugin Registration | 2 | ✅ 100% |

## Example Files

The `example/` directory contains demonstration files:

### Good Example
- **File**: `good_example.dart`
- **Description**: Correctly structured cloud function
- **Passes**: All lint rules ✅

### Bad Examples

1. **`bad_example_missing_annotation.dart`**
   - Missing `@cloudFunction` annotation
   - Triggers: `missing_cloud_function_annotation`

2. **`bad_example_multiple_annotations.dart`**
   - Duplicate `@cloudFunction` annotations
   - Triggers: `multiple_cloud_function_annotations`

3. **`bad_example_with_main.dart`**
   - Contains prohibited `main()` function
   - Triggers: `no_main_function_in_cloud_function`

## Manual Testing

### Using the Examples

1. Open any example file in your IDE
2. Observe lint warnings/errors
3. Verify the error messages match expectations

### Testing with dart analyze

```bash
# Analyze all examples
dart analyze example/

# Analyze specific file
dart analyze example/bad_example_missing_annotation.dart
```

Expected output for bad examples:
```
Analyzing example...

  error • missing_cloud_function_annotation at example/bad_example_missing_annotation.dart:9:7
  error • multiple_cloud_function_annotations at example/bad_example_multiple_annotations.dart:10:1
  error • no_main_function_in_cloud_function at example/bad_example_with_main.dart:20:6

3 issues found.
```

## Automated Testing

### Unit Tests

The test suite uses AST visitors to verify rule behavior:

```dart
// Example test structure
test('should detect missing annotation', () async {
  const code = '''
  class TestFunction extends CloudDartFunction {
    // ... implementation
  }
  ''';
  
  final result = await parseString(content: code);
  final visitor = _TestMissingAnnotationVisitor();
  result.unit.accept(visitor);
  
  expect(visitor.foundMissingAnnotation, isTrue);
});
```

### Running Specific Tests

```bash
# Run specific test group
dart test --name "MissingCloudFunctionAnnotationRule"

# Run with verbose output
dart test --reporter expanded

# Run with coverage
dart test --coverage=coverage
```

## Integration Testing

### In a Real Project

1. Add the plugin to your project's `analysis_options.yaml`:
```yaml
analyzer:
  plugins:
    - dart_cloud_function_analyzer_plugin
```

2. Create a test cloud function file
3. Run `dart analyze`
4. Verify lint errors appear

### Expected Behavior

| Scenario | Expected Result |
|----------|----------------|
| Class extends CloudDartFunction without @cloudFunction | ❌ Error |
| Class has @cloudFunction annotation | ✅ Pass |
| Class has multiple @cloudFunction annotations | ❌ Error |
| Cloud function file contains main() | ❌ Error |
| Regular file contains main() | ✅ Pass |

## Continuous Integration

### GitHub Actions Example

```yaml
name: Test Analyzer Plugin

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - name: Install dependencies
        run: dart pub get
        working-directory: tools/dart_packages/dart_cloud_function_analyzer_plugin
      - name: Run tests
        run: dart test
        working-directory: tools/dart_packages/dart_cloud_function_analyzer_plugin
      - name: Analyze examples
        run: dart analyze example/
        working-directory: tools/dart_packages/dart_cloud_function_analyzer_plugin
```

## Debugging Tests

### Enable Verbose Output

```bash
dart test --reporter expanded --verbose-trace
```

### Debug Specific Test

```bash
dart test test/dart_cloud_function_analyzer_plugin_test.dart --name "should report error when class extends CloudDartFunction without annotation"
```

### Common Issues

1. **Import errors in examples**: Expected - examples reference `dart_cloud_function` package
2. **AST parsing errors**: Check Dart SDK version compatibility
3. **Visitor not triggered**: Verify node processor registration

## Performance Testing

The plugin should have minimal performance impact:

- **Parse time**: < 10ms per file
- **Analysis time**: < 5ms per rule per file
- **Memory usage**: < 10MB additional

Monitor performance with:
```bash
dart analyze --timing
```

## Contributing Tests

When adding new lint rules:

1. ✅ Add test group for the rule
2. ✅ Cover positive and negative cases
3. ✅ Add example files (good and bad)
4. ✅ Update this documentation
5. ✅ Ensure all tests pass

## Test Maintenance

- Review tests when analyzer package updates
- Update examples when CloudDartFunction API changes
- Keep test coverage above 80%
- Run tests before each commit
