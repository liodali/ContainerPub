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

  /// Join path segments
  String joinPaths(String part1, List<String> part2);
}

/// Real file system implementation using dart:io
class RealFileSystem implements FileSystem {
  const RealFileSystem();

  @override
  Future<void> writeFile(String filePath, String content) => File(filePath).writeAsString(
    content,
    flush: true,
  );

  @override
  Future<String> readFile(String filePath) => File(filePath).readAsString();

  @override
  Future<bool> fileExists(String filePath) => File(filePath).exists();

  @override
  Directory createTempDirectory(String prefix) =>
      Directory.systemTemp.createTempSync(prefix);

  @override
  Future<void> deleteDirectory(String dirPath) =>
      Directory(dirPath).delete(recursive: true);

  @override
  String joinPath(String part1, String part2) => path.join(part1, part2);

  @override
  Future<void> deleteFile(String filePath) => File(filePath).delete();

  @override
  String joinPaths(String part1, List<String> part2) => path.joinAll([part1, ...part2]);
}

/// Helper class for managing request files
class RequestFileManager {
  final FileSystem _fileSystem;

  const RequestFileManager(this._fileSystem);

  /// Create a request file with the given input data
  ///
  /// Returns the path to the created file and the temp directory
  Future<({String filePath, String tempDirPath})> createRequestFile(
    String tempDir,
    Map<String, dynamic> input,
  ) async {
    print('Creating request file at $tempDir , with content $input');
    final filePath = _fileSystem.joinPath(tempDir, 'request.json');
    await _fileSystem.writeFile(filePath, jsonEncode(input));
    return (filePath: filePath, tempDirPath: tempDir);
  }

  /// Create a request file with the given input data
  ///
  /// Returns the path to the created file and the temp directory
  Future<({String filePath, String tempDirPath})> createLogsFile(
    String tempDir,
    Map<String, dynamic> input,
  ) async {
    final filePath = _fileSystem.joinPath(tempDir, 'logs.json');
    await _fileSystem.writeFile(filePath, jsonEncode(input));
    return (filePath: filePath, tempDirPath: tempDir);
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
