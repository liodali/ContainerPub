import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Abstract interface for file system operations
///
/// This abstraction allows for:
/// - Easy mocking in tests
/// - Decoupling from dart:io
abstract class FileSystem {
  /// Write content to a file
  Future<void> writeFile(String filePath, String content);

  /// Read content from a file
  Future<String> readFile(String filePath);

  /// Check if a file exists
  Future<bool> fileExists(String filePath);

  /// Create a temporary directory
  Directory createTempDirectory(String prefix);

  /// Delete a directory recursively
  Future<void> deleteDirectory(String dirPath);

  /// Delete a directory recursively
  Future<void> deleteFile(String filePath);

  /// Join path segments
  String joinPath(String part1, String part2);
}

/// Real file system implementation using dart:io
class RealFileSystem implements FileSystem {
  const RealFileSystem();

  @override
  Future<void> writeFile(String filePath, String content) async {
    await File(filePath).writeAsString(content);
  }

  @override
  Future<String> readFile(String filePath) async {
    return File(filePath).readAsString();
  }

  @override
  Future<bool> fileExists(String filePath) async {
    return File(filePath).exists();
  }

  @override
  Directory createTempDirectory(String prefix) {
    return Directory.systemTemp.createTempSync(prefix);
  }

  @override
  Future<void> deleteDirectory(String dirPath) async {
    await Directory(dirPath).delete(recursive: true);
  }

  @override
  String joinPath(String part1, String part2) {
    return path.join(part1, part2);
  }

  @override
  Future<void> deleteFile(String filePath) => File(filePath).delete();
}

/// Helper class for managing request files
class RequestFileManager {
  final FileSystem _fileSystem;

  const RequestFileManager(this._fileSystem);

  /// Create a request file with the given input data
  ///
  /// Returns the path to the created file and the temp directory
  Future<({String filePath, String tempDirPath})> createRequestFile(
    Map<String, dynamic> input,
  ) async {
    final tempDir = _fileSystem.createTempDirectory('dart_cloud_request_');
    final filePath = _fileSystem.joinPath(tempDir.path, 'request.json');
    await _fileSystem.writeFile(filePath, jsonEncode(input));
    return (filePath: filePath, tempDirPath: tempDir.path);
  }

  /// Clean up a temporary directory
  Future<void> cleanup(String tempDirPath) async {
    try {
      await _fileSystem.deleteDirectory(tempDirPath);
    } catch (e) {
      // Best-effort cleanup
      print('Failed to cleanup temp directory: $e');
    }
  }
}
