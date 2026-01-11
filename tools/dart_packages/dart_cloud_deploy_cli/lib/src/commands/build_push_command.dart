import 'dart:io';
import 'package:args/command_runner.dart';
import '../models/deploy_config.dart';
import '../services/registry_service.dart';
import '../utils/console.dart';
import '../utils/workspace_detector.dart';

class BuildPushCommand extends Command<void> {
  @override
  final String name = 'build-push';

  @override
  final String description = 'Build container image and push to Gitea registry';

  BuildPushCommand() {
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
        'image-name',
        abbr: 'i',
        help: 'Image name (without registry URL)',
        mandatory: true,
      )
      ..addOption('tag', abbr: 't', help: 'Image tag', defaultsTo: 'latest')
      ..addOption(
        'dockerfile',
        abbr: 'd',
        help: 'Path to Dockerfile',
        defaultsTo: 'Dockerfile',
      )
      ..addOption('context', help: 'Build context path', defaultsTo: '.')
      ..addMultiOption('build-arg', help: 'Build arguments (key=value)')
      ..addFlag(
        'no-push',
        help: 'Build only, do not push to registry',
        defaultsTo: false,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Verbose output',
        defaultsTo: false,
      );
  }

  @override
  Future<void> run() async {
    final configPathArg = argResults!['config'] as String?;
    final imageName = argResults!['image-name'] as String;
    final tag = argResults!['tag'] as String;
    final dockerfilePath = argResults!['dockerfile'] as String;
    final contextPath = argResults!['context'] as String;
    final buildArgs = argResults!['build-arg'] as List<String>;
    final noPush = argResults!['no-push'] as bool;

    Console.header('Container Build & Push');

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

    // Load configuration
    DeployConfig config;
    try {
      config = await DeployConfig.load(configPath);
    } catch (e) {
      Console.error('Failed to load configuration: $e');
      exit(1);
    }

    // Validate registry configuration
    if (config.registry == null) {
      Console.error('Registry configuration required for build-push');
      Console.info('Add registry section to your configuration file:');
      Console.info('''
registry:
  url: gitea.example.com
  username: your-username
  token_base64: <base64-encoded-token>
''');
      exit(1);
    }

    // Validate Dockerfile exists
    final dockerfileFile = File(dockerfilePath);
    if (!await dockerfileFile.exists()) {
      Console.error('Dockerfile not found: $dockerfilePath');
      exit(1);
    }

    // Validate context path exists
    final contextDir = Directory(contextPath);
    if (!await contextDir.exists()) {
      Console.error('Build context not found: $contextPath');
      exit(1);
    }

    // Validate container configuration
    final container = config.container;
    if (container == null) {
      Console.error('Container configuration required for build-push');
      Console.info('Add container section to your configuration file');
      exit(1);
    }

    // Initialize registry service
    final registryService = RegistryService(
      config: config.registry!,
      containerRuntime: container.runtime,
    );

    Console.info('Image: ${registryService.getFullImageName(imageName, tag)}');
    Console.info('Dockerfile: $dockerfilePath');
    Console.info('Context: $contextPath');
    if (buildArgs.isNotEmpty) {
      Console.info('Build args: ${buildArgs.join(', ')}');
    }

    try {
      if (noPush) {
        // Build only
        Console.header('Building Image');

        if (!await registryService.login()) {
          Console.error('Failed to login to registry');
          exit(1);
        }

        final success = await registryService.buildImage(
          imageName: imageName,
          tag: tag,
          dockerfilePath: dockerfilePath,
          contextPath: contextPath,
          buildArgs: buildArgs,
        );

        await registryService.logout();

        if (!success) {
          Console.error('Build failed');
          exit(1);
        }

        Console.header('Build Complete!');
        Console.success(
          'Image built successfully: ${registryService.getFullImageName(imageName, tag)}',
        );
      } else {
        // Build and push
        Console.header('Building and Pushing Image');

        final success = await registryService.buildAndPush(
          imageName: imageName,
          tag: tag,
          dockerfilePath: dockerfilePath,
          contextPath: contextPath,
          buildArgs: buildArgs,
        );

        if (!success) {
          Console.error('Build or push failed');
          exit(1);
        }

        Console.header('Build & Push Complete!');
        Console.success(
          'Image pushed successfully: ${registryService.getFullImageName(imageName, tag)}',
        );
      }
    } catch (e) {
      Console.error('Error during build/push: $e');
      exit(1);
    }
  }
}
