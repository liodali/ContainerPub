import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:hive_ce/hive.dart';

/// Generic Hive initialization and management service
///
/// Provides shared functionality for initializing Hive boxes
/// with proper home directory detection and environment handling
class HiveService {
  /// Get the home directory based on the platform
  ///
  /// - Windows: Uses USERPROFILE environment variable
  /// - macOS/Linux: Uses HOME environment variable
  /// - Fallback: Uses current directory
  static String getHomeDir() {
    String homeDir = "./";
    if (Platform.isWindows) {
      homeDir = Platform.environment['USERPROFILE'] ?? "./";
    } else if (Platform.isLinux || Platform.isMacOS) {
      homeDir = Platform.environment['HOME'] ?? "./";
    }
    return homeDir;
  }

  /// Check if running in development local mode
  ///
  /// Reads .env file and checks for isDevLocal=true
  static bool isDevLocal() {
    if (!File('.env').existsSync()) {
      return false;
    }
    try {
      final dotEnv = DotEnv()..load(['.env']);
      return dotEnv.getOrElse('isDevLocal', () => 'false') == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Get the appropriate Hive directory path
  ///
  /// - Dev local: Uses .dart_tool directory
  /// - Production: Uses home directory/.containerpub/cache
  static String getHiveDir({String? subPath}) {
    final homeDir = getHomeDir();
    final basePath = isDevLocal() ? './.dart_tool' : homeDir;
    final path = subPath != null
        ? '$basePath/.containerpub/$subPath'
        : '$basePath/.containerpub/cache';
    return path;
  }

  /// Initialize Hive with the specified directory and box name
  ///
  /// [boxName]: Name of the Hive box to open
  /// [subPath]: Optional subdirectory under .containerpub (e.g., 'cache', 'api_keys')
  ///
  /// Returns the opened Box
  static Future<LazyBox<T>> initBox<T>(
    String boxName, {
    String? subPath,
  }) async {
    try {
      final hiveDir = getHiveDir(subPath: subPath);
      final dir = Directory(hiveDir);

      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      Hive.init(hiveDir);
      return Hive.openLazyBox<T>(boxName);
    } catch (e) {
      throw Exception('Failed to initialize Hive box "$boxName": $e');
    }
  }

  /// Close a specific Hive box
  static Future<void> closeBox(LazyBox? box) async {
    if (box != null && box.isOpen) {
      await box.close();
    }
  }

  /// Close all Hive boxes
  static Future<void> closeAll() async {
    await Hive.close();
  }
}
