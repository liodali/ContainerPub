import 'dart:io';
import 'package:args/command_runner.dart';
import '../models/deploy_config.dart';
import '../services/ansible_service.dart';
import '../services/openbao_service.dart';
import '../services/playbook_service.dart';
import '../services/venv_service.dart';
import '../utils/console.dart';
import '../utils/venv_detector.dart';
import '../utils/workspace_detector.dart';

class DeployDevCommand extends Command<void> {
  @override
  final String name = 'deploy-dev';

  @override
  final String description = 'Deploy to dev environment using Ansible';

  DeployDevCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help:
            'Path to deployment configuration file (yaml/toml). '
            'Defaults to ~/.dart-cloud-deploy/deploy_config.yml or '
            '.dart_tool/deploy_config.yml',
      )
      ..addOption(
        'target',
        abbr: 't',
        help: 'Deployment target',
        allowed: ['all', 'backend', 'database', 'backup'],
        defaultsTo: 'all',
      )
      ..addFlag(
        'skip-secrets',
        help: 'Skip fetching secrets from OpenBao',
        defaultsTo: false,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Verbose Ansible output',
        defaultsTo: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Show what would be done without executing',
        defaultsTo: false,
      )
      ..addMultiOption('tags', help: 'Ansible tags to run')
      ..addMultiOption('skip-tags', help: 'Ansible tags to skip')
      ..addMultiOption(
        'extra-vars',
        abbr: 'e',
        help: 'Extra variables (key=value)',
      );
  }

  @override
  Future<void> run() async {
    final configPathArg = argResults!['config'] as String?;
    final target = argResults!['target'] as String;
    final skipSecrets = argResults!['skip-secrets'] as bool;
    final verbose = argResults!['verbose'] as bool;
    final dryRun = argResults!['dry-run'] as bool;
    final tags = argResults!['tags'] as List<String>;
    final skipTags = argResults!['skip-tags'] as List<String>;
    final extraVarsRaw = argResults!['extra-vars'] as List<String>;

    Console.header('Dart Cloud Dev Deployment');

    // Resolve config path: CLI arg > workspace config > global config
    String configPath;
    if (configPathArg != null) {
      configPath = configPathArg;
    } else {
      final resolvedPath = await WorkspaceDetector.resolveDeployConfigPath();
      if (resolvedPath != null) {
        configPath = resolvedPath;
        Console.info('Using config: $configPath');
      } else {
        Console.error(
          'No configuration file found!\n'
          'Please provide one of:\n'
          '  1. --config <path> argument\n'
          '  2. .dart_tool/deploy_config.yml in current directory\n'
          '  3. ~/.dart-cloud-deploy/deploy_config.yml',
        );
        exit(1);
      }
    }

    // Parse extra vars
    final extraVars = <String, String>{};
    for (final v in extraVarsRaw) {
      final parts = v.split('=');
      if (parts.length == 2) {
        extraVars[parts[0]] = parts[1];
      }
    }

    // Load configuration
    DeployConfig config;
    try {
      config = await DeployConfig.load(configPath);
    } catch (e) {
      Console.error('Failed to load configuration: $e');
      exit(1);
    }
    if (config.staging == null) {
      Console.error('Staging configuration is required for dev deployment');
      exit(1);
    }
    // Determine target environment (default to staging if not set)
    Environment targetEnv = Environment.staging;

    // Set current environment for backward compatibility
    config.setCurrentEnvironment(targetEnv);

    // Validate configuration for dev deployment
    if (config.host == null) {
      Console.error('Host configuration required for dev deployment');
      Console.info(
        'Add host section to your configuration file for ${targetEnv.name} environment',
      );
      exit(1);
    }

    if (config.ansible == null) {
      Console.error('Ansible configuration required for dev deployment');
      Console.info(
        'Add ansible section to your configuration file for ${targetEnv.name} environment',
      );
      exit(1);
    }

    if (config.container == null) {
      Console.error('Container configuration required for dev deployment');
      Console.info(
        'Add container section to your configuration file for ${targetEnv.name} environment',
      );
      exit(1);
    }

    // Initialize services
    final venvLocation = await VenvDetector.detectVenvLocation();
    final venvService = VenvService(venvPath: venvLocation.path);

    Console.info('Using virtual environment: ${venvLocation.path}');
    Console.info('Activating venv for deployment...');

    final playbookService = PlaybookService(
      workingDirectory: config.projectPath,
    );
    final ansibleService = AnsibleService(
      config: config.ansible!,
      host: config.host!,
      workingDirectory: config.projectPath,
      venvService: venvService,
      playbookService: playbookService,
    );

    // Check environment is ready
    Console.info('Checking deployment environment...');
    if (!await ansibleService.checkEnvironment()) {
      Console.error('Environment not ready. Run: dart_cloud_deploy init');
      exit(1);
    }
    Console.success('Environment ready (venv activated)');

    // Fetch secrets if configured
    final envConfig = config.getEnvironmentConfig(config.environment!);
    if (!skipSecrets && envConfig?.openbao != null) {
      await _fetchSecrets(config);
    }

    // Generate inventory
    Console.info('Generating Ansible inventory...');
    await ansibleService.generateInventory();

    // Test connection
    Console.info('Testing connection to ${config.host!.host}...');
    if (!await ansibleService.ping()) {
      Console.error('Cannot connect to target host');
      await ansibleService.cleanup();
      exit(1);
    }

    if (dryRun) {
      Console.header('Dry Run - Would Execute:');
      Console.info('Target: $target');
      Console.info('Host: ${config.host!.host}');
      Console.info('Playbooks (generated on-demand):');
      if (target == 'all' || target == 'backend') {
        Console.step('  - backend.yml');
      }
      if (target == 'all' || target == 'database') {
        Console.step('  - database.yml');
      }
      if (target == 'backup') {
        Console.step('  - backup.yml');
      }
      await ansibleService.cleanup();
      return;
    }

    // Run deployments with generated playbooks
    try {
      bool success = true;

      if (target == 'all' || target == 'database') {
        Console.info('Generating database playbook...');
        final dbPlaybook = await playbookService.generateDatabasePlaybook(
          config,
        );
        success = await ansibleService.runPlaybook(
          dbPlaybook,
          extraVars: extraVars,
          verbose: verbose,
        );
        if (!success) {
          Console.error('Database deployment failed');
          exit(1);
        }
      }

      if (target == 'all' || target == 'backend') {
        Console.info('Generating backend playbook...');
        final backendPlaybook = await playbookService.generateBackendPlaybook(
          config,
        );
        success = await ansibleService.runPlaybook(
          backendPlaybook,
          extraVars: extraVars,
          verbose: verbose,
          tags: tags.isNotEmpty ? tags : null,
          skipTags: skipTags.isNotEmpty ? skipTags : null,
        );
        if (!success) {
          Console.error('Backend deployment failed');
          exit(1);
        }
      }

      if (target == 'backup') {
        Console.info('Generating backup playbook...');
        final backupPlaybook = await playbookService.generateBackupPlaybook(
          config,
        );
        success = await ansibleService.runPlaybook(
          backupPlaybook,
          extraVars: extraVars,
          verbose: verbose,
        );
        if (!success) {
          Console.error('Backup failed');
          exit(1);
        }
      }

      Console.header('Deployment Complete!');
      Console.success('Successfully deployed to ${config.host!.host}');
    } finally {
      // Cleanup generated playbooks and inventory
      await ansibleService.cleanup();
      await playbookService.cleanup();
      Console.info('Cleaned up temporary files');
    }
  }

  Future<void> _fetchSecrets(DeployConfig config) async {
    Console.header('Fetching Secrets from OpenBao');

    final environment = config.environment;
    if (environment == null) {
      Console.error('Environment not found');
      exit(1);
    }

    final envConfig = config.getEnvironmentConfig(environment);
    final openbaoConfig = envConfig?.openbao;

    if (openbaoConfig == null) {
      Console.warning(
        'No OpenBao configuration for ${environment.name} environment',
      );
      if (!Console.confirm('Continue without secrets?')) {
        exit(1);
      }
      return;
    }

    final openbao = OpenBaoService(
      config: openbaoConfig,
      environment: environment,
    );

    if (!await openbao.checkHealth()) {
      Console.warning('OpenBao is not reachable at ${openbaoConfig.address}');
      if (!Console.confirm('Continue without secrets?')) {
        exit(1);
      }
      return;
    }

    Console.info('Creating token for ${environment.name}...');
    if (!await openbao.createToken()) {
      Console.warning('Failed to create token for ${environment.name}');
      if (!Console.confirm('Continue without secrets?')) {
        exit(1);
      }
      return;
    }

    try {
      final envPath = config.envFilePath ?? '.env';
      await openbao.writeEnvFile(openbaoConfig.secretPath, envPath);
    } catch (e) {
      Console.error('Failed to fetch secrets: $e');
      if (!Console.confirm('Continue without secrets?')) {
        exit(1);
      }
    }
  }
}
