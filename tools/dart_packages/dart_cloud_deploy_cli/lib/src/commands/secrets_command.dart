import 'dart:io';
import 'package:args/command_runner.dart';
import '../models/deploy_config.dart';
import '../services/openbao_service.dart';
import '../utils/console.dart';

class SecretsCommand extends Command<void> {
  @override
  final String name = 'secrets';

  @override
  final String description = 'Manage secrets from OpenBao';

  SecretsCommand() {
    addSubcommand(_SecretsFetchCommand());
    addSubcommand(_SecretsListCommand());
    addSubcommand(_SecretsCheckCommand());
  }
}

class _SecretsFetchCommand extends Command<void> {
  @override
  final String name = 'fetch';

  @override
  final String description =
      'Fetch secrets from OpenBao and write to .env file';

  _SecretsFetchCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Configuration file path',
        defaultsTo: 'deploy.yaml',
      )
      ..addOption('output', abbr: 'o', help: 'Output .env file path')
      ..addOption('path', abbr: 'p', help: 'Override secret path in OpenBao')
      ..addOption(
        'env',
        abbr: 'e',
        help: 'Environment to use',
        allowed: ['local', 'staging', 'production'],
        defaultsTo: 'local',
      );
  }

  @override
  Future<void> run() async {
    final configPath = argResults!['config'] as String;
    final outputPath = argResults!['output'] as String?;
    final secretPathOverride = argResults!['path'] as String?;
    final envStr = argResults!['env'] as String;
    final environment = Environment.values.firstWhere(
      (e) => e.name == envStr,
      orElse: () => Environment.local,
    );

    Console.header('Fetching Secrets from OpenBao (${environment.name})');

    DeployConfig config;
    try {
      config = await DeployConfig.load(configPath);
    } catch (e) {
      Console.error('Failed to load configuration: $e');
      exit(1);
    }

    final envConfig = config.getEnvironmentConfig(environment);
    final openbaoConfig = envConfig?.openbao;

    if (openbaoConfig == null) {
      Console.error(
        'No OpenBao configuration for ${environment.name} environment in $configPath',
      );
      exit(1);
    }

    final openbao = OpenBaoService(
      config: openbaoConfig,
      environment: environment,
    );

    Console.info('Checking OpenBao health...');
    if (!await openbao.checkHealth()) {
      Console.error('OpenBao is not reachable at ${openbaoConfig.address}');
      exit(1);
    }
    Console.success('OpenBao is healthy');

    Console.info('Creating token for ${environment.name}...');
    if (!await openbao.createToken()) {
      Console.error('Failed to create token');
      exit(1);
    }

    final path = secretPathOverride ?? openbao.secretPath;

    final output = outputPath ?? config.envFilePath ?? '.env';

    try {
      await openbao.writeEnvFile(path, output);
      Console.success('Secrets written to $output');
    } catch (e) {
      Console.error('Failed to fetch secrets: $e');
      exit(1);
    }
  }
}

class _SecretsListCommand extends Command<void> {
  @override
  final String name = 'list';

  @override
  final String description = 'List available secrets in OpenBao';

  _SecretsListCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Configuration file path',
        defaultsTo: 'deploy.yaml',
      )
      ..addOption('path', abbr: 'p', help: 'Path to list secrets from')
      ..addOption(
        'env',
        abbr: 'e',
        help: 'Environment to use',
        allowed: ['local', 'staging', 'production'],
        defaultsTo: 'local',
      );
  }

  @override
  Future<void> run() async {
    final configPath = argResults!['config'] as String;
    final listPath = argResults!['path'] as String?;
    final envStr = argResults!['env'] as String;
    final environment = Environment.values.firstWhere(
      (e) => e.name == envStr,
      orElse: () => Environment.local,
    );

    Console.header('Listing Secrets (${environment.name})');

    DeployConfig config;
    try {
      config = await DeployConfig.load(configPath);
    } catch (e) {
      Console.error('Failed to load configuration: $e');
      exit(1);
    }

    final envConfig = config.getEnvironmentConfig(environment);
    final openbaoConfig = envConfig?.openbao;

    if (openbaoConfig == null) {
      Console.error(
        'No OpenBao configuration for ${environment.name} environment in $configPath',
      );
      exit(1);
    }

    final openbao = OpenBaoService(
      config: openbaoConfig,
      environment: environment,
    );

    Console.info('Creating token for ${environment.name}...');
    if (!await openbao.createToken()) {
      Console.error('Failed to create token');
      exit(1);
    }

    final path = listPath ?? 'secret/metadata/dart_cloud';

    try {
      final secrets = await openbao.listSecrets(path);

      if (secrets.isEmpty) {
        Console.info('No secrets found at $path');
        return;
      }

      Console.info('Secrets at $path:');
      for (final secret in secrets) {
        Console.step('  $secret');
      }
    } catch (e) {
      Console.error('Failed to list secrets: $e');
      exit(1);
    }
  }
}

class _SecretsCheckCommand extends Command<void> {
  @override
  final String name = 'check';

  @override
  final String description = 'Check OpenBao connection and authentication';

  _SecretsCheckCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Configuration file path',
        defaultsTo: 'deploy.yaml',
      )
      ..addOption(
        'env',
        abbr: 'e',
        help: 'Environment to use',
        allowed: ['local', 'staging', 'production'],
        defaultsTo: 'local',
      );
  }

  @override
  Future<void> run() async {
    final configPath = argResults!['config'] as String;
    final envStr = argResults!['env'] as String;
    final environment = Environment.values.firstWhere(
      (e) => e.name == envStr,
      orElse: () => Environment.local,
    );

    Console.header('Checking OpenBao Connection (${environment.name})');

    DeployConfig config;
    try {
      config = await DeployConfig.load(configPath);
    } catch (e) {
      Console.error('Failed to load configuration: $e');
      exit(1);
    }

    final envConfig = config.getEnvironmentConfig(environment);
    final openbaoConfig = envConfig?.openbao;

    if (openbaoConfig == null) {
      Console.error(
        'No OpenBao configuration for ${environment.name} environment in $configPath',
      );
      exit(1);
    }

    Console.keyValue('Address', openbaoConfig.address);
    Console.keyValue('Environment', environment.name);
    Console.keyValue('Token Manager', openbaoConfig.tokenManager);
    Console.keyValue('Policy', openbaoConfig.policy);
    Console.keyValue('Secret Path', openbaoConfig.secretPath);
    if (openbaoConfig.namespace != null) {
      Console.keyValue('Namespace', openbaoConfig.namespace!);
    }

    final openbao = OpenBaoService(
      config: openbaoConfig,
      environment: environment,
    );

    Console.info('Checking health...');
    if (await openbao.checkHealth()) {
      Console.success('OpenBao is healthy and reachable');
    } else {
      Console.error('OpenBao is not reachable');
      exit(1);
    }

    Console.info('Creating token for ${environment.name}...');
    if (!await openbao.createToken()) {
      Console.error('Failed to create token');
      exit(1);
    }
    Console.success('Token created successfully');

    Console.info('Testing secret access...');
    try {
      final secrets = await openbao.fetchSecrets(openbaoConfig.secretPath);
      Console.success('Successfully accessed secrets (${secrets.length} keys)');

      Console.info('Available keys:');
      for (final key in secrets.keys) {
        Console.step('  $key');
      }
    } catch (e) {
      Console.error('Failed to access secrets: $e');
      exit(1);
    }
  }
}
