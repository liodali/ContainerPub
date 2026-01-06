import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:toml/toml.dart';
import '../utils/console.dart';

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
        help: 'Configuration file format',
        allowed: ['yaml', 'toml'],
        defaultsTo: 'yaml',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path',
        defaultsTo: 'deploy.yaml',
      )
      ..addOption(
        'environment',
        abbr: 'e',
        help: 'Target environment',
        allowed: ['local', 'dev', 'production'],
        defaultsTo: 'local',
      );
  }

  @override
  Future<void> run() async {
    final format = argResults!['format'] as String;
    var output = argResults!['output'] as String;
    final environment = argResults!['environment'] as String;

    if (format == 'toml' && output == 'deploy.yaml') {
      output = 'deploy.toml';
    }

    Console.header('Initializing Deployment Configuration');

    final file = File(output);
    if (await file.exists()) {
      if (!Console.confirm('File $output already exists. Overwrite?')) {
        Console.info('Cancelled');
        return;
      }
    }

    String content;
    if (format == 'yaml') {
      content = _generateYamlConfig(environment);
    } else {
      content = _generateTomlConfig(environment);
    }

    await file.writeAsString(content);
    Console.success('Configuration file created: $output');
    Console.info('Edit the file to configure your deployment settings');
  }

  String _generateYamlConfig(String environment) {
    return '''
# Dart Cloud Deployment Configuration
# Environment: $environment

name: dart_cloud_backend
environment: $environment
project_path: .

# Environment file path (will be generated from OpenBao secrets)
env_file_path: .env

# OpenBao Configuration (for secrets management)
openbao:
  address: http://localhost:8200
  # token: hvs.xxxxx  # Or use token_path
  token_path: ~/.openbao/token
  secret_path: secret/data/dart_cloud/$environment
  # namespace: admin  # Optional namespace

# Container Configuration
container:
  runtime: podman  # or docker
  compose_file: docker-compose.yml
  project_name: dart_cloud
  network_name: dart_cloud_network
  services:
    backend: dart_cloud_backend
    postgres: dart_cloud_postgres

${environment != 'local' ? '''
# Host Configuration (for remote deployments)
host:
  host: your-server.example.com
  port: 22
  user: deploy
  ssh_key_path: ~/.ssh/id_rsa
  # password: xxx  # Not recommended, use SSH keys

# Ansible Configuration
ansible:
  # inventory_path: inventory.ini  # Optional, will generate temp inventory
  backend_playbook: playbooks/backend.yml
  database_playbook: playbooks/database.yml
  backup_playbook: playbooks/backup.yml
  extra_vars:
    deploy_user: deploy
    app_dir: /opt/dart_cloud
''' : '''
# Host configuration not needed for local deployment
# host: {}

# Ansible not needed for local deployment
# ansible: {}
'''}
''';
  }

  String _generateTomlConfig(String environment) {
    return '''
# Dart Cloud Deployment Configuration
# Environment: $environment

name = "dart_cloud_backend"
environment = "$environment"
project_path = "."
env_file_path = ".env"

[openbao]
address = "http://localhost:8200"
# token = "hvs.xxxxx"
token_path = "~/.openbao/token"
secret_path = "secret/data/dart_cloud/$environment"
# namespace = "admin"

[container]
runtime = "podman"
compose_file = "docker-compose.yml"
project_name = "dart_cloud"
network_name = "dart_cloud_network"

[container.services]
backend = "dart_cloud_backend"
postgres = "dart_cloud_postgres"

${environment != 'local' ? '''
[host]
host = "your-server.example.com"
port = 22
user = "deploy"
ssh_key_path = "~/.ssh/id_rsa"

[ansible]
backend_playbook = "playbooks/backend.yml"
database_playbook = "playbooks/database.yml"
backup_playbook = "playbooks/backup.yml"

[ansible.extra_vars]
deploy_user = "deploy"
app_dir = "/opt/dart_cloud"
''' : '''
# Host and Ansible not needed for local deployment
'''}
''';
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
