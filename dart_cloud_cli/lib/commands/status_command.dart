import 'dart:io';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;
import 'package:dart_cloud_cli/common/function_config.dart';
import 'package:dart_cloud_cli/services/function_hasher.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class StatusCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    try {
      // Get the current working directory or provided path
      String functionPath;
      if (args.isEmpty) {
        functionPath = Directory.current.path;
      } else {
        functionPath = args[0];
      }

      final functionDir = Directory(functionPath);
      if (!functionDir.existsSync()) {
        print('✗ Error: Directory not found: $functionPath');
        exit(1);
      }

      // Check if pubspec.yaml exists
      final pubspecFile = File(path.join(functionDir.path, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        print('✗ Error: Not a Dart project (pubspec.yaml not found)');
        exit(1);
      }

      // Get function name from pubspec
      final pubspecContent = pubspecFile.readAsStringSync();
      final pubspec = loadYaml(pubspecContent) as Map;
      final functionName =
          pubspec['name'] as String? ?? path.basename(functionDir.path);

      // Load existing config
      final config = await FunctionConfig.load(functionDir.path);

      print('\n📦 Function Status: $functionName');
      print('${'─' * 50}');

      if (config == null) {
        print('Status: Not initialized');
        print('\nRun "dart_cloud init" to initialize this function.');
        return;
      }

      // Generate current hash
      final hasher = FunctionHasher(functionDir.path);
      final currentHash = await hasher.generateHash();

      print('Function ID:     ${config.functionId ?? 'Not deployed'}');
      print('Function Path:   ${config.functionPath ?? functionDir.path}');
      print('Created At:      ${config.createdAt ?? 'Unknown'}');
      print('');
      print('📊 Deployment Info:');
      print('  Version:       ${config.deployVersion ?? 'Never deployed'}');
      print('  Last Deployed: ${config.lastDeployedAt ?? 'Never'}');
      print(
          '  Last Hash:     ${config.lastDeployHash != null ? '${config.lastDeployHash!.substring(0, 16)}...' : 'None'}');
      print('  Current Hash:  ${currentHash.substring(0, 16)}...');
      print('');

      // Check if code has changed
      if (config.lastDeployHash == null) {
        print('🆕 Status: Ready for first deployment');
      } else if (config.hasUnchangedCode(currentHash)) {
        print('✅ Status: Up to date (no changes since last deploy)');
      } else {
        print('🔄 Status: Changes detected - ready to deploy');
        print(
            '   Run "dart_cloud deploy" to deploy version ${config.nextVersion}');
      }

      print('');
    } catch (e) {
      print('✗ Error: $e');
      exit(1);
    }
  }
}
