import 'dart:io';
import 'package:args/command_runner.dart';
import '../utils/console.dart';
import '../utils/config_paths.dart';

class PruneCommand extends Command<void> {
  @override
  final String name = 'prune';

  @override
  final String description =
      'Remove all deployment configurations and virtual environment from config directory';

  PruneCommand() {
    argParser.addFlag(
      'yes',
      abbr: 'y',
      help: 'Skip confirmation prompt',
      defaultsTo: false,
    );
  }

  @override
  Future<void> run() async {
    final skipConfirmation = argResults!['yes'] as bool;

    Console.header('Prune Config Directory');
    Console.warning('This will remove:');
    Console.step('  • Virtual environment: ${ConfigPaths.venvDir}');
    Console.step('  • Deployment configs: ${ConfigPaths.deploymentConfigsDir}');
    Console.step('  • Cache: ${ConfigPaths.cacheDir}');
    Console.step('  • Logs: ${ConfigPaths.logsDir}');
    Console.step('  • Playbooks: ${ConfigPaths.playbooksDir}');
    Console.step('  • Inventory: ${ConfigPaths.inventoryDir}');
    Console.info('');
    Console.warning('Config directory: ${ConfigPaths.configDir}');

    if (!skipConfirmation) {
      Console.info('');
      stdout.write('Are you sure you want to continue? (y/N): ');
      final response = stdin.readLineSync()?.toLowerCase().trim();

      if (response != 'y' && response != 'yes') {
        Console.info('Prune cancelled.');
        return;
      }
    }

    Console.info('');
    Console.info('Removing config directory...');

    try {
      await ConfigPaths.cleanConfigDir();
      Console.success('Config directory removed successfully');
      Console.info('');
      Console.info('Run "dart_cloud_deploy init" to reinitialize.');
    } catch (e) {
      Console.error('Failed to remove config directory: $e');
      exit(1);
    }
  }
}
