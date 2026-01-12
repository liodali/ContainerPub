import 'dart:io';
import '../models/deploy_config.dart';
import '../utils/console.dart';

enum ContainerStatus { running, stopped, notFound }

class ContainerInfo {
  final String name;
  final ContainerStatus status;
  final String? id;

  ContainerInfo({required this.name, required this.status, this.id});
}

class ContainerService {
  final ContainerConfig config;
  final String workingDirectory;

  ContainerService({required this.config, required this.workingDirectory});

  String get _runtime => config.containerCommand;
  String get _compose => config.composeCommand;

  Future<ProcessResult> _run(
    String command,
    List<String> args, {
    bool silent = false,
  }) async {
    if (!silent) {
      Console.step('Running: $command ${args.join(' ')}');
    }
    return Process.run(
      command,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
  }

  Future<bool> checkRuntime() async {
    try {
      final result = await _run(_runtime.split(' ').last, [
        '--version',
      ], silent: true);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkComposeRuntime() async {
    try {
      final parts = _compose.split(' ');
      final result = await _run(parts.first, [
        ...parts.skip(1),
        'version',
      ], silent: true);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<ContainerInfo> getContainerStatus(String containerName) async {
    Console.info('Checking container status: $containerName');
    final result = await _run(_runtime, [
      'container',
      'ls',
      '--format',
      '{{.Names}}:{{.Status}}',
    ], silent: true);

    if (result.exitCode != 0) {
      return ContainerInfo(
        name: containerName,
        status: ContainerStatus.notFound,
      );
    }

    final lines = (result.stdout as String).split('\n');
    for (final line in lines) {
      if (line.contains(containerName)) {
        final isRunning = line.toLowerCase().contains('up');
        return ContainerInfo(
          name: containerName,
          status: isRunning ? ContainerStatus.running : ContainerStatus.stopped,
        );
      }
    }

    return ContainerInfo(name: containerName, status: ContainerStatus.notFound);
  }

  Future<Map<String, ContainerInfo>> getAllServicesStatus() async {
    final statuses = <String, ContainerInfo>{};
    for (final service in config.services.keys) {
      final containerName = config.services[service]!;
      statuses[service] = await getContainerStatus(containerName);
    }
    return statuses;
  }

  Future<bool> startServices({
    bool build = false,
    bool forceRecreate = false,
  }) async {
    final parts = _compose.split(' ');
    final args = [
      ...parts.skip(1),
      '-p',
      config.projectName,
      '-f',
      config.composeFile,
      'up',
      '-d',
    ];

    if (build) args.add('--build');
    if (forceRecreate) args.add('--force-recreate');

    final result = await _run(parts.first, args);
    return result.exitCode == 0;
  }

  Future<bool> startService(String serviceName, {bool build = false}) async {
    final parts = _compose.split(' ');
    final args = [
      ...parts.skip(1),
      '-p',
      config.projectName,
      '-f',
      config.composeFile,
      'up',
      '-d',
    ];

    if (build) args.add('--build');
    args.add(serviceName);

    final result = await _run(parts.first, args);
    return result.exitCode == 0;
  }

  Future<bool> stopServices() async {
    final parts = _compose.split(' ');
    final result = await _run(parts.first, [
      ...parts.skip(1),
      '-p',
      config.projectName,
      '-f',
      config.composeFile,
      'down',
    ]);
    return result.exitCode == 0;
  }

  Future<bool> stopService(String serviceName) async {
    final parts = _compose.split(' ');
    final result = await _run(parts.first, [
      ...parts.skip(1),
      '-p',
      config.projectName,
      '-f',
      config.composeFile,
      'stop',
      serviceName,
    ]);
    return result.exitCode == 0;
  }

  Future<bool> restartServices() async {
    final parts = _compose.split(' ');
    final result = await _run(parts.first, [
      ...parts.skip(1),
      '-p',
      config.projectName,
      '-f',
      config.composeFile,
      'restart',
    ]);
    return result.exitCode == 0;
  }

  Future<bool> removeVolumes() async {
    final parts = _compose.split(' ');
    final result = await _run(parts.first, [
      ...parts.skip(1),
      '-p',
      config.projectName,
      '-f',
      config.composeFile,
      'down',
      '-v',
    ]);
    return result.exitCode == 0;
  }

  Future<bool> removeContainer(String containerName) async {
    final runtimeCmd = _runtime.split(' ');
    await _run(runtimeCmd.last, ['stop', containerName], silent: true);
    final result = await _run(runtimeCmd.last, ['rm', '-f', containerName]);
    return result.exitCode == 0;
  }

  Future<bool> removeImage(String imageName) async {
    final runtimeCmd = _runtime.split(' ');
    final result = await _run(runtimeCmd.last, ['rmi', imageName]);
    return result.exitCode == 0;
  }

  Future<bool> pruneImages() async {
    final runtimeCmd = _runtime.split(' ');
    final result = await _run(runtimeCmd.last, ['image', 'prune', '-f']);
    return result.exitCode == 0;
  }

  Future<String> getLogs(String serviceName, {int? lines}) async {
    final parts = _compose.split(' ');
    final args = [
      ...parts.skip(1),
      '-p',
      config.projectName,
      '-f',
      config.composeFile,
      'logs',
    ];

    if (lines != null) {
      args.addAll(['--tail', lines.toString()]);
    }
    args.add(serviceName);

    final result = await _run(parts.first, args, silent: true);
    return result.stdout as String;
  }

  Future<bool> execInContainer(String serviceName, List<String> command) async {
    final result = await _run(_runtime, [
      'exec',
      '-t',
      serviceName,
      ...command,
    ]);
    return result.exitCode == 0;
  }

  Future<bool> waitForPostgres(
    String serviceName, {
    int maxAttempts = 30,
  }) async {
    Console.info('Waiting for PostgreSQL to be ready...');

    for (var i = 0; i < maxAttempts; i++) {
      final ready = await execInContainer(serviceName, [
        'pg_isready',
        '-U',
        'dart_cloud',
      ]);
      if (ready) {
        Console.success('PostgreSQL is ready');
        return true;
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    Console.error('PostgreSQL failed to start within ${maxAttempts}s');
    return false;
  }

  Future<bool> waitForBackend(String healthUrl, {int maxAttempts = 30}) async {
    Console.info('Waiting for backend to be ready...');

    for (var i = 0; i < maxAttempts; i++) {
      try {
        final result = await Process.run('curl', ['-sf', healthUrl]);
        if (result.exitCode == 0) {
          Console.success('Backend is ready');
          return true;
        }
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 1));
    }

    Console.error('Backend failed to start within ${maxAttempts}s');
    return false;
  }
}
