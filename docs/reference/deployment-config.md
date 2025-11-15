# Deployment Configuration

This document describes the deployment configuration for `dart_cloud_cli`.

## Configuration Overview

All deployment restrictions and validation rules are centralized in `dart_cloud_cli/lib/config/deployment_config.dart`.

## Size Limits

- **Maximum function size:** 5 MB
- **Warning threshold:** 4 MB

Functions exceeding 5 MB cannot be deployed. Functions between 4-5 MB will trigger a warning.

### Reducing Function Size

If your function exceeds 5 MB:

1. **Remove unnecessary directories:**
   ```bash
   rm -rf .git .dart_tool build node_modules
   ```

2. **Use `.gitignore` to exclude files:**
   ```
   .dart_tool/
   build/
   .git/
   node_modules/
   ```

3. **Minimize dependencies:**
   - Only include required packages in `pubspec.yaml`
   - Use `pub get` to install only production dependencies

4. **Remove build artifacts:**
   ```bash
   dart pub get
   dart pub upgrade
   ```

## Forbidden Directories

The following directories cannot be deployed:

- `.git` - Version control
- `.github` - GitHub workflows
- `.vscode` - VS Code settings
- `.idea` - IntelliJ settings
- `node_modules` - Node.js dependencies
- `.dart_tool` - Dart build artifacts
- `build` - Build output
- `.gradle` - Gradle build files
- `.cocoapods` - CocoaPods files

**Why?** These directories:
- Contain unnecessary files that increase size
- May contain sensitive information
- Are not needed for function execution

## Forbidden Files

The following files cannot be deployed:

### Exact Matches
- `.env` - Environment variables
- `.env.local` - Local environment overrides
- `secrets.json` - Secrets configuration
- `credentials.json` - Credentials file

### Patterns
- `*.pem` - Private keys (PEM format)
- `*.key` - Private keys
- `*.p12` - PKCS12 certificates
- `*.pfx` - PKCS12 certificates
- `.env.*.local` - Environment overrides

**Why?** These files:
- Contain sensitive credentials
- Should never be committed to version control
- Could expose secrets if deployed

## Required Files

The following files are required for deployment:

- `pubspec.yaml` - Dart package manifest

## Required Entry Points

One of the following must exist:

- `main.dart` - Function entry point in root
- `bin/main.dart` - Function entry point in bin directory

## Security Configuration

### Forbidden Imports

- `dart:mirrors` - Reflection
- `dart:ffi` - Foreign Function Interface

### Dangerous Operations

- `Process.run()` - Execute processes
- `Process.start()` - Start processes
- `Process.runSync()` - Synchronous process execution

### Dangerous Patterns

- `Shell` - Shell execution
- `bash` - Bash execution
- `Platform.executable` - Platform executable access
- `Platform.script` - Platform script access
- `Socket` - Raw socket operations
- `ServerSocket` - Server socket operations

## Configuration File Location

```dart
dart_cloud_cli/lib/config/deployment_config.dart
```

## Modifying Configuration

To change deployment restrictions:

1. Edit `dart_cloud_cli/lib/config/deployment_config.dart`
2. Update the constants in `DeploymentConfig` class
3. Rebuild the CLI

Example - Change maximum size to 10 MB:

```dart
class DeploymentConfig {
  static const int maxFunctionSizeMB = 10;  // Changed from 5
  static const int sizeWarningThresholdMB = 8;  // Changed from 4
  // ... rest of config
}
```

## Deployment Validation Flow

```
1. Check function size
   ├─ If > 5 MB → ERROR
   └─ If 4-5 MB → WARNING

2. Check for forbidden directories
   └─ If found → ERROR

3. Check for forbidden files
   └─ If found → ERROR

4. Verify required files exist
   └─ If missing → ERROR

5. Analyze code
   ├─ Check CloudDartFunction structure
   ├─ Verify @cloudFunction annotation
   ├─ Check for main() function
   └─ Scan for security risks

6. If all pass → Create archive and upload
   If any fail → Display errors and abort
```

## Common Issues

### "Function size exceeds 5 MB limit"

**Solution:**
- Remove `.git`, `.dart_tool`, `build` directories
- Check for large files (images, videos, etc.)
- Minimize dependencies

### "Forbidden directories found: .git"

**Solution:**
- Run: `rm -rf .git`
- Or add to `.gitignore` if using version control

### "Forbidden files found: .env"

**Solution:**
- Remove `.env` file
- Use environment variables instead
- Store secrets in secure configuration

### "pubspec.yaml not found"

**Solution:**
- Ensure `pubspec.yaml` exists in function root
- Run: `dart pub get` to initialize

### "main.dart or bin/main.dart not found"

**Solution:**
- Create `main.dart` in function root
- Or create `bin/main.dart`
- Must contain your `@cloudFunction` class

## Best Practices

1. **Keep it minimal** - Only include necessary files
2. **Use .gitignore** - Exclude build artifacts
3. **No secrets** - Never commit `.env` or credentials
4. **Clean before deploy** - Remove build directories
5. **Check size** - Monitor function size growth
6. **Test locally** - Verify before deployment

## See Also

- [Analyzer Rules](./analyzer-rules.md) - Code analysis rules
- [CLI Commands](./cli-commands.md) - CLI reference
