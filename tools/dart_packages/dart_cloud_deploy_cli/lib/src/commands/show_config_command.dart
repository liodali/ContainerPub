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

    // Determine target environment
    Environment targetEnv = Environment.local;
    if (config.local != null) {
      targetEnv = Environment.local;
    } else if (config.staging != null) {
      targetEnv = Environment.staging;
    } else if (config.production != null) {
      targetEnv = Environment.production;
    }

    // Set current environment for backward compatibility
    config.setCurrentEnvironment(targetEnv);

    // General
    Console.divider();
    print('\x1B[34mGeneral:\x1B[0m');
    Console.divider();
    Console.keyValue('Name', config.name);
    Console.keyValue('Environment', targetEnv.name);
    Console.keyValue('Project Path', config.projectPath);
    Console.keyValue('Env File', config.envFilePath ?? '.env');

    // Container
    final container = config.container;
    if (container != null) {
      Console.divider();
      print('\x1B[34mContainer:\x1B[0m');
      Console.divider();
      Console.keyValue('Runtime', container.runtime);
      Console.keyValue('Compose File', container.composeFile);
      Console.keyValue('Project Name', container.projectName);
      Console.keyValue('Network', container.networkName);
      Console.info('Services:');
      for (final entry in container.services.entries) {
        Console.step('  ${entry.key}: ${entry.value}');
      }
    } else {
      Console.divider();
      print('\x1B[33mContainer: Not configured\x1B[0m');
    }

    // OpenBao
    if (config.openbao != null) {
      Console.divider();
      print('\x1B[34mOpenBao:\x1B[0m');
      Console.divider();
      Console.keyValue('Address', config.openbao!.address);
      if (config.openbao!.namespace != null) {
        Console.keyValue('Namespace', config.openbao!.namespace!);
      }

      // Show environment configurations
      for (final env in Environment.values) {
        final envConfig = config.openbao!.getEnvConfig(env);
        if (envConfig != null) {
          Console.info('  ${env.name}:');
          Console.keyValue('    Secret Path', envConfig.secretPath);
          Console.keyValue('    Policy', envConfig.policy);
          if (showFull) {
            Console.keyValue('    Token Manager', envConfig.tokenManager);
          } else {
            Console.keyValue(
              '    Token Manager',
              '****** (use --full to show)',
            );
          }
        }
      }
    } else {
      Console.divider();
      print('\x1B[33mOpenBao: Not configured\x1B[0m');
    }

    // Host
    final host = config.host;
    if (host != null) {
      Console.divider();
      print('\x1B[34mHost:\x1B[0m');
      Console.divider();
      Console.keyValue('Host', host.host);
      Console.keyValue('Port', host.port.toString());
      Console.keyValue('User', host.user);
      if (host.sshKeyPath != null) {
        Console.keyValue('SSH Key', host.sshKeyPath!);
      }
    } else if (!config.isLocal) {
      Console.divider();
      print(
        '\x1B[33mHost: Not configured (required for remote deployment)\x1B[0m',
      );
    }

    // Ansible
    final ansible = config.ansible;
    if (ansible != null) {
      Console.divider();
      print('\x1B[34mAnsible:\x1B[0m');
      Console.divider();
      if (ansible.inventoryPath != null) {
        Console.keyValue('Inventory', ansible.inventoryPath!);
      }
      Console.keyValue('Backend Playbook', ansible.backendPlaybook);
      Console.keyValue('Database Playbook', ansible.databasePlaybook);
      Console.keyValue('Backup Playbook', ansible.backupPlaybook);
      if (ansible.extraVars.isNotEmpty) {
        Console.info('Extra Variables:');
        for (final entry in ansible.extraVars.entries) {
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
    } else if (host != null && ansible != null) {
      Console.success(
        'Configuration ready for ${targetEnv.name} deployment',
      );
      Console.info('Run: dart_cloud_deploy deploy-dev');
    } else {
      Console.warning('Configuration incomplete for remote deployment');
      Console.info('Add host and ansible sections for remote deployment');
    }
  }
}
