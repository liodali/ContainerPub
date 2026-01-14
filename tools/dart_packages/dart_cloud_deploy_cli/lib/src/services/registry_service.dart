import 'dart:convert';
import 'dart:io';
import '../models/deploy_config.dart';
import '../utils/console.dart';

class RegistryService {
  final RegistryConfig config;
  final String containerRuntime;

  RegistryService({
    required this.config,
    this.containerRuntime = 'podman',
  });

  Future<bool> login() async {
    Console.info('Logging into registry: ${config.url}');

    try {
      final decodedToken = config.decodedToken;

      final process = await Process.start(containerRuntime, [
        'login',
        config.url,
        '--username',
        config.username,
        '--password-stdin',
      ]);

      process.stdin.write(decodedToken);
      await process.stdin.close();

      final exitCode = await process.exitCode;
      final stderr = await process.stderr.transform(utf8.decoder).join();

      if (exitCode == 0) {
        Console.success('Successfully logged into registry');
        return true;
      } else {
        Console.error('Failed to login to registry: $stderr');
        return false;
      }
    } catch (e) {
      Console.error('Error during registry login: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    Console.info('Logging out from registry: ${config.url}');

    try {
      final result = await Process.run(containerRuntime, [
        'logout',
        config.url,
      ]);

      if (result.exitCode == 0) {
        Console.success('Successfully logged out from registry');
        return true;
      } else {
        Console.warning('Failed to logout from registry: ${result.stderr}');
        return false;
      }
    } catch (e) {
      Console.warning('Error during registry logout: $e');
      return false;
    }
  }

  Future<bool> buildImage({
    required String imageName,
    required String tag,
    required String dockerfilePath,
    required String contextPath,
    List<String> buildArgs = const [],
  }) async {
    final fullImageName = '${config.url}/$imageName:$tag';
    Console.info('Building image: $fullImageName');

    try {
      final args = ['build', '-t', fullImageName, '-f', dockerfilePath];

      for (final arg in buildArgs) {
        args.addAll(['--build-arg', arg]);
      }

      args.add(contextPath);

      Console.info('Running: $containerRuntime ${args.join(' ')}');

      final result = await Process.run(
        containerRuntime,
        args,
        workingDirectory: contextPath,
      );

      if (result.exitCode == 0) {
        Console.success('Successfully built image: $fullImageName');
        if (result.stdout.toString().isNotEmpty) {
          Console.info(result.stdout.toString());
        }
        return true;
      } else {
        Console.error('Failed to build image: ${result.stderr}');
        if (result.stdout.toString().isNotEmpty) {
          Console.error(result.stdout.toString());
        }
        return false;
      }
    } catch (e) {
      Console.error('Error during image build: $e');
      return false;
    }
  }

  Future<bool> pushImage({
    required String imageName,
    required String tag,
  }) async {
    final fullImageName = '${config.url}/$imageName:$tag';
    Console.info('Pushing image: $fullImageName');

    try {
      final result = await Process.run(containerRuntime, [
        'push',
        fullImageName,
      ]);

      if (result.exitCode == 0) {
        Console.success('Successfully pushed image: $fullImageName');
        if (result.stdout.toString().isNotEmpty) {
          Console.info(result.stdout.toString());
        }
        return true;
      } else {
        Console.error('Failed to push image: ${result.stderr}');
        if (result.stdout.toString().isNotEmpty) {
          Console.error(result.stdout.toString());
        }
        return false;
      }
    } catch (e) {
      Console.error('Error during image push: $e');
      return false;
    }
  }

  Future<bool> buildAndPush({
    required String imageName,
    required String tag,
    required String dockerfilePath,
    required String contextPath,
    List<String> buildArgs = const [],
  }) async {
    if (!await login()) {
      return false;
    }

    try {
      if (!await buildImage(
        imageName: imageName,
        tag: tag,
        dockerfilePath: dockerfilePath,
        contextPath: contextPath,
        buildArgs: buildArgs,
      )) {
        return false;
      }

      if (!await pushImage(imageName: imageName, tag: tag)) {
        return false;
      }

      return true;
    } finally {
      await logout();
    }
  }

  String getFullImageName(String imageName, String tag) {
    return '${config.registryCompanyHostName}/$imageName:$tag';
  }
}
