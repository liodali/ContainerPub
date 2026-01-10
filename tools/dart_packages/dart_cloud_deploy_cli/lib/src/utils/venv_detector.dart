import 'dart:io';
import 'package:path/path.dart' as p;
import 'config_paths.dart';

class VenvDetector {
  static Future<VenvLocation> detectVenvLocation() async {
    final currentDir = Directory.current.path;

    // Check parent directory for existing .venv
    final parentDir = Directory(currentDir).parent.path;
    final parentVenvPath = p.join(parentDir, '.venv');

    if (await _isValidVenv(parentVenvPath)) {
      return VenvLocation(
        path: parentVenvPath,
        isParent: true,
        isConfig: false,
      );
    }

    // Check current directory for existing .venv
    final currentVenvPath = p.join(currentDir, '.venv');
    if (await _isValidVenv(currentVenvPath)) {
      return VenvLocation(
        path: currentVenvPath,
        isParent: false,
        isConfig: false,
      );
    }

    // Check config directory for existing venv
    final configVenvPath = ConfigPaths.venvDir;
    if (await _isValidVenv(configVenvPath)) {
      return VenvLocation(
        path: configVenvPath,
        isParent: false,
        isConfig: true,
      );
    }

    // Default: use config directory for new venv
    return VenvLocation(
      path: configVenvPath,
      isParent: false,
      isConfig: true,
    );
  }

  static Future<bool> _isValidVenv(String venvPath) async {
    final pythonPath = Platform.isWindows
        ? p.join(venvPath, 'Scripts', 'python.exe')
        : p.join(venvPath, 'bin', 'python');

    return File(pythonPath).existsSync();
  }
}

class VenvLocation {
  final String path;
  final bool isParent;
  final bool isConfig;

  VenvLocation({
    required this.path,
    required this.isParent,
    required this.isConfig,
  });

  String get description {
    if (isParent) {
      return 'parent directory';
    } else if (isConfig) {
      return 'config directory';
    } else {
      return 'current directory';
    }
  }

  bool get exists => Directory(path).existsSync();
}
