import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:dart_cloud_cli/config/deployment_config.dart';

/// Deployment restrictions validator
class DeploymentValidator {
  final String functionDir;

  DeploymentValidator(this.functionDir);

  /// Validate deployment restrictions
  Future<DeploymentValidationResult> validate() async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Check 1: Function size limit
      final size = await _calculateDirectorySize(functionDir);
      final sizeMB = size / (1024 * 1024);
      print('Function size: ${sizeMB.toStringAsFixed(2)} MB');
      if (!DeploymentRules.isValidSize(sizeMB)) {
        errors.add(
          'Function size exceeds ${DeploymentConfig.maxFunctionSizeMB} MB limit (${sizeMB.toStringAsFixed(2)} MB). Remove unnecessary files.',
        );
      } else if (DeploymentRules.shouldWarnAboutSize(sizeMB)) {
        warnings.add(
          'Function size is ${sizeMB.toStringAsFixed(2)} MB (approaching ${DeploymentConfig.sizeWarningThresholdMB} MB limit)',
        );
      }

      // Check 2: Forbidden directories
      final forbiddenDirs = await _checkForbiddenDirectories();
      if (forbiddenDirs.isNotEmpty) {
        print('Forbidden directories found: ${forbiddenDirs.join(", ")}. Remove these before deployment.');
        // errors.add(
        //   'Forbidden directories found: ${forbiddenDirs.join(", ")}. Remove these before deployment.',
        // );
      }

      // Check 3: Forbidden files
      final forbiddenFiles = await _checkForbiddenFiles();
      if (forbiddenFiles.isNotEmpty) {
        print('Forbidden files found: ${forbiddenFiles.join(", ")}. Remove these before deployment.');
        // errors.add(
        //   'Forbidden files found: ${forbiddenFiles.join(", ")}. Remove these before deployment.',
        // );
      }

      // Check 4: pubspec.yaml exists and is valid
      final pubspecFile = File(path.join(functionDir, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        errors.add('pubspec.yaml not found in function directory');
      }

      // Check 5: main.dart exists
      final mainFile = File(path.join(functionDir, 'main.dart'));
      final binMainFile = File(path.join(functionDir, 'bin', 'main.dart'));
      if (!mainFile.existsSync() && !binMainFile.existsSync()) {
        errors.add('main.dart or bin/main.dart not found');
      }

      // Check 6: No git repository
      final gitDir = Directory(path.join(functionDir, '.git'));
      if (gitDir.existsSync()) {
        warnings.add(
          '.git directory found - consider adding .gitignore to exclude it',
        );
      }

      // Check 7: No node_modules or similar
      final nodeModules = Directory(path.join(functionDir, 'node_modules'));
      if (nodeModules.existsSync()) {
        //was warning
        warnings.add('node_modules directory found - remove before deployment');
      }

      final isValid = errors.isEmpty;

      return DeploymentValidationResult(
        isValid: isValid,
        errors: errors,
        warnings: warnings,
        sizeInMB: sizeMB,
      );
    } catch (e) {
      errors.add('Validation failed: $e');
      return DeploymentValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        sizeInMB: 0,
      );
    }
  }

  /// Calculate total directory size in bytes
  Future<int> _calculateDirectorySize(String dir) async {
    int totalSize = 0;
    final directory = Directory(dir);

    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File &&
            (entity.path.endsWith('.dart') ||
                entity.path.endsWith('pubspec.yaml') ||
                entity.path.endsWith('pubspec.lock') ||
                entity.path.endsWith('.env'))) {
          totalSize += await entity.length();
        } else if (entity is Directory &&
            (entity.path == './bin' || entity.path == './lib')) {
          totalSize += await _calculateDirectorySize(entity.path);
        }
      }
    } catch (e, trace) {
      print('report this error to us, check our contact page for more info');
      print(trace);
    }
    return totalSize;
  }

  /// Check for forbidden directories
  Future<List<String>> _checkForbiddenDirectories() async {
    final found = <String>[];
    final dir = Directory(functionDir);

    try {
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final name = path.basename(entity.path);
          if (DeploymentRules.isForbiddenDirectory(name)) {
            found.add(name);
          }
        }
      }
    } catch (_) {
      // Ignore permission errors
    }

    return found;
  }

  /// Check for forbidden files
  Future<List<String>> _checkForbiddenFiles() async {
    final found = <String>[];
    final dir = Directory(functionDir);

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && !entity.path.endsWith('.dart_tool')) {
          final name = path.basename(entity.path);
          if (DeploymentRules.isForbiddenFile(name)) {
            found.add(name);
          }
        }
      }
    } catch (_) {
      // Ignore permission errors
    }

    return found.toSet().toList(); // Remove duplicates
  }
}

/// Result of deployment validation
class DeploymentValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final double sizeInMB;

  DeploymentValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.sizeInMB,
  });

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'errors': errors,
        'warnings': warnings,
        'sizeInMB': sizeInMB,
      };
}
