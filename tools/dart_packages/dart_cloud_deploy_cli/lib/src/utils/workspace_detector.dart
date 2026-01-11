import 'dart:io';
import 'package:path/path.dart' as p;

class WorkspaceDetector {
  static const String _dartToolDir = '.dart_tool';
  static const String _configFileName = 'deploy_config.yaml';

  /// Detect if current directory or parent is a Dart project
  static Future<WorkspaceInfo> detectWorkspace({String? workspacePath}) async {
    final startPath = workspacePath ?? Directory.current.path;

    // Check current directory
    if (await _isDartProject(startPath)) {
      return WorkspaceInfo(
        path: startPath,
        isDartProject: true,
        configPath: p.join(startPath, _dartToolDir, _configFileName),
      );
    }

    // Check parent directory (level -1)
    final parentPath = Directory(startPath).parent.path;
    if (await _isDartProject(parentPath)) {
      return WorkspaceInfo(
        path: parentPath,
        isDartProject: true,
        configPath: p.join(parentPath, _dartToolDir, _configFileName),
        isParent: true,
      );
    }

    // Not a Dart project, use current directory
    return WorkspaceInfo(
      path: startPath,
      isDartProject: false,
      configPath: p.join(startPath, 'deploy.yaml'),
    );
  }

  static Future<bool> _isDartProject(String path) async {
    final pubspecFile = File(p.join(path, 'pubspec.yaml'));
    return pubspecFile.existsSync();
  }

  static Future<void> ensureDartToolExists(String projectPath) async {
    final dartToolDir = Directory(p.join(projectPath, _dartToolDir));
    if (!await dartToolDir.exists()) {
      await dartToolDir.create(recursive: true);
    }
  }

  static String getConfigPath(String projectPath) {
    return p.join(projectPath, _dartToolDir, _configFileName);
  }
}

class WorkspaceInfo {
  final String path;
  final bool isDartProject;
  final String configPath;
  final bool isParent;

  WorkspaceInfo({
    required this.path,
    required this.isDartProject,
    required this.configPath,
    this.isParent = false,
  });

  String get description {
    if (isParent) {
      return 'parent Dart project';
    } else if (isDartProject) {
      return 'Dart project';
    } else {
      return 'current directory';
    }
  }

  bool get configExists => File(configPath).existsSync();
}
