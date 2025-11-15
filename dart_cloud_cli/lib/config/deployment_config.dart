/// Deployment configuration constants
class DeploymentConfig {
  /// Maximum function size in MB
  static const int maxFunctionSizeMB = 5;

  /// Size warning threshold in MB
  static const int sizeWarningThresholdMB = 4;

  /// Forbidden directories that cannot be deployed
  static const List<String> forbiddenDirectories = [
    '.git',
    '.github',
    '.vscode',
    '.idea',
    'node_modules',
    '.dart_tool',
    'build',
    '.gradle',
    '.cocoapods',
  ];

  /// Forbidden files that cannot be deployed
  static const List<String> forbiddenFiles = [
    '.env',
    '.env.local',
    'secrets.json',
    'credentials.json',
  ];

  /// Forbidden file patterns (regex)
  static const List<String> forbiddenFilePatterns = [
    r'.*\.pem$',
    r'.*\.key$',
    r'.*\.p12$',
    r'.*\.pfx$',
    r'.*\.env\..*\.local$',
  ];

  /// Required files for deployment
  static const List<String> requiredFiles = [
    'pubspec.yaml',
  ];

  /// Required entry points (one of these must exist)
  static const List<String> requiredEntryPoints = [
    'main.dart',
    'bin/main.dart',
  ];

  /// Security restrictions
  static const SecurityConfig security = SecurityConfig();

  /// Get all configuration as JSON
  static Map<String, dynamic> toJson() => {
        'maxFunctionSizeMB': maxFunctionSizeMB,
        'sizeWarningThresholdMB': sizeWarningThresholdMB,
        'forbiddenDirectories': forbiddenDirectories,
        'forbiddenFiles': forbiddenFiles,
        'forbiddenFilePatterns': forbiddenFilePatterns,
        'requiredFiles': requiredFiles,
        'requiredEntryPoints': requiredEntryPoints,
        'security': security.toJson(),
      };
}

/// Security configuration
class SecurityConfig {
  /// Forbidden imports
  static const List<String> forbiddenImports = [
    'dart:mirrors',
    'dart:ffi',
  ];

  /// Dangerous operations to detect
  static const List<String> dangerousOperations = [
    'Process.run',
    'Process.start',
    'Process.runSync',
  ];

  /// Dangerous patterns
  static const List<String> dangerousPatterns = [
    'Shell',
    'bash',
    'Platform.executable',
    'Platform.script',
    'Socket',
    'ServerSocket',
  ];

  const SecurityConfig();

  Map<String, dynamic> toJson() => {
        'forbiddenImports': forbiddenImports,
        'dangerousOperations': dangerousOperations,
        'dangerousPatterns': dangerousPatterns,
      };
}

/// Deployment validation rules
class DeploymentRules {
  /// Check if size is within limits
  static bool isValidSize(double sizeMB) {
    return sizeMB <= DeploymentConfig.maxFunctionSizeMB;
  }

  /// Check if size should trigger warning
  static bool shouldWarnAboutSize(double sizeMB) {
    return sizeMB > DeploymentConfig.sizeWarningThresholdMB &&
        sizeMB <= DeploymentConfig.maxFunctionSizeMB;
  }

  /// Check if directory is forbidden
  static bool isForbiddenDirectory(String dirName) {
    return DeploymentConfig.forbiddenDirectories.contains(dirName);
  }

  /// Check if file is forbidden
  static bool isForbiddenFile(String fileName) {
    // Check exact matches
    if (DeploymentConfig.forbiddenFiles.contains(fileName)) {
      return true;
    }

    // Check patterns
    for (final pattern in DeploymentConfig.forbiddenFilePatterns) {
      if (RegExp(pattern).hasMatch(fileName)) {
        return true;
      }
    }

    return false;
  }

  /// Check if import is forbidden
  static bool isForbiddenImport(String import) {
    return SecurityConfig.forbiddenImports.contains(import);
  }

  /// Check if operation is dangerous
  static bool isDangerousOperation(String operation) {
    return SecurityConfig.dangerousOperations.contains(operation);
  }

  /// Check if pattern is dangerous
  static bool isDangerousPattern(String pattern) {
    return SecurityConfig.dangerousPatterns.contains(pattern);
  }
}
