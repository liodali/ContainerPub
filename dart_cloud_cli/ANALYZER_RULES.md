# Dart Cloud CLI - Analyzer Rules

This document describes the validation rules enforced by the `dart_cloud_cli` analyzer during function deployment.

## Overview

The analyzer performs static code analysis on your function before deployment to ensure:
1. **Structural compliance** - Correct CloudDartFunction structure
2. **Security** - No dangerous operations or imports
3. **Best practices** - Proper annotations and patterns

## Structural Rules (STRICT)

These rules are **strictly enforced** and will cause deployment to fail if violated:

### 1. Exactly One CloudDartFunction Class

**Rule:** Your `main.dart` must contain exactly one class that extends `CloudDartFunction`.

**Error Messages:**
- `No CloudDartFunction class found. You must have exactly one class extending CloudDartFunction`
- `Multiple CloudDartFunction classes found (N). Only one class extending CloudDartFunction is allowed`

**Example - Valid:**
```dart
@cloudFunction
class MyFunction extends CloudDartFunction { ... }
```

**Example - Invalid:**
```dart
// No CloudDartFunction class
class MyClass { }

// OR multiple classes
@cloudFunction
class Function1 extends CloudDartFunction { ... }
@cloudFunction
class Function2 extends CloudDartFunction { ... }  // ERROR!
```

### 2. @cloudFunction Annotation Required

**Rule:** The CloudDartFunction class must be annotated with `@cloudFunction`.

**Error Message:**
- `Missing @cloudFunction annotation. The CloudDartFunction class must be annotated with @cloudFunction`

**Example - Valid:**
```dart
@cloudFunction
class MyFunction extends CloudDartFunction { ... }
```

**Example - Invalid:**
```dart
class MyFunction extends CloudDartFunction { ... }  // Missing annotation
```

### 3. No main() Function

**Rule:** Your `main.dart` must NOT contain a `main()` function.

**Error Message:**
- `main() function is not allowed. Remove the main function from your code`

**Rationale:** The cloud platform handles function invocation. A `main()` function is unnecessary and could interfere with the runtime.

**Example - Valid:**
```dart
@cloudFunction
class MyFunction extends CloudDartFunction { ... }
// No main() function
```

**Example - Invalid:**
```dart
@cloudFunction
class MyFunction extends CloudDartFunction { ... }

void main() {  // ERROR!
  print('This is not allowed');
}
```

## Security Rules (STRICT)

These security checks will cause deployment to fail:

### Prohibited Operations

**Process Execution:**
- `Process.run()`
- `Process.start()`
- `Process.runSync()`
- Shell execution

**Error:** `Detected Process execution - command execution is not allowed`

### Prohibited Imports

**dart:mirrors**
- Reflection is not allowed for security reasons

**Error:** `dart:mirrors import is not allowed`

**dart:ffi**
- Foreign Function Interface is not allowed

**Error:** `dart:ffi import is not allowed`

**Platform Script Access:**
- `Platform.executable`
- `Platform.script`

**Error:** `Detected platform script access - not allowed`

**Raw Sockets:**
- `Socket`
- `ServerSocket`

**Error:** `Raw socket operations are not allowed`

## Warnings (NON-BLOCKING)

These issues generate warnings but don't block deployment:

### File Operations
- File write operations detected
- **Warning:** `File write operations detected - ensure they are within function scope`

### dart:io Usage
- General dart:io imports
- **Warning:** `dart:io import detected - ensure only HTTP operations are used`

### Isolate Spawning
- `Isolate.spawn()`
- **Warning:** `Isolate spawning detected - may impact performance`

### Dynamic Code Execution
- Methods named `eval` or `execute`
- **Warning:** `Dynamic code execution detected: ...`

## Deployment Restrictions

Before code analysis, the deployment validator checks:

### Size Limits
- **Maximum:** 5 MB
- **Warning threshold:** 4 MB
- Includes all files in the function directory

### Forbidden Directories
- `.git` - Version control
- `.github` - GitHub workflows
- `.vscode`, `.idea` - IDE configs
- `node_modules` - Node dependencies
- `.dart_tool` - Dart build artifacts
- `build`, `.gradle`, `.cocoapods` - Build directories

### Forbidden Files
- `.env`, `.env.local` - Environment files
- `secrets.json`, `credentials.json` - Credential files
- `*.pem`, `*.key`, `*.p12`, `*.pfx` - Private keys

### Required Files
- `pubspec.yaml` - Dart package manifest
- `main.dart` or `bin/main.dart` - Function entry point

## Validation Flow

```
1. Validate deployment restrictions
   ├─ Check function size (< 50 MB)
   ├─ Check for forbidden directories
   ├─ Check for forbidden files
   ├─ Verify required files exist
   └─ Check for credentials/secrets
   ↓
2. Analyze function code
   ├─ Find main.dart
   ├─ Parse and analyze AST
   ├─ Count CloudDartFunction classes
   ├─ Check for main() function
   ├─ Verify @cloudFunction annotation
   └─ Scan for security risks
   ↓
3. PASS: Create archive and upload
   FAIL: Display errors and abort
```

## Analysis Result

After analysis, you'll see:

```
Analyzing function code...

⚠️  Warnings:
  - dart:io import detected - ensure only HTTP operations are used

✓ Function analysis passed
```

Or if validation fails:

```
Analyzing function code...

✗ Function validation failed:
  - Missing @cloudFunction annotation. The CloudDartFunction class must be annotated with @cloudFunction
  - main() function is not allowed. Remove the main function from your code
```

## Best Practices

1. **Single Responsibility:** One function per package
2. **Use Annotations:** Always add `@cloudFunction` to your class
3. **Avoid main():** Let the platform handle invocation
4. **Safe Operations:** Use HTTP clients, not raw sockets
5. **No Shell Access:** Never execute system commands
6. **Read-Only FS:** Minimize file system writes

## Implementation Details

The analyzer uses:
- **analyzer** package for Dart AST parsing
- **RecursiveAstVisitor** for code traversal
- **Static analysis** - no code execution
- **Pattern matching** for risk detection

## Related Files

- `lib/services/function_analyzer.dart` - Main analyzer implementation
- `lib/commands/deploy_command.dart` - Integration with deploy flow

## See Also

- [dart_cloud_function Package](../tools/dart_packages/dart_cloud_function/)
- [dart_cloud_function README](../tools/dart_packages/dart_cloud_function/README.md)
