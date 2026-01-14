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
      )
      ..addOption(
        'registry-url',
        help: 'Container registry URL (e.g., https://gitea.example.com)',
      )
      ..addOption(
        'registry-company-host',
        help:
            'Registry company host name (e.g., docker.io, gitea.example.com/company)',
      )
      ..addOption(
        'registry-username',
        help: 'Registry username for authentication',
      )
      ..addOption(
        'registry-token',
        help: 'Registry token (base64 encoded)',
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
    final registryUrl = argResults!['registry-url'] as String?;
    final registryCompanyHost = argResults!['registry-company-host'] as String?;
    final registryUsername = argResults!['registry-username'] as String?;
    final registryToken = argResults!['registry-token'] as String?;

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
      final existingConfig = await configManager.loadConfig();

      // Check if we should update registry
      final hasRegistryFlags =
          registryUrl != null ||
          registryCompanyHost != null ||
          registryUsername != null ||
          registryToken != null;

      if (hasRegistryFlags && existingConfig?['registry'] != null) {
        Console.info('Registry exists, updating configuration...');

        // Merge existing registry with new values
        final existingRegistry = Map<String, dynamic>.from(
          existingConfig!['registry'] as Map,
        );

        final updatedRegistry = {
          'url': registryUrl ?? existingRegistry['url'],
          'registry_company_host_name':
              registryCompanyHost ??
              existingRegistry['registry_company_host_name'],
          'username': registryUsername ?? existingRegistry['username'],
          'token_base64': registryToken ?? existingRegistry['token_base64'],
        };

        await configManager.updateRegistry(registryConfig: updatedRegistry);
        Console.success('Registry configuration updated');
        return;
      }

      // Config exists - check if we should add environment section
      final hasEnv = await configManager.hasEnvironmentSection(environment);

      if (hasEnv) {
        // Environment exists - check if we should add OpenBao
        final hasOpenBaoFlags =
            openbaoAddress != null ||
            openbaoSecretPath != null ||
            openbaoRoleId != null ||
            openbaoRoleName != null;

        if (hasOpenBaoFlags) {
          Console.info(
            'Environment $environment exists, checking OpenBao configuration...',
          );
          final envConfig = existingConfig?[environment];

          if (envConfig != null && envConfig['openbao'] == null) {
            Console.info(
              'Adding OpenBao configuration to $environment environment...',
            );
            final openbaoConfig = ConfigManager.generateOpenBaoDefaults(
              address: openbaoAddress,
              secretPath: openbaoSecretPath,
              roleId: openbaoRoleId,
              roleName: openbaoRoleName,
              environment: environment,
            );

            // Add OpenBao to existing environment
            await configManager.addOpenBaoToEnvironment(
              environment: environment,
              openbaoConfig: openbaoConfig,
            );
            Console.success(
              'Added OpenBao configuration to $environment environment',
            );
            return;
          } else if (envConfig?['openbao'] != null) {
            Console.info(
              'OpenBao already configured for $environment environment',
            );
            return;
          }
        }

        Console.success('Config already exists with $environment environment');
        Console.info('Skipping - no changes needed');
        return;
      }

      // Add environment section only
      Console.info('Config exists, adding $environment environment section...');
      final envConfig = _buildEnvironmentConfig(
        environment,
        includeOpenbao:
            openbaoAddress != null ||
            openbaoSecretPath != null ||
            openbaoRoleId != null ||
            openbaoRoleName != null,
        openbaoAddress: openbaoAddress,
        openbaoSecretPath: openbaoSecretPath,
        openbaoRoleId: openbaoRoleId,
        openbaoRoleName: openbaoRoleName,
      );
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
      environment: environment,
    );

    // Generate container config
    final containerConfig = ConfigManager.generateContainerDefaults(
      projectName: name,
    );

    // Generate registry config if any registry option is provided
    final hasRegistryFlags =
        registryUrl != null ||
        registryCompanyHost != null ||
        registryUsername != null ||
        registryToken != null;

    final registryConfig = hasRegistryFlags
        ? ConfigManager.generateRegistryDefaults(
            url: registryUrl,
            registryCompanyHostName: registryCompanyHost,
            username: registryUsername,
            tokenBase64: registryToken,
          )
        : null;

    // Create config
    await configManager.createConfig(
      name: name,
      environment: environment,
      format: format,
      registry: registryConfig,
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

  Map<String, dynamic> _buildEnvironmentConfig(
    String environment, {
    bool includeOpenbao = false,
    String? openbaoAddress,
    String? openbaoSecretPath,
    String? openbaoRoleId,
    String? openbaoRoleName,
  }) {
    final config = <String, dynamic>{
      'env_file_path': '.env',
      'container': ConfigManager.generateContainerDefaults(),
    };

    if (includeOpenbao) {
      config['openbao'] = ConfigManager.generateOpenBaoDefaults(
        address: openbaoAddress,
        secretPath: openbaoSecretPath,
        roleId: openbaoRoleId,
        roleName: openbaoRoleName,
        environment: environment,
      );
    }

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
        help:
            'Configuration file path (auto-detects .dart_tool/deploy_config.yaml or deploy.yaml)',
      )
      ..addOption('key', abbr: 'k', help: 'Configuration key (dot notation)')
      ..addOption('value', abbr: 'v', help: 'Configuration value');
  }

  @override
  Future<void> run() async {
    // Detect workspace and determine config path
    final workspace = await WorkspaceDetector.detectWorkspace();
    final configPath = argResults!['config'] as String? ?? workspace.configPath;
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
      help:
          'Configuration file path (auto-detects .dart_tool/deploy_config.yaml or deploy.yaml)',
    );
  }

  @override
  Future<void> run() async {
    // Detect workspace and determine config path
    final workspace = await WorkspaceDetector.detectWorkspace();
    final configPath = argResults!['config'] as String? ?? workspace.configPath;

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

    if (config['project_path'] == null) {
      errors.add('Missing required field: project_path');
    }

    // Check for at least one environment
    final hasLocal = config['local'] != null;
    final hasStaging = config['staging'] != null;
    final hasProduction = config['production'] != null;

    if (!hasLocal && !hasStaging && !hasProduction) {
      errors.add(
        'At least one environment (local, staging, or production) must be configured',
      );
    }

    // Validate each environment that exists
    for (final envName in ['local', 'staging', 'production']) {
      final env = config[envName];
      if (env != null) {
        if (env['container'] == null) {
          errors.add('Missing required field: $envName.container');
        } else {
          if (env['container']['compose_file'] == null) {
            errors.add(
              'Missing required field: $envName.container.compose_file',
            );
          }
          if (env['container']['runtime'] == null) {
            errors.add('Missing required field: $envName.container.runtime');
          }
        }

        // Non-local environments should have host config
        if (envName != 'local' && env['host'] == null) {
          Console.warning(
            'Host configuration recommended for $envName environment',
          );
        }
      }
    }

    if (errors.isNotEmpty) {
      for (final error in errors) {
        Console.error(error);
      }
      throw Exception('${errors.length} validation error(s)');
    }

    Console.success('All required fields present');

    // Check optional but recommended fields
    var hasAnyOpenbao = false;
    for (final envName in ['local', 'staging', 'production']) {
      final env = config[envName];
      if (env != null && env['openbao'] != null) {
        hasAnyOpenbao = true;
        break;
      }
    }

    if (!hasAnyOpenbao) {
      Console.warning(
        'OpenBao not configured in any environment - secrets will not be fetched',
      );
    }
  }
}
