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

      // Validate function structure: must have bin/main.dart or lib/main.dart
      final binMainFile = File(path.join(currentDir.path, 'bin', 'main.dart'));
      final libMainFile = File(path.join(currentDir.path, 'lib', 'main.dart'));

      if (!binMainFile.existsSync() && !libMainFile.existsSync()) {
        print('✗ Error: Function entry point not found');
        print('  Expected: bin/main.dart or lib/main.dart');
        exit(1);
      }

      // Parse pubspec.yaml to get the project name
      final pubspecContent = pubspecFile.readAsStringSync();
      final pubspec = loadYaml(pubspecContent) as Map;
      final projectName = pubspec['name'] as String? ?? 'function';

      // Create function config with path
      final functionConfig = FunctionConfig(
        functionName: projectName,
        createdAt: DateTime.now().toIso8601String(),
        functionPath: currentDir.path,
      );

      // Save the config
      await functionConfig.save(currentDir.path);

      print('✓ Successfully initialized function config');
      print(
          '✓ Config file created at: ${path.join(currentDir.path, '.dart_tool', 'function_config.json')}');
      print('✓ Function name: $projectName');
      print('✓ Function path: ${currentDir.path}');
      print(
          '✓ Entry point: ${binMainFile.existsSync() ? 'bin/main.dart' : 'lib/main.dart'}');
    } catch (e) {
      print('✗ Initialization failed: $e');
      exit(1);
    }
  }
}
