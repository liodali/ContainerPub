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
  File createFunctionArchive(String functionName) {
    final archivePath = path.join(Directory.current.path, '$functionName.zip');

    final archive = buildFunctionArchive(functionName);

    // Encode to zip
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('Failed to encode archive');
    }

    // Write to file
    final archiveFile = File(archivePath);
    archiveFile.writeAsBytesSync(zipData);

    return archiveFile;
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
    archiveFile.lastModTime =
        file.lastModifiedSync().millisecondsSinceEpoch ~/ 1000;

    addFile(archiveFile);
  }
}
