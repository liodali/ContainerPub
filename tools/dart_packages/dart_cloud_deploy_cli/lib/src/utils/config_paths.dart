import 'dart:io';
import 'package:path/path.dart' as p;

class ConfigPaths {
  static const String _configDirName = '.dart-cloud-deploy';

  static String get homeDir {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    if (home.isEmpty) {
      throw Exception('Unable to determine home directory');
    }
    return home;
  }

  static String get configDir => p.join(homeDir, _configDirName);

  static String get globalConfigFile => p.join(configDir, 'config.yaml');

  static String get credentialsFile => p.join(configDir, 'credentials.yaml');

  static String get cacheDir => p.join(configDir, 'cache');

  static String get logsDir => p.join(configDir, 'logs');

  static String get playbooksDir => p.join(configDir, 'playbooks');

  static String get inventoryDir => p.join(configDir, 'inventory');

  static String get venvDir => p.join(configDir, 'venv');

  static String get deploymentConfigsDir => p.join(configDir, 'deployments');

  static Future<void> ensureConfigDirExists() async {
    final dir = Directory(configDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  static Future<void> ensureAllDirsExist() async {
    final dirs = [
      configDir,
      cacheDir,
      logsDir,
      playbooksDir,
      inventoryDir,
      venvDir,
      deploymentConfigsDir,
    ];

    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  static Future<void> cleanConfigDir() async {
    final dir = Directory(configDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  static String expandPath(String path) {
    if (path.startsWith('~/')) {
      return p.join(homeDir, path.substring(2));
    }
    return path;
  }

  static String getProjectConfigPath(String projectPath, String filename) {
    return p.join(projectPath, filename);
  }
}
