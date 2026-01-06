import 'dart:io';
import 'package:args/command_runner.dart';
import '../models/deploy_config.dart';
import '../utils/console.dart';

class ShowConfigCommand extends Command<void> {
  @override
  final String name = 'show';

  @override
  final String description = 'Show current deployment configuration';

  ShowConfigCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Configuration file path',
        defaultsTo: 'deploy.yaml',
      )
      ..addFlag(
        'full',
        abbr: 'f',
        help: 'Show full configuration including sensitive data',
        defaultsTo: false,
      );
  }

  @override
  Future<void> run() async {
    final configPath = argResults!['config'] as String;
    final showFull = argResults!['full'] as bool;

    Console.header('Deployment Configuration');

    final file = File(configPath);
    if (!await file.exists()) {
      Console.error('Configuration file not found: $configPath');
      Console.info('Run "dart_cloud_deploy config init" to create one');
      exit(1);
    }

    DeployConfig config;
    try {
      config = await DeployConfig.load(configPath);
    } catch (e) {
      Console.error('Failed to load configuration: $e');
      exit(1);
    }

    // General
    Console.divider();
    print('\x1B[34mGeneral:\x1B[0m');
    Console.divider();
    Console.keyValue('Name', config.name);
    Console.keyValue('Environment', config.environment.name);
    Console.keyValue('Project Path', config.projectPath);
    Console.keyValue('Env File', config.envFilePath ?? '.env');

    // Container
    Console.divider();
    print('\x1B[34mContainer:\x1B[0m');
    Console.divider();
    Console.keyValue('Runtime', config.container.runtime);
    Console.keyValue('Compose File', config.container.composeFile);
    Console.keyValue('Project Name', config.container.projectName);
    Console.keyValue('Network', config.container.networkName);
    Console.info('Services:');
    for (final entry in config.container.services.entries) {
      Console.step('  ${entry.key}: ${entry.value}');
    }

    // OpenBao
    if (config.openbao != null) {
      Console.divider();
      print('\x1B[34mOpenBao:\x1B[0m');
      Console.divider();
      Console.keyValue('Address', config.openbao!.address);
      Console.keyValue('Secret Path', config.openbao!.secretPath);
      if (config.openbao!.namespace != null) {
        Console.keyValue('Namespace', config.openbao!.namespace!);
      }
      if (showFull) {
        if (config.openbao!.token != null) {
          Console.keyValue('Token', config.openbao!.token!);
        }
        if (config.openbao!.tokenPath != null) {
          Console.keyValue('Token Path', config.openbao!.tokenPath!);
        }
      } else {
        Console.keyValue('Token', '****** (use --full to show)');
      }
    } else {
      Console.divider();
      print('\x1B[33mOpenBao: Not configured\x1B[0m');
    }

    // Host
    if (config.host != null) {
      Console.divider();
      print('\x1B[34mHost:\x1B[0m');
      Console.divider();
      Console.keyValue('Host', config.host!.host);
      Console.keyValue('Port', config.host!.port.toString());
      Console.keyValue('User', config.host!.user);
      if (config.host!.sshKeyPath != null) {
        Console.keyValue('SSH Key', config.host!.sshKeyPath!);
      }
    } else if (!config.isLocal) {
      Console.divider();
      print(
        '\x1B[33mHost: Not configured (required for remote deployment)\x1B[0m',
      );
    }

    // Ansible
    if (config.ansible != null) {
      Console.divider();
      print('\x1B[34mAnsible:\x1B[0m');
      Console.divider();
      if (config.ansible!.inventoryPath != null) {
        Console.keyValue('Inventory', config.ansible!.inventoryPath!);
      }
      Console.keyValue('Backend Playbook', config.ansible!.backendPlaybook);
      Console.keyValue('Database Playbook', config.ansible!.databasePlaybook);
      Console.keyValue('Backup Playbook', config.ansible!.backupPlaybook);
      if (config.ansible!.extraVars.isNotEmpty) {
        Console.info('Extra Variables:');
        for (final entry in config.ansible!.extraVars.entries) {
          Console.step('  ${entry.key}: ${entry.value}');
        }
      }
    } else if (!config.isLocal) {
      Console.divider();
      print(
        '\x1B[33mAnsible: Not configured (required for remote deployment)\x1B[0m',
      );
    }

    Console.divider();

    // Summary
    print('');
    if (config.isLocal) {
      Console.success('Configuration ready for local deployment');
      Console.info('Run: dart_cloud_deploy deploy-local');
    } else if (config.host != null && config.ansible != null) {
      Console.success(
        'Configuration ready for ${config.environment.name} deployment',
      );
      Console.info('Run: dart_cloud_deploy deploy-dev');
    } else {
      Console.warning('Configuration incomplete for remote deployment');
      Console.info('Add host and ansible sections for remote deployment');
    }
  }
}
