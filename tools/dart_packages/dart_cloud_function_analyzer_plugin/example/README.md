# Cloud Function Analyzer Plugin Examples

This directory contains examples demonstrating the analyzer plugin rules.

## Good Example

**File:** `good_example.dart`

Shows a correctly structured cloud function:
- ✅ Has `@cloudFunction` annotation
- ✅ Extends `CloudDartFunction`
- ✅ No `main()` function

## Bad Examples

### Missing Annotation

**File:** `bad_example_missing_annotation.dart`

**Lint Error:** `missing_cloud_function_annotation`

**Problem:** Class extends `CloudDartFunction` but lacks `@cloudFunction` annotation

**Fix:** Add `@cloudFunction` annotation above the class declaration

### Multiple Annotations

**File:** `bad_example_multiple_annotations.dart`

**Lint Error:** `multiple_cloud_function_annotations`

**Problem:** Class has duplicate `@cloudFunction` annotations

**Fix:** Remove duplicate annotations, keep only one

### Main Function Present

**File:** `bad_example_with_main.dart`

**Lint Error:** `no_main_function_in_cloud_function`

**Problem:** Cloud function file contains a `main()` function

**Fix:** Remove the `main()` function - cloud functions are invoked by the runtime, not via a main entry point

## Testing the Plugin

To see the plugin in action:

1. Ensure the plugin is properly configured in your `analysis_options.yaml`
2. Open any of the bad example files in your IDE
3. You should see lint errors highlighted
4. Run `dart analyze` to see all errors in the terminal

## Plugin Rules

| Rule Name | Description |
|-----------|-------------|
| `missing_cloud_function_annotation` | Detects classes extending CloudDartFunction without @cloudFunction |
| `multiple_cloud_function_annotations` | Detects duplicate @cloudFunction annotations |
| `no_main_function_in_cloud_function` | Detects main() functions in cloud function files |
