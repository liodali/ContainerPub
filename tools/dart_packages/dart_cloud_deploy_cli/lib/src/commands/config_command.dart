import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:toml/toml.dart';
import '../utils/console.dart';
import '../utils/workspace_detector.dart';
import '../utils/config_manager.dart';

class ConfigCommand extends Command<void> {
  @override
  final String name = 'config';

  @override
  final String description = 'Initialize or manage deployment configuration';

  ConfigCommand() {
    addSubcommand(_ConfigInitCommand());
    addSubcommand(_ConfigSetCommand());
    addSubcommand(_ConfigValidateCommand());
  }
}

class _ConfigInitCommand extends Command<void> {
  @override
  final String name = 'init';

  @override
  final String description = 'Initialize a new deployment configuration file';

  _ConfigInitCommand() {
    argParser
      ..addOption(
        'format',
        abbr: 'f',
        help: 'Configuration file format (only used when creating new config)',
        allowed: ['yaml', 'toml'],
        defaultsTo: 'yaml',
      )
      ..addFlag(
        'workspace',
        abbr: 'w',
        help: 'Store config in .dart_tool/ of Dart project',
        defaultsTo: true,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path (overrides workspace detection)',
      )
      ..addOption(
        'environment',
        abbr: 'e',
        help: 'Target environment',
        allowed: ['local', 'staging', 'production'],
        defaultsTo: 'local',
      )
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Project name',
      )
      ..addOption(
        'openbao-address',
        help: 'OpenBao server address',
      )
      ..addOption(
        'openbao-secret-path',
        help: 'OpenBao secret path',
      )
      ..addOption(
        'openbao-role-id',
        help: 'OpenBao AppRole role ID',
      )
      ..addOption(
        'openbao-role-name',
        help: 'OpenBao AppRole role name',
      );
  }

  @override
  Future<void> run() async {
    final format = argResults!['format'] as String;
    final useWorkspace = argResults!['workspace'] as bool;
    final outputOverride = argResults!['output'] as String?;
    final environment = argResults!['environment'] as String;
    final projectName = argResults!['name'] as String?;
    final openbaoAddress = argResults!['openbao-address'] as String?;
    final openbaoSecretPath = argResults!['openbao-secret-path'] as String?;
    final openbaoRoleId = argResults!['openbao-role-id'] as String?;
    final openbaoRoleName = argResults!['openbao-role-name'] as String?;

    Console.header('Initializing Deployment Configuration');

    // Detect workspace
    final workspace = await WorkspaceDetector.detectWorkspace();

    // Determine config path based on format
    final extension = format == 'toml' ? '.toml' : '.yaml';

    // Determine config path
    String configPath;
    if (outputOverride != null) {
      configPath = outputOverride;
    } else if (useWorkspace && workspace.isDartProject) {
      // Use workspace path but with correct extension
      configPath = workspace.configPath.replaceAll('.yaml', extension);
      Console.info('Detected ${workspace.description}: ${workspace.path}');
      Console.info('Config will be stored in: $configPath');
    } else {
      configPath = 'deploy$extension';
    }

    final configManager = ConfigManager(
      WorkspaceInfo(
        path: workspace.path,
        isDartProject: workspace.isDartProject,
        configPath: configPath,
      ),
    );

    // Check if config exists
    if (configManager.configExists) {
      // Config exists - check if we should add environment section
      final hasEnv = await configManager.hasEnvironmentSection(environment);
      if (hasEnv) {
        Console.success('Config already exists with $environment environment');
        Console.info('Skipping - no changes needed');
        return;
      }

      // Add environment section only
      Console.info('Config exists, adding $environment environment section...');
      final envConfig = _buildEnvironmentConfig(environment);
      final added = await configManager.addEnvironmentSection(
        environment: environment,
        envConfig: envConfig,
      );

      if (added) {
        Console.success('Added $environment environment to: $configPath');
      } else {
        Console.info('Environment section already exists, skipped');
      }
      return;
    }

    // Create new config
    Console.info('Creating new configuration...');

    // Ensure .dart_tool exists for Dart projects
    if (workspace.isDartProject) {
      await WorkspaceDetector.ensureDartToolExists(workspace.path);
    }

    // Determine project name
    final name = projectName ?? p.basename(workspace.path);

    // Generate OpenBao config with defaults for missing values
    final openbaoConfig = ConfigManager.generateOpenBaoDefaults(
      address: openbaoAddress,
      secretPath: openbaoSecretPath,
      roleId: openbaoRoleId,
      roleName: openbaoRoleName,
    );

    // Generate container config
    final containerConfig = ConfigManager.generateContainerDefaults(
      projectName: name,
    );

    // Create config
    await configManager.createConfig(
      name: name,
      environment: environment,
      format: format,
      openbao: openbaoConfig,
      container: containerConfig,
      host: environment != 'local' ? _buildHostDefaults() : null,
      ansible: environment != 'local' ? _buildAnsibleDefaults() : null,
    );

    Console.success('Configuration file created: $configPath');
    Console.info('');
    Console.info('Next steps:');
    Console.step('  1. Edit $configPath to configure OpenBao credentials');
    Console.step('  2. Run: dart_cloud_deploy deploy-local');
  }

  Map<String, dynamic> _buildEnvironmentConfig(String environment) {
    final config = <String, dynamic>{
      'env_file_path': '.env',
      'container': ConfigManager.generateContainerDefaults(),
    };

    if (environment != 'local') {
      config['host'] = _buildHostDefaults();
      config['ansible'] = _buildAnsibleDefaults();
    }

    return config;
  }

  Map<String, dynamic> _buildHostDefaults() {
    return {
      'host': 'your-server.example.com',
      'port': 22,
      'user': 'deploy',
      'ssh_key_path': '~/.ssh/id_rsa',
    };
  }

  Map<String, dynamic> _buildAnsibleDefaults() {
    return {
      'backend_playbook': 'playbooks/backend.yml',
      'database_playbook': 'playbooks/database.yml',
      'extra_vars': {
        'deploy_user': 'deploy',
        'app_dir': '/opt/dart_cloud',
      },
    };
  }
}

