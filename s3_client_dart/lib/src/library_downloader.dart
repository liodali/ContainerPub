import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';

/// Downloads and extracts the native library from GitHub releases
class LibraryDownloader {
  static const String _githubRepo = 'liodali/ContainerPub';
  static const String _defaultVersion = 'latest';

  /// Downloads the appropriate native library for the current platform
  /// 
  /// [version] - The release version to download (e.g., 'v1.0.0' or 'latest')
  /// [targetDir] - Directory where the library should be saved
  /// 
  /// Returns the path to the downloaded library file
  static Future<String> downloadLibrary({
    String version = _defaultVersion,
    String? targetDir,
  }) async {
    final platform = _getPlatformInfo();
    final libDir = targetDir ?? await _getDefaultLibraryDir();
    
    // Create directory if it doesn't exist
    final dir = Directory(libDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final libraryPath = path.join(libDir, platform.libraryName);
    
    // Check if library already exists
    if (File(libraryPath).existsSync()) {
      print('Library already exists at: $libraryPath');
      return libraryPath;
    }

    print('Downloading ${platform.libraryName} for ${platform.os}...');

    // Get download URL
    final downloadUrl = await _getDownloadUrl(version, platform);
    
    // Download the archive
    print('Downloading from: $downloadUrl');
    final response = await http.get(Uri.parse(downloadUrl));
    
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download library: HTTP ${response.statusCode}\n'
        'URL: $downloadUrl',
      );
    }

    // Extract the library
    await _extractLibrary(response.bodyBytes, libraryPath, platform);
    
    print('✅ Library downloaded successfully to: $libraryPath');
    return libraryPath;
  }

  /// Gets the download URL for the library
  static Future<String> _getDownloadUrl(
    String version,
    _PlatformInfo platform,
  ) async {
    String releaseTag;
    
    if (version == _defaultVersion) {
      // Get latest release
      final apiUrl = 'https://api.github.com/repos/$_githubRepo/releases/latest';
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch latest release info');
      }
      
      // Parse JSON to get tag name
      final jsonStr = response.body;
      final tagMatch = RegExp(r'"tag_name":\s*"([^"]+)"').firstMatch(jsonStr);
      
      if (tagMatch == null) {
        throw Exception('Could not parse release tag from response');
      }
      
      releaseTag = tagMatch.group(1)!;
    } else {
      releaseTag = version.startsWith('v') ? version : 'v$version';
    }

    return 'https://github.com/$_githubRepo/releases/download/$releaseTag/${platform.archiveName}';
  }

  /// Extracts the library from the downloaded archive
  static Future<void> _extractLibrary(
    List<int> archiveBytes,
    String targetPath,
    _PlatformInfo platform,
  ) async {
    if (platform.os == 'windows') {
      // Extract ZIP
      final archive = ZipDecoder().decodeBytes(archiveBytes);
      
      for (final file in archive) {
        if (file.name.endsWith(platform.libraryName)) {
          final outputFile = File(targetPath);
          outputFile.writeAsBytesSync(file.content as List<int>);
          break;
        }
      }
    } else {
      // Extract TAR.GZ
      final archive = TarDecoder().decodeBytes(
        GZipDecoder().decodeBytes(archiveBytes),
      );
      
      for (final file in archive) {
        if (file.name == platform.libraryName) {
          final outputFile = File(targetPath);
          outputFile.writeAsBytesSync(file.content as List<int>);
          
          // Make executable on Unix systems
          if (platform.os != 'windows') {
            await Process.run('chmod', ['+x', targetPath]);
          }
          break;
        }
      }
    }
  }

  /// Gets the default directory for storing libraries
  static Future<String> _getDefaultLibraryDir() async {
    final homeDir = Platform.environment['HOME'] ?? 
                    Platform.environment['USERPROFILE'] ?? 
                    Directory.current.path;
    
    return path.join(homeDir, '.s3_client_dart', 'lib');
  }

  /// Gets platform-specific information
  static _PlatformInfo _getPlatformInfo() {
    if (Platform.isMacOS) {
      return _PlatformInfo(
        os: 'darwin',
        arch: 'amd64',
        libraryName: 's3_client_dart.dylib',
        archiveName: 's3_client_dart-darwin-amd64.tar.gz',
      );
    } else if (Platform.isLinux) {
      return _PlatformInfo(
        os: 'linux',
        arch: 'amd64',
        libraryName: 's3_client_dart.so',
        archiveName: 's3_client_dart-linux-amd64.tar.gz',
      );
    } else if (Platform.isWindows) {
      return _PlatformInfo(
        os: 'windows',
        arch: 'amd64',
        libraryName: 's3_client_dart.dll',
        archiveName: 's3_client_dart-windows-amd64.zip',
      );
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }
  }

  /// Checks if the library exists at the given path
  static bool libraryExists(String libraryPath) {
    return File(libraryPath).existsSync();
  }

  /// Gets the default library path for the current platform
  static Future<String> getDefaultLibraryPath() async {
    final platform = _getPlatformInfo();
    final libDir = await _getDefaultLibraryDir();
    return path.join(libDir, platform.libraryName);
  }
}

class _PlatformInfo {
  final String os;
  final String arch;
  final String libraryName;
  final String archiveName;

  _PlatformInfo({
    required this.os,
    required this.arch,
    required this.libraryName,
    required this.archiveName,
  });
}
