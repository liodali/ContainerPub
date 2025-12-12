---
title: Analyzer Rules
description: Code validation rules enforced during function deployment
---

# Analyzer Rules

This document describes the validation rules enforced by the `dart_cloud_cli` analyzer during function deployment.

## Overview

The analyzer performs static code analysis on your function before deployment to ensure:

1. **Structural compliance** - Correct CloudDartFunction structure
2. **Security** - No dangerous operations or imports
3. **Best practices** - Proper annotations and patterns

## Structural Rules (STRICT)

These rules are **strictly enforced** and will cause deployment to fail if violated.

### 1. Exactly One CloudDartFunction Class

**Rule:** Your `main.dart` must contain exactly one class that extends `CloudDartFunction`.

**Error Messages:**

- `No CloudDartFunction class found. You must have exactly one class extending CloudDartFunction`
- `Multiple CloudDartFunction classes found (N). Only one class extending CloudDartFunction is allowed`

**Valid Example:**

```dart
@cloudFunction
class MyFunction extends CloudDartFunction { ... }
```

**Invalid Example:**

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

**Valid Example:**

```dart
@cloudFunction
class MyFunction extends CloudDartFunction { ... }
```

**Invalid Example:**

```dart
class MyFunction extends CloudDartFunction { ... }  // Missing annotation
```

### 3. No main() Function

**Rule:** Your `main.dart` must NOT contain a `main()` function.

**Error Message:**

- `main() function is not allowed. Remove the main function from your code`

**Rationale:** The cloud platform handles function invocation. A `main()` function is unnecessary and could interfere with the runtime.

**Valid Example:**

```dart
@cloudFunction
class MyFunction extends CloudDartFunction { ... }
// No main() function
```

**Invalid Example:**

```dart
@cloudFunction
class MyFunction extends CloudDartFunction { ... }

void main() {  // ERROR!
  print('This is not allowed');
}
```

## Security Rules (STRICT)

These security checks will cause deployment to fail.

### Prohibited Operations

**Process Execution:**

- `Process.run()`
- `Process.start()`
- `Process.runSync()`
- Shell execution

**Error:** `Detected Process execution - command execution is not allowed`

### Prohibited Imports

| Import         | Reason                 | Error Message                        |
| -------------- | ---------------------- | ------------------------------------ |
| `dart:mirrors` | Reflection not allowed | `dart:mirrors import is not allowed` |
| `dart:ffi`     | FFI not allowed        | `dart:ffi import is not allowed`     |

### Prohibited Patterns

| Pattern               | Error Message                                   |
| --------------------- | ----------------------------------------------- |
| `Platform.executable` | `Detected platform script access - not allowed` |
| `Platform.script`     | `Detected platform script access - not allowed` |
| `Socket`              | `Raw socket operations are not allowed`         |
| `ServerSocket`        | `Raw socket operations are not allowed`         |

## Warnings (NON-BLOCKING)

These issues generate warnings but don't block deployment:

| Issue                  | Warning Message                                                          |
| ---------------------- | ------------------------------------------------------------------------ |
| File write operations  | `File write operations detected - ensure they are within function scope` |
| `dart:io` import       | `dart:io import detected - ensure only HTTP operations are used`         |
| `Isolate.spawn()`      | `Isolate spawning detected - may impact performance`                     |
| Dynamic code execution | `Dynamic code execution detected: ...`                                   |

## Validation Flow

```dart
1. Validate deployment restrictions
   ├─ Check function size (< 5 MB)
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

### Successful Analysis

```dart
Analyzing function code...

⚠️  Warnings:
  - dart:io import detected - ensure only HTTP operations are used

✓ Function analysis passed
```

### Failed Analysis

```
Analyzing function code...

✗ Function validation failed:
  - Missing @cloudFunction annotation
  - main() function is not allowed
```

## Best Practices

1. **Single Responsibility** - One function per package
2. **Use Annotations** - Always add `@cloudFunction` to your class
3. **Avoid main()** - Let the platform handle invocation
4. **Safe Operations** - Use HTTP clients, not raw sockets
5. **No Shell Access** - Never execute system commands
6. **Read-Only FS** - Minimize file system writes

## Implementation Details

The analyzer uses:

- **analyzer** package for Dart AST parsing
- **RecursiveAstVisitor** for code traversal
- **Static analysis** - no code execution
- **Pattern matching** for risk detection

## See Also

- [Deployment Configuration](./deployment-config.md)
- [dart_cloud_function Package](./dart-cloud-function.md)
- [dart_cloud CLI](./dart-cloud-cli.md)
