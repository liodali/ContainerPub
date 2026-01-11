import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';

import '../models/deploy_config.dart';
import '../services/container_service.dart';
import '../services/openbao_service.dart';
import '../utils/console.dart';
import '../utils/workspace_detector.dart';

// =============================================================================
// DEPLOY LOCAL COMMAND
// =============================================================================
// A robust local deployment command that:
// 1. Uses env file path from config as primary source
// 2. Falls back to OpenBao if no env file is provided
// 3. Throws exception if neither env file nor OpenBao secrets are available
// 4. Supports selective rebuild based on services in compose file
// =============================================================================

/// Enum defining rebuild strategies for deployment
enum RebuildStrategy {
  /// Rebuild all services defined in compose file
  all('all'),

  /// Rebuild only the backend service
  backendOnly('backend-only'),

  /// No rebuild, just start existing containers
  none('none')
  ;

  const RebuildStrategy(this.label);
  final String label;
}

/// Extension on RebuildStrategy to provide utility methods
extension RebuildStrategyExtension on RebuildStrategy {
  /// Get list of all valid rebuild strategy names
  static List<String> get names {
    return RebuildStrategy.values.map((e) => e.label).toList();
  }
}

/// Configuration for local deployment options
class LocalDeployOptions {
  /// Path to the deployment config file
  final String configPath;

  /// Path to environment file (overrides config)
  final String? envFilePath;

  /// Rebuild strategy to use (null = use config value)
  final RebuildStrategy? rebuildStrategy;

  /// Force recreate containers even if running
  final bool forceRecreate;

  /// Specific service to deploy (null = all services)
  final String? targetService;

  const LocalDeployOptions({
    required this.configPath,
    this.envFilePath,
    this.rebuildStrategy,
    this.forceRecreate = false,
    this.targetService,
  });
}

/// Main command for local deployment using Podman/Docker
class DeployLocalCommand extends Command<void> {
  @override
  final String name = 'deploy-local';

  @override
  final String description =
      'Deploy locally using Podman/Docker with flexible env and rebuild options';

  DeployLocalCommand() {
    _setupArgParser();
  }

  // ---------------------------------------------------------------------------
  // ARGUMENT PARSER SETUP
  // ---------------------------------------------------------------------------

