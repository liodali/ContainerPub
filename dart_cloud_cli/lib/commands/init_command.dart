import 'dart:io';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;
import 'package:dart_cloud_cli/common/function_config.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class InitCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    try {
      // Get the current working directory
      final currentDir = Directory.current;

      // Check if pubspec.yaml exists
      final pubspecFile = File(path.join(currentDir.path, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        print('✗ Error: pubspec.yaml not found in current directory');
        exit(1);
      }

      // Parse pubspec.yaml to get the project name
      final pubspecContent = pubspecFile.readAsStringSync();
      final pubspec = loadYaml(pubspecContent) as Map;
      final projectName = pubspec['name'] as String? ?? 'function';

      // Create function config
      final functionConfig = FunctionConfig(
        functionName: projectName,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Save the config
      await functionConfig.save(currentDir.path);

      print('✓ Successfully initialized function config');
      print(
          '✓ Config file created at: ${path.join(currentDir.path, '.dart_tool', 'function_config.json')}');
      print('✓ Function name: $projectName');
    } catch (e) {
      print('✗ Initialization failed: $e');
      exit(1);
    }
  }
}
