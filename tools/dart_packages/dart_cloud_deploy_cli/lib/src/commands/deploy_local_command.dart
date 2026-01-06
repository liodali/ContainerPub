import 'dart:io';
import 'package:args/command_runner.dart';
import '../models/deploy_config.dart';
import '../services/container_service.dart';
import '../services/openbao_service.dart';
import '../utils/console.dart';

class DeployLocalCommand extends Command<void> {
  @override
  final String name = 'deploy-local';

  @override
  final String description = 'Deploy locally using Podman/Docker (no Ansible)';

  DeployLocalCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Configuration file path',
        defaultsTo: 'deploy.yaml',
      )
      ..addFlag(
        'build',
        abbr: 'b',
        help: 'Force rebuild containers',
        defaultsTo: true,
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force recreate containers',
        defaultsTo: false,
      )
      ..addFlag(
        'skip-secrets',
        help: 'Skip fetching secrets from OpenBao',
        defaultsTo: false,
      )
      ..addOption(
        'service',
        abbr: 's',
        help: 'Deploy specific service only (backend, postgres)',
      );
  }

  @override
  Future<void> run() async {
    final configPath = argResults!['config'] as String;
    final build = argResults!['build'] as bool;
    final force = argResults!['force'] as bool;
    final skipSecrets = argResults!['skip-secrets'] as bool;
    final service = argResults!['service'] as String?;

    Console.header('Dart Cloud Local Deployment');

    // Load configuration
    DeployConfig config;
    try {
      config = await DeployConfig.load(configPath);
    } catch (e) {
      Console.error('Failed to load configuration: $e');
      exit(1);
    }

    if (!config.isLocal && config.environment != Environment.dev) {
      Console.warning(
        'Configuration is for ${config.environment.name} environment',
      );
      if (!Console.confirm('Continue with local deployment?')) {
        return;
      }
    }

    // Initialize container service
    final containerService = ContainerService(
      config: config.container,
      workingDirectory: config.projectPath,
    );

    // Check runtime
    Console.info('Checking container runtime...');
    if (!await containerService.checkRuntime()) {
      Console.error(
        'Container runtime (${config.container.runtime}) not found',
      );
      exit(1);
    }
    Console.success('${config.container.runtime} is available');

    if (!await containerService.checkComposeRuntime()) {
      Console.error('Compose runtime not found');
      exit(1);
    }
    Console.success('Compose is available');

    // Fetch secrets if configured
    if (!skipSecrets && config.openbao != null) {
      await _fetchSecrets(config);
    } else if (!skipSecrets) {
      Console.warning('OpenBao not configured, skipping secrets fetch');
      await _checkEnvFile(config);
    }

    // Check current status
    Console.header('Checking Service Status');
    final statuses = await containerService.getAllServicesStatus();

    for (final entry in statuses.entries) {
      final status = entry.value.status;
      final statusStr = switch (status) {
        ContainerStatus.running => '\x1B[32mRunning\x1B[0m',
        ContainerStatus.stopped => '\x1B[33mStopped\x1B[0m',
        ContainerStatus.notFound => '\x1B[31mNot Found\x1B[0m',
      };
      Console.keyValue(entry.key, statusStr);
    }

    // Handle existing services
    final hasRunning = statuses.values.any(
      (s) => s.status == ContainerStatus.running,
    );
    final hasStopped = statuses.values.any(
      (s) => s.status == ContainerStatus.stopped,
    );
    final hasAny = statuses.values.any(
      (s) => s.status != ContainerStatus.notFound,
    );

    if (hasAny && !force) {
      await _handleExistingServices(
        containerService,
        statuses,
        hasRunning,
        hasStopped,
        build,
      );
      return;
    }

    // Deploy
    await _deploy(containerService, service, build, force);
  }

  Future<void> _fetchSecrets(DeployConfig config) async {
    Console.header('Fetching Secrets from OpenBao');

    final openbao = OpenBaoService(
      address: config.openbao!.address,
      namespace: config.openbao!.namespace,
      token: config.openbao!.token,
      tokenPath: config.openbao!.tokenPath,
    );

    if (!await openbao.checkHealth()) {
      Console.warning('OpenBao is not reachable at ${config.openbao!.address}');
      if (!Console.confirm('Continue without secrets?')) {
        exit(1);
      }
      return;
    }

    try {
      final envPath = config.envFilePath ?? '.env';
      await openbao.writeEnvFile(config.openbao!.secretPath, envPath);
    } catch (e) {
      Console.error('Failed to fetch secrets: $e');
      if (!Console.confirm('Continue without secrets?')) {
        exit(1);
      }
    }
  }

  Future<void> _checkEnvFile(DeployConfig config) async {
    final envPath = config.envFilePath ?? '.env';
    final envFile = File(envPath);

    if (!await envFile.exists()) {
      Console.warning('.env file not found');

      final exampleFile = File('.env.example');
      if (await exampleFile.exists()) {
        if (Console.confirm('Create .env from .env.example?')) {
          await exampleFile.copy(envPath);
          Console.success('.env created from .env.example');
          Console.warning('Please update the values in .env before deploying');
        }
      }
    } else {
      Console.success('.env file found');
    }
  }

  Future<void> _handleExistingServices(
    ContainerService containerService,
    Map<String, ContainerInfo> statuses,
    bool hasRunning,
    bool hasStopped,
    bool build,
  ) async {
    Console.header('Services Already Exist');

    final options = <String>[
      'Start stopped services (without rebuilding)',
      'Rebuild backend only (keep PostgreSQL and data)',
      'Rebuild backend and remove its volume',
      'Remove everything (all containers + volumes)',
      'Cancel and exit',
    ];

    final choice = Console.menu('What would you like to do?', options);

    switch (choice) {
      case 0:
        Console.info('Starting stopped services...');
        await containerService.startServices();
        await _waitForServices(containerService);
        break;

      case 1:
        Console.info('Rebuilding backend only...');
        final backendName = containerService.config.services['backend'];
        if (backendName != null) {
          await containerService.removeContainer(backendName);
          await containerService.removeImage(backendName);
        }
        await containerService.startService('backend-cloud', build: true);
        await containerService.pruneImages();
        await _waitForServices(containerService);
        break;

      case 2:
        Console.info('Rebuilding backend and removing volume...');
        final backendName = containerService.config.services['backend'];
        if (backendName != null) {
          await containerService.removeContainer(backendName);
          await containerService.removeImage(backendName);
        }
        // Remove volume
        await Process.run(
          containerService.config.containerCommand.split(' ').last,
          [
            'volume',
            'rm',
            '${containerService.config.projectName}_backend_functions_data',
          ],
          runInShell: true,
        );
        await containerService.startService('backend-cloud', build: true);
        await _waitForServices(containerService);
        break;

      case 3:
        Console.warning('This will remove all data!');
        if (Console.confirm('Are you sure?')) {
          await containerService.removeVolumes();
          await containerService.pruneImages();
          Console.success('All services and volumes removed');
        }
        break;

      case 4:
      default:
        Console.info('Cancelled');
        return;
    }
  }

  Future<void> _deploy(
    ContainerService containerService,
    String? service,
    bool build,
    bool force,
  ) async {
    Console.header('Starting Services');

    bool success;
    if (service != null) {
      Console.info('Deploying service: $service');
      success = await containerService.startService(service, build: build);
    } else {
      Console.info('Deploying all services...');
      success = await containerService.startServices(
        build: build,
        forceRecreate: force,
      );
    }

    if (!success) {
      Console.error('Failed to start services');
      exit(1);
    }

    await containerService.pruneImages();
    await _waitForServices(containerService);
  }

  Future<void> _waitForServices(ContainerService containerService) async {
    Console.info('Waiting for services to be ready...');
    await Future.delayed(const Duration(seconds: 5));

    // Wait for PostgreSQL
    final postgresReady = await containerService.waitForPostgres('postgres');
    if (!postgresReady) {
      Console.error('PostgreSQL failed to start');
      final logs = await containerService.getLogs('postgres', lines: 50);
      Console.info('PostgreSQL logs:\n$logs');
      exit(1);
    }

    // Wait for backend
    final backendReady = await containerService.waitForBackend(
      'http://localhost:8080/health',
    );
    if (!backendReady) {
      Console.error('Backend failed to start');
      final logs = await containerService.getLogs('backend-cloud', lines: 50);
      Console.info('Backend logs:\n$logs');
      exit(1);
    }

    _printSuccess(containerService);
  }

  void _printSuccess(ContainerService containerService) {
    Console.header('Deployment Complete!');

    Console.divider();
    print('\x1B[34mService Endpoints:\x1B[0m');
    Console.divider();
    Console.keyValue('Backend API', '\x1B[32mhttp://localhost:8080\x1B[0m');
    Console.keyValue(
      'Health Check',
      '\x1B[32mhttp://localhost:8080/health\x1B[0m',
    );
    Console.keyValue(
      'PostgreSQL',
      '\x1B[32mpostgres:5432\x1B[0m (internal network)',
    );

    Console.divider();
    print('\x1B[34mManagement Commands:\x1B[0m');
    Console.divider();
    final compose = containerService.config.composeCommand;
    Console.keyValue('View all logs', '\x1B[33m$compose logs -f\x1B[0m');
    Console.keyValue(
      'View backend logs',
      '\x1B[33m$compose logs -f backend-cloud\x1B[0m',
    );
    Console.keyValue('Stop services', '\x1B[33m$compose down\x1B[0m');
    Console.keyValue('View status', '\x1B[33m$compose ps\x1B[0m');

    Console.divider();
    print('\x1B[34mDatabase Access:\x1B[0m');
    Console.divider();
    Console.keyValue(
      'Connect to DB',
      '\x1B[33m$compose exec postgres psql -U dart_cloud -d dart_cloud\x1B[0m',
    );

    print('');
    Console.success('All services are running successfully!');
    print('');
  }
}