class _ConfigSetCommand extends Command<void> {
  @override
  final String name = 'set';

  @override
  final String description = 'Set a configuration value';

  _ConfigSetCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Configuration file path',
        defaultsTo: 'deploy.yaml',
      )
      ..addOption('key', abbr: 'k', help: 'Configuration key (dot notation)')
      ..addOption('value', abbr: 'v', help: 'Configuration value');
  }

  @override
  Future<void> run() async {
    final configPath = argResults!['config'] as String;
    final key = argResults!['key'] as String?;
    final value = argResults!['value'] as String?;

    if (key == null || value == null) {
      Console.error('Both --key and --value are required');
      return;
    }

    final file = File(configPath);
    if (!await file.exists()) {
      Console.error('Configuration file not found: $configPath');
      return;
    }

    Console.info('Setting $key = $value in $configPath');
    Console.warning('Manual editing recommended for complex changes');

    // For now, just inform the user - full YAML/TOML editing is complex
    Console.info('Please edit $configPath manually to set: $key = $value');
  }
}

class _ConfigValidateCommand extends Command<void> {
  @override
  final String name = 'validate';

  @override
  final String description = 'Validate a deployment configuration file';

  _ConfigValidateCommand() {
    argParser.addOption(
      'config',
      abbr: 'c',
      help: 'Configuration file path',
      defaultsTo: 'deploy.yaml',
    );
  }

  @override
  Future<void> run() async {
    final configPath = argResults!['config'] as String;

    Console.header('Validating Configuration');

    final file = File(configPath);
    if (!await file.exists()) {
      Console.error('Configuration file not found: $configPath');
      exit(1);
    }

    try {
      final ext = p.extension(configPath).toLowerCase();
      final content = await file.readAsString();

      if (ext == '.yaml' || ext == '.yml') {
        _validateYaml(content);
      } else if (ext == '.toml') {
        _validateToml(content);
      } else {
        Console.error('Unsupported format: $ext');
        exit(1);
      }

      Console.success('Configuration is valid');
    } catch (e) {
      Console.error('Configuration validation failed: $e');
      exit(1);
    }
  }

  void _validateYaml(String content) {
    final doc = loadYaml(content);
    _validateConfig(doc);
  }

  void _validateToml(String content) {
    final doc = TomlDocument.parse(content);
    _validateConfig(doc.toMap());
  }

  void _validateConfig(dynamic config) {
    final errors = <String>[];

    if (config['name'] == null) {
      errors.add('Missing required field: name');
    }

    if (config['environment'] == null) {
      errors.add('Missing required field: environment');
    }

    if (config['container'] == null) {
      errors.add('Missing required field: container');
    } else {
      if (config['container']['compose_file'] == null) {
        errors.add('Missing required field: container.compose_file');
      }
    }

    final env = config['environment'];
    if (env != 'local' && config['host'] == null) {
      errors.add('Host configuration required for non-local environments');
    }

    if (errors.isNotEmpty) {
      for (final error in errors) {
        Console.error(error);
      }
      throw Exception('${errors.length} validation error(s)');
    }

    Console.success('All required fields present');

    // Check optional but recommended fields
    if (config['openbao'] == null) {
      Console.warning('OpenBao not configured - secrets will not be fetched');
    }
  }
}
