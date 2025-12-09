import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/// Generates a deterministic hash for a function's deployable content.
///
/// The hash is computed from:
/// - All .dart files in lib/ and bin/ directories
/// - pubspec.yaml and pubspec.lock
/// - .env file (if present)
///
/// Files are sorted alphabetically to ensure deterministic hashing.
class FunctionHasher {
  final String functionPath;

  FunctionHasher(this.functionPath);

  /// Generates a SHA-256 hash of all deployable files.
  ///
  /// Returns a hex-encoded hash string.
  Future<String> generateHash() async {
    final contentBuffer = StringBuffer();
    final files = await _collectDeployableFiles();

    // Sort files by relative path for deterministic ordering
    files.sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final relativePath = path.relative(file.path, from: functionPath);
      final content = await file.readAsString();

      // Include file path in hash to detect renames
      contentBuffer.writeln('--- FILE: $relativePath ---');
      contentBuffer.writeln(content);
    }

    final bytes = utf8.encode(contentBuffer.toString());
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Collects all files that would be included in a deployment.
  Future<List<File>> _collectDeployableFiles() async {
    final files = <File>[];

    // Directories to scan for .dart files
    const dartDirectories = ['lib', 'bin'];

    // Root config files to include (excluding pubspec.lock as it changes frequently)
    const configFiles = ['pubspec.yaml', '.env'];

    // Collect .dart files from lib/ and bin/
    for (final dirName in dartDirectories) {
      final dir = Directory(path.join(functionPath, dirName));
      if (dir.existsSync()) {
        final dartFiles = await _collectDartFiles(dir);
        files.addAll(dartFiles);
      }
    }

    // Collect config files from root
    for (final fileName in configFiles) {
      final file = File(path.join(functionPath, fileName));
      if (file.existsSync()) {
        files.add(file);
      }
    }

    return files;
  }

  /// Recursively collects all .dart files from a directory.
  Future<List<File>> _collectDartFiles(Directory dir) async {
    final dartFiles = <File>[];

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity);
      }
    }

    return dartFiles;
  }

  /// Compares two hashes and returns true if they are identical.
  static bool hashesMatch(String? hash1, String? hash2) {
    if (hash1 == null || hash2 == null) return false;
    return hash1 == hash2;
  }
}
