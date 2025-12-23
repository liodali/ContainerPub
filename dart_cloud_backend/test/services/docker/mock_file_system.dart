import 'dart:io';

import 'package:dart_cloud_backend/services/docker/docker.dart';

/// Mock implementation of FileSystem for testing
///
/// Stores files in memory instead of writing to disk.
///
/// **Usage:**
/// ```dart
/// final mockFs = MockFileSystem();
///
/// // Pre-populate files
/// mockFs.files['/path/to/file.txt'] = 'file contents';
///
/// // Use in tests
/// final service = DockerService(fileSystem: mockFs);
///
/// // Verify file was written
/// expect(mockFs.files['/path/to/Dockerfile'], contains('FROM dart:stable'));
/// ```
class MockFileSystem extends FileSystem {
  /// In-memory file storage
  final Map<String, String> files = {};

  /// Track created temp directories
  final List<String> createdTempDirs = [];

  /// Track deleted directories
  final List<String> deletedDirs = [];

  /// Counter for temp directory names
  int _tempDirCounter = 0;

  /// Base path for temp directories
  final String tempBasePath;

  MockFileSystem({this.tempBasePath = '/tmp/mock'});

  @override
  Future<void> writeFile(String filePath, String content) async {
    files[filePath] = content;
  }

  @override
  Future<String> readFile(String filePath) async {
    final content = files[filePath];
    if (content == null) {
      throw FileSystemException('File not found', filePath);
    }
    return content;
  }

  @override
  Future<bool> fileExists(String filePath) async {
    return files.containsKey(filePath);
  }

  @override
  Directory createTempDirectory(String prefix) {
    final dirPath = '$tempBasePath/${prefix}_${_tempDirCounter++}';
    createdTempDirs.add(dirPath);
    return _MockDirectory(dirPath);
  }

  @override
  Future<void> deleteDirectory(String dirPath) async {
    deletedDirs.add(dirPath);
    // Remove all files in this directory
    files.removeWhere((key, _) => key.startsWith(dirPath));
  }

  @override
  String joinPath(String part1, String part2) {
    if (part1.endsWith('/')) {
      return '$part1$part2';
    }
    return '$part1/$part2';
  }

  /// Reset the mock state
  void reset() {
    files.clear();
    createdTempDirs.clear();
    deletedDirs.clear();
    _tempDirCounter = 0;
  }

  /// Check if a file was written
  bool wasFileWritten(String filePath) {
    return files.containsKey(filePath);
  }

  /// Get file content
  String? getFileContent(String filePath) {
    return files[filePath];
  }

  @override
  Future<void> deleteFile(String filePath) async {
    files.remove(filePath);
  }

  @override
  String joinPaths(String part1, List<String> part2) {
    return [part1, ...part2].join('/');
  }
}

/// Mock Directory implementation
class _MockDirectory implements Directory {
  @override
  final String path;

  _MockDirectory(this.path);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return sensible defaults for common methods
    if (invocation.memberName == #existsSync) return true;
    if (invocation.memberName == #exists) return Future.value(true);
    return super.noSuchMethod(invocation);
  }
}
