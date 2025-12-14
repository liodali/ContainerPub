import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

/// Extension methods for creating function archives
extension ArchiveUtils on Directory {
  /// Creates a zip archive containing only allowed files and directories
  /// Includes: .dart files from lib/ and bin/, plus pubspec.yaml, pubspec.lock, .env
  Archive buildFunctionArchive(String functionName) {
    final archive = Archive();
    int filesAdded = 0;

    // Directories to scan for .dart files
    const dartDirectories = ['lib', 'bin'];

    // Root config files to include
    const configFiles = ['pubspec.yaml', 'pubspec.lock', '.env'];

    // Add .dart files from lib/ and bin/ directories
    for (final dirName in dartDirectories) {
      final dir = Directory(path.join(this.path, dirName));
      if (dir.existsSync()) {
        final dartFiles = dir.collectDartFiles();
        for (final file in dartFiles) {
          archive.addFileFromPath(file, this.path);
          filesAdded++;
        }
      }
    }

    // Add config files from root
    for (final fileName in configFiles) {
      final file = File(path.join(this.path, fileName));
      if (file.existsSync()) {
        archive.addFileFromPath(file, this.path);
        filesAdded++;
      }
    }

    if (filesAdded == 0) {
      throw Exception(
        'No files found to archive. Ensure lib/ or bin/ directories contain .dart files.',
      );
    }

    // return archive
    return archive;
  }

  /// Creates a zip archive containing only allowed files and directories
  /// Includes: .dart files from lib/ and bin/, plus pubspec.yaml, pubspec.lock, .env
  Future<(File, String)> createFunctionArchive(String functionName) async {
    // final dirArchive = path.join(functDir, 'data/app/functions/archives');
    // if (!(await Directory(dirArchive).exists())) {
    //   await Directory(dirArchive).create(recursive: true);
    // }
    final archivePath = path.join(this.path, '$functionName.zip');

    final archive = buildFunctionArchive(functionName);

    // Encode to zip
    final zipData = ZipEncoder().encode(archive);

    // Write to file
    final archiveFile = File(archivePath);
    await archiveFile.writeAsBytes(zipData);

    return (archiveFile, archivePath);
  }

  /// Recursively collects all .dart files from this directory
  List<File> collectDartFiles() {
    final dartFiles = <File>[];
    final entities = listSync(recursive: true);

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity);
      }
    }
    return dartFiles;
  }
}

/// Extension methods for Archive
extension ArchiveExtension on Archive {
  /// Adds a single file to the archive with proper relative path
  void addFileFromPath(File file, String basePath) {
    final relativePath = path.relative(file.path, from: basePath);
    final bytes = file.readAsBytesSync();

    final archiveFile = ArchiveFile(
      relativePath,
      bytes.length,
      bytes,
    );

    // Set file permissions (0644 for files)
    archiveFile.mode = 0644;
    archiveFile.lastModTime = file.lastModifiedSync().millisecondsSinceEpoch ~/ 1000;

    addFile(archiveFile);
  }
}

/// Utility class for archive operations
class ArchiveUtility {
  /// Extract a zip file from the given path to a specific destination directory
  static Future<void> extractZipFile(String zipPath, String destinationPath) async {
    try {
      // Validate zip file exists
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw FileSystemException('Zip file not found', zipPath);
      }

      // Read zip file bytes
      final zipBytes = await zipFile.readAsBytes();

      // Decode zip archive
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Create destination directory if it doesn't exist
      final destinationDir = Directory(destinationPath);
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      // Extract all files from archive
      for (final file in archive) {
        final filePath = path.join(destinationPath, file.name);
        final fileDir = Directory(path.dirname(filePath));

        // Create parent directories if needed
        if (!await fileDir.exists()) {
          await fileDir.create(recursive: true);
        }

        // Write file if it's not a directory
        if (!file.isFile) continue;

        final outputFile = File(filePath);
        await outputFile.writeAsBytes(file.content as List<int>);
      }
    } catch (e) {
      throw Exception('Failed to extract zip file: $e');
    }
  }

  /// Extract a zip file and return the list of extracted file paths
  static Future<List<String>> extractZipFileWithPaths(
    String zipPath,
    String destinationPath,
  ) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw FileSystemException('Zip file not found', zipPath);
      }

      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      final destinationDir = Directory(destinationPath);
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      final extractedPaths = <String>[];

      for (final file in archive) {
        final filePath = path.join(destinationPath, file.name);
        final fileDir = Directory(path.dirname(filePath));

        if (!await fileDir.exists()) {
          await fileDir.create(recursive: true);
        }

        if (!file.isFile) continue;

        final outputFile = File(filePath);
        await outputFile.writeAsBytes(file.content as List<int>);
        extractedPaths.add(filePath);
      }

      return extractedPaths;
    } catch (e) {
      throw Exception('Failed to extract zip file: $e');
    }
  }
}