  void _setupArgParser() {
    argParser
      // Config file path
      ..addOption(
        'config',
        abbr: 'c',
        help:
            'Path to deployment configuration file (yaml/toml). '
            'Defaults to ~/.dart-cloud-deploy/deploy_config.yml or '
            '.dart_tool/deploy_config.yml',
      )
      // Environment file path (overrides config)
      ..addOption(
        'env-file',
        abbr: 'e',
        help: 'Path to .env file (overrides config env_file_path)',
      )
      // Rebuild strategy
      ..addOption(
        'rebuild',
        abbr: 'r',
        help: 'Rebuild strategy: all, backend-only, none',
        allowed: RebuildStrategyExtension.names,
        defaultsTo: RebuildStrategy.none.label,
        mandatory: false,
      )
      // Force recreate
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force recreate containers even if running',
        defaultsTo: false,
      )
      // Target specific service
      ..addOption(
        'service',
        abbr: 's',
        help: 'Deploy specific service only (from compose file)',
      );
  }

  // ---------------------------------------------------------------------------
  // MAIN ENTRY POINT
  // ---------------------------------------------------------------------------

  @override
  Future<void> run() async {
    // Parse command line options
    final options = await _parseOptions();

    Console.header('Dart Cloud Local Deployment');

    // Step 1: Load and validate configuration
    final config = await _loadConfig(options.configPath);

    // Step 2: Initialize container service
    final containerService = await _initContainerService(config);

    // Step 3: Detect available services from compose file
    final availableServices = await _detectServicesFromCompose(config);

    // Step 4: Resolve environment variables (env file or OpenBao)
    await _resolveEnvironment(config, options.envFilePath);

    // Step 5: Check current service status
    final statuses = await _checkServiceStatus(containerService);

    // Step 6: Execute deployment based on strategy
    await _executeDeployment(
      containerService: containerService,
      availableServices: availableServices,
      statuses: statuses,
      options: options,
    );
  }

  /// Parse command line arguments into LocalDeployOptions
  /// Note: Rebuild strategy from CLI will override config file value
  Future<LocalDeployOptions> _parseOptions() async {
    final rebuildStr = argResults!['rebuild'] as String?;
    final configPathArg = argResults!['config'] as String?;

    // CLI rebuild flag takes precedence over config
    // If not provided via CLI, will be resolved from config later
    final rebuildStrategy = rebuildStr != null
        ? switch (rebuildStr) {
            'all' => RebuildStrategy.all,
            'backend-only' => RebuildStrategy.backendOnly,
            'none' => RebuildStrategy.none,
            _ => RebuildStrategy.all,
          }
        : null;

    // Resolve config path: CLI arg > workspace config > global config
    String configPath;

    if (configPathArg != null) {
      // User explicitly provided config path
      configPath = configPathArg;
    } else {
      // Use centralized config resolution
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

    return LocalDeployOptions(
      configPath: configPath,
      envFilePath: argResults!['env-file'] as String?,
      rebuildStrategy: rebuildStrategy,
      forceRecreate: argResults!['force'] as bool,
      targetService: argResults!['service'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: CONFIGURATION LOADING
  // ---------------------------------------------------------------------------

  /// Load and validate deployment configuration
  Future<DeployConfig> _loadConfig(String configPath) async {
    Console.info('Loading configuration from: $configPath');

    try {
      final config = await DeployConfig.load(configPath);

      // Verify 'local' environment exists in config
      if (config.local == null) {
        Console.error(
          'Configuration file does not contain "local" environment!\n'
          'The deploy-local command requires a "local" section in the config.\n'
          'Please add a "local" environment configuration.',
        );
        exit(1);
      }

      // Set current environment to local
      config.setCurrentEnvironment(Environment.local);

      Console.success('Configuration loaded successfully');
      return config;
    } catch (e) {
      Console.error('Failed to load configuration: $e');
      exit(1);
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 2: CONTAINER SERVICE INITIALIZATION
  // ---------------------------------------------------------------------------

  /// Initialize and validate container runtime
  Future<ContainerService> _initContainerService(DeployConfig config) async {
    Console.info('Checking container runtime...');

    final container = config.container;
    if (container == null) {
      Console.error('Container configuration is required');
      exit(1);
    }

    final containerService = ContainerService(
      config: container,
      workingDirectory: config.projectPath,
    );

    // Validate container runtime (podman/docker)
    if (!await containerService.checkRuntime()) {
      Console.error(
        'Container runtime (${container.runtime}) not found. '
        'Please install ${container.runtime} first.',
      );
      exit(1);
    }
    Console.success('${container.runtime} is available');

    // Validate compose runtime
    if (!await containerService.checkComposeRuntime()) {
      Console.error(
        'Compose runtime not found. '
        'Please install ${container.composeCommand} first.',
      );
      exit(1);
    }
    Console.success('Compose is available');

    return containerService;
  }

  // ---------------------------------------------------------------------------
  // STEP 3: SERVICE DETECTION FROM COMPOSE FILE
  // ---------------------------------------------------------------------------

  /// Detect available services from the compose file
  Future<List<String>> _detectServicesFromCompose(DeployConfig config) async {
    Console.info('Detecting services from compose file...');

    final container = config.container;
    if (container == null) {
      Console.error('Container configuration is required');
      exit(1);
    }

    final composeFile = File(
      '${config.projectPath}/${container.composeFile}',
    );

    if (!await composeFile.exists()) {
      Console.error('Compose file not found: ${container.composeFile}');
      exit(1);
    }

    try {
      final content = await composeFile.readAsString();
      final yaml = loadYaml(content) as YamlMap;
      final services = yaml['services'] as YamlMap?;

      if (services == null || services.isEmpty) {
        Console.error('No services defined in compose file');
        exit(1);
      }

      final serviceNames = services.keys.cast<String>().toList();
      Console.success(
        'Found ${serviceNames.length} services: '
        '${serviceNames.join(', ')}',
      );

      return serviceNames;
    } catch (e) {
      Console.error('Failed to parse compose file: $e');
      exit(1);
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 4: ENVIRONMENT RESOLUTION
  // ---------------------------------------------------------------------------

  /// Resolve environment variables from env file or OpenBao
  /// Priority: CLI --env-file > config env_file_path > OpenBao > Exception
  Future<void> _resolveEnvironment(
    DeployConfig config,
    String? cliEnvFilePath,
  ) async {
    Console.header('Resolving Environment Variables');

    // Priority 1: CLI provided env file path
    if (cliEnvFilePath != null) {
      await _validateEnvFile(cliEnvFilePath, config.projectPath);
      return;
    }

    // Priority 2: Config provided env file path
    if (config.envFilePath != null) {
      await _validateEnvFile(config.envFilePath!, config.projectPath);
      return;
    }

    // Priority 3: Fallback to OpenBao
    final envConfig = config.getEnvironmentConfig(config.environment!);
    if (envConfig?.openbao != null && config.envFilePath == null) {
      Console.info('No env file specified, attempting OpenBao...');
      await _fetchSecretsFromOpenBao(config);
      return;
    }

    // No environment source available - throw exception
    Console.error(
      'No environment configuration found!\n'
      'Please provide one of:\n'
      '  1. --env-file <path> argument\n'
      '  2. env_file_path in config file\n'
      '  3. openbao configuration in config file',
    );
    exit(1);
  }

  /// Validate that env file exists and is readable
  Future<void> _validateEnvFile(String envPath, String projectPath) async {
    // Handle relative paths
    final fullPath = envPath.startsWith('/')
        ? envPath
        : '$projectPath/$envPath';

    final envFile = File(fullPath);

    if (!await envFile.exists()) {
      Console.error('Environment file not found: $fullPath');

      // Check for .env.example as helper
      final exampleFile = File('$projectPath/.env.example');
      if (await exampleFile.exists()) {
        Console.info(
          'Found .env.example - you can copy it to create your env file',
        );
      }

      exit(1);
    }

    // Validate file is not empty
    final content = await envFile.readAsString();
    if (content.trim().isEmpty) {
      Console.error('Environment file is empty: $fullPath');
      exit(1);
    }

    Console.success('Environment file validated: $envPath');
  }

  /// Fetch secrets from OpenBao and write to .env file
  Future<void> _fetchSecretsFromOpenBao(DeployConfig config) async {
    final environment = config.environment;
    if (environment == null) {
      Console.error('Environment not found');
      exit(1);
    }

    final envConfig = config.getEnvironmentConfig(environment);
    final openbaoConfig = envConfig?.openbao;

    // Check if OpenBao has config for this environment
    if (openbaoConfig == null) {
      Console.error(
        'No OpenBao configuration for ${environment.name} environment.\n'
        'Please provide an env file or configure OpenBao for this environment.',
      );
      exit(1);
    }

    final openbao = OpenBaoService(
      config: openbaoConfig,
      environment: environment,
    );

    // Check OpenBao health
    if (!await openbao.checkHealth()) {
      Console.error(
        'OpenBao is not reachable at ${openbaoConfig.address}.\n'
        'Please provide an env file or ensure OpenBao is running.',
      );
      exit(1);
    }

    // Create token
    Console.info('Authenticating with OpenBao for ${environment.name}...');
    if (!await openbao.createToken()) {
      Console.error(
        'Failed to authenticate with OpenBao.\n'
        'Please check your credentials or provide an env file.',
      );
      exit(1);
    }

    // Fetch and write secrets
    try {
      final envPath = '${config.projectPath}/.env';
      await openbao.writeEnvFile(openbaoConfig.secretPath, envPath);
      Console.success('Secrets fetched from OpenBao and written to .env');
    } catch (e) {
      Console.error(
        'Failed to fetch secrets from OpenBao: $e\n'
        'Please provide an env file manually.',
      );
      exit(1);
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 5: SERVICE STATUS CHECK
  // ---------------------------------------------------------------------------

  /// Check current status of all services
  Future<Map<String, ContainerInfo>> _checkServiceStatus(
    ContainerService containerService,
  ) async {
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

    return statuses;
  }

  // ---------------------------------------------------------------------------
  // STEP 6: DEPLOYMENT EXECUTION
  // ---------------------------------------------------------------------------

  /// Execute deployment based on strategy and current state
  Future<void> _executeDeployment({
    required ContainerService containerService,
    required List<String> availableServices,
    required Map<String, ContainerInfo> statuses,
    required LocalDeployOptions options,
  }) async {
    final hasExisting = statuses.values.any(
      (s) => s.status != ContainerStatus.notFound,
    );

    // If services exist and not forcing, show interactive menu
    if (hasExisting && !options.forceRecreate) {
      await _handleExistingServices(
        containerService: containerService,
        availableServices: availableServices,
        statuses: statuses,
        options: options,
      );
      return;
    }

    // Fresh deployment or force recreate
    await _deployServices(
      containerService: containerService,
      availableServices: availableServices,
      options: options,
    );
  }

  /// Handle case when services already exist
  Future<void> _handleExistingServices({
    required ContainerService containerService,
    required List<String> availableServices,
    required Map<String, ContainerInfo> statuses,
    required LocalDeployOptions options,
  }) async {
    Console.header('Services Already Exist');

    // Build dynamic menu based on available services
    final menuOptions = <String>[
      'Start stopped services (no rebuild)',
      'Rebuild all services',
      if (availableServices.contains('backend-cloud') ||
          containerService.config.services.containsKey('backend'))
        'Rebuild backend only (keep database)',
      'Remove all containers and volumes (clean start)',
      'Cancel',
    ];

    final choice = Console.menu('Select action:', menuOptions);

    // Handle null or invalid choice
    if (choice == null || choice < 0 || choice >= menuOptions.length) {
      Console.info('Cancelled');
      return;
    }

    final selectedOption = menuOptions[choice];

    if (selectedOption.contains('Start stopped')) {
      await _startStoppedServices(containerService);
    } else if (selectedOption.contains('Rebuild all')) {
      await _deployServices(
        containerService: containerService,
        availableServices: availableServices,
        options: LocalDeployOptions(
          configPath: options.configPath,
          rebuildStrategy: RebuildStrategy.all, // Force rebuild all
          forceRecreate: true,
        ),
      );
    } else if (selectedOption.contains('Rebuild backend')) {
      await _rebuildBackendOnly(containerService);
    } else if (selectedOption.contains('Remove all')) {
      await _cleanAll(containerService);
    } else {
      Console.info('Cancelled');
      return;
    }
  }

  /// Start stopped services without rebuilding
  Future<void> _startStoppedServices(ContainerService containerService) async {
    Console.info('Starting stopped services...');
    await containerService.startServices();
    await _waitForServices(containerService);
  }

  /// Rebuild only the backend service
  Future<void> _rebuildBackendOnly(ContainerService containerService) async {
    Console.info('Rebuilding backend only...');

    final backendName =
        containerService.config.services['backend'] ?? 'backend-cloud';

    // Stop and remove backend container
    await containerService.removeContainer(backendName);
    await containerService.removeImage(backendName);

    // Rebuild and start backend
    await containerService.startService(backendName, build: true);
    await containerService.pruneImages();
    await _waitForServices(containerService);
  }

  /// Remove all containers and volumes
  Future<void> _cleanAll(ContainerService containerService) async {
    Console.warning('This will remove ALL data including database!');

    if (!Console.confirm('Are you absolutely sure?')) {
      Console.info('Cancelled');
      return;
    }

    Console.info('Removing all containers and volumes...');
    await containerService.removeVolumes();
    await containerService.pruneImages();
    Console.success('All services and volumes removed');
  }

  /// Deploy services based on rebuild strategy
  Future<void> _deployServices({
    required ContainerService containerService,
    required List<String> availableServices,
    required LocalDeployOptions options,
  }) async {
    Console.header('Starting Deployment');

    // Resolve rebuild strategy: CLI > Config > Default
    final rebuildStrategy =
        options.rebuildStrategy ??
        _parseRebuildStrategyFromConfig(
          containerService.config.rebuildStrategy,
        );

    bool success;

    // Handle specific service target
    if (options.targetService != null) {
      if (!availableServices.contains(options.targetService)) {
        Console.error(
          'Service "${options.targetService}" not found in compose file.\n'
          'Available services: ${availableServices.join(', ')}',
        );
        exit(1);
      }

      Console.info('Deploying service: ${options.targetService}');
      success = await containerService.startService(
        options.targetService!,
        build: rebuildStrategy != RebuildStrategy.none,
      );
    } else {
      // Deploy based on rebuild strategy
      switch (rebuildStrategy) {
        case RebuildStrategy.all:
          Console.info('Deploying all services with rebuild...');
          success = await containerService.startServices(
            build: true,
            forceRecreate: options.forceRecreate,
          );

        case RebuildStrategy.backendOnly:
          Console.info('Deploying with backend rebuild only...');
          // Start database first without rebuild
          final dbService =
              containerService.config.services['postgres'] ?? 'postgres';
          if (availableServices.contains(dbService)) {
            await containerService.startService(dbService, build: false);
          }
          // Then rebuild backend
          final backendService =
              containerService.config.services['backend'] ?? 'backend-cloud';
          success = await containerService.startService(
            backendService,
            build: true,
          );

        case RebuildStrategy.none:
          Console.info('Starting services without rebuild...');
          success = await containerService.startServices(
            build: false,
            forceRecreate: options.forceRecreate,
          );
      }
    }

    if (!success) {
      Console.error('Failed to start services');
      exit(1);
    }

    await containerService.pruneImages();
    await _waitForServices(containerService);
  }

  /// Parse rebuild strategy from config string value
  RebuildStrategy _parseRebuildStrategyFromConfig(String configValue) {
    return switch (configValue) {
      'all' => RebuildStrategy.all,
      'backend-only' => RebuildStrategy.backendOnly,
      'none' => RebuildStrategy.none,
      _ => RebuildStrategy.all, // Default fallback
    };
  }

  // ---------------------------------------------------------------------------
  // SERVICE HEALTH CHECKS
  // ---------------------------------------------------------------------------

  /// Wait for all services to be healthy
  Future<void> _waitForServices(ContainerService containerService) async {
    Console.info('Waiting for services to be ready...');
    await Future.delayed(const Duration(seconds: 5));

    // Wait for PostgreSQL if it exists in config
    if (containerService.config.services.containsKey('postgres')) {
      final postgresService = containerService.config.services['postgres']!;
      final postgresReady = await containerService.waitForPostgres(
        postgresService,
      );

      if (!postgresReady) {
        Console.error('PostgreSQL failed to start');
        final logs = await containerService.getLogs(postgresService, lines: 50);
        Console.info('PostgreSQL logs:\n$logs');
        exit(1);
      }
    }

    // Wait for backend if it exists in config
    if (containerService.config.services.containsKey('backend')) {
      final backendReady = await containerService.waitForBackend(
        'http://localhost:8080/health',
      );

      if (!backendReady) {
        Console.error('Backend failed to start');
        final backendService = containerService.config.services['backend']!;
        final logs = await containerService.getLogs(backendService, lines: 50);
        Console.info('Backend logs:\n$logs');
        exit(1);
      }
    }

    _printSuccess(containerService);
  }

  // ---------------------------------------------------------------------------
  // SUCCESS OUTPUT
  // ---------------------------------------------------------------------------

  /// Print deployment success message with useful commands
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
