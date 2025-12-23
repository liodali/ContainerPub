import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_cloud_backend/services/docker/container_data.dart';

import 'container_runtime.dart';

/// Podman implementation of ContainerRuntime
///
/// Uses Podman as the container runtime with rootless execution.
/// Podman CLI is Docker-compatible, making it a drop-in replacement.
class PodmanRuntime implements ContainerRuntime {
  final String _executable;

  /// Create a PodmanRuntime instance
  ///
  /// [executable] defaults to 'podman' but can be overridden for testing
  /// or custom installations
  PodmanRuntime({String executable = 'podman'}) : _executable = executable;

  @override
  String get name => 'podman';

  @override
  Future<Architecture> getArch() async {
    final result = await Process.run(_executable, ['info', '--format', '{{.Host.Arch}}']);
    final arch = result.stdout.toString().trim();
    if (arch == 'amd64') return Architecture.x64;
    if (arch == 'arm64') return Architecture.arm64;
    throw Exception('Unsupported architecture: $arch');
  }

  @override
  Future<ArchitecturePlatform> getArchPlatform() async {
    final result = await Process.run(_executable, [
      'info',
      '--format',
      '{{.Version.OsArch}}',
    ]);
    final archPlatform = result.stdout.toString().trim();
    if (archPlatform == 'linux/arm64') return ArchitecturePlatform.linuxArm64;
    if (archPlatform == 'linux/amd64') return ArchitecturePlatform.linuxX64;
    throw Exception('Unsupported architecture platform: $archPlatform');
  }

  @override
  Future<String?> getImagePlatform(String imageTag) async {
    final result = await Process.run(
      _executable,
      ['image', 'inspect', imageTag, '--format', '{{.Os}}/{{.Architecture}}'],
    );
    if (result.exitCode != 0) {
      return null;
    }
    return result.stdout.toString().trim();
  }

  @override
  Future<void> ensureImagePlatformCompatibility(
    String imageTag,
    ArchitecturePlatform targetPlatform,
  ) async {
    final currentPlatform = await getImagePlatform(imageTag);
    if (currentPlatform == null) {
      return;
    }
    if (currentPlatform != targetPlatform.buildPlatform) {
      print(
        '[Podman] Image $imageTag has platform $currentPlatform, '
        'expected ${targetPlatform.buildPlatform}. Removing...',
      );
      await removeImage(imageTag, force: true);
    }
  }

  @override
  Future<ProcessResult> buildImage({
    required String imageTag,
    required String dockerfilePath,
    required String contextDir,
    Duration timeout = const Duration(minutes: 5),
    void Function(String)? onStdout,
    void Function(String)? onStderr,
  }) async {
    // Get architecture platform
    final archPlatform = await getArchPlatform();
    final platformStr = archPlatform.buildPlatform;
    final process = await Process.start(
      _executable,
      [
        'build',
        '--platform',
        platformStr,
        '-t',
        imageTag,
        '-f',
        dockerfilePath,
        contextDir,
      ],
    );

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    process.stdout.transform(utf8.decoder).listen((data) {
      stdoutBuffer.write(data);
      onStdout?.call(data);
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      stderrBuffer.write(data);
      onStderr?.call(data);
    });

    final exitCode = await process.exitCode.timeout(
      timeout,
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        throw TimeoutException('Build timed out after ${timeout.inMinutes} minutes');
      },
    );

    return ImageProcessResult(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
    );
  }

  @override
  Future<ProcessResult> runContainer({
    required String imageTag,
    required String containerName,
    Map<String, String> environment = const {},
    String? envFilePath,
    List<String> volumeMounts = const [],
    int memoryMb = 20,
    String memoryUnit = 'm',
    double cpus = 0.5,
    String network = 'none',
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final args = [
      'run',
      '--rm',
      '--name',
      containerName,
      '--memory',
      '${memoryMb}$memoryUnit',
      '--memory-swap',
      '${memoryMb}$memoryUnit',
      '--cpus',
      cpus.toString(),
      '--storage-opt',
      'size=50M',
      if (network != 'none') ...[
        '--network',
        network,
      ],
    ];

    // Add volume mounts
    for (final mount in volumeMounts) {
      args.addAll(['-v', mount]);
    }

    // // Add env file if provided (preferred method)
    // if (envFilePath != null) {
    //   args.addAll(['--env-file', envFilePath]);
    // }

    // Add environment variables (legacy support)
    environment.forEach((key, value) {
      args.addAll(['-e', '$key=$value']);
    });

    // Add image tag
    args.add(imageTag);

    final process = await Process.start(_executable, args);

    final stdout = <String, dynamic>{};
    final stderrBuffer = StringBuffer();

    process.stdout.transform(utf8.decoder).listen((data) {
      final lines = data.split("\n").where((e) => e.isNotEmpty).toList();
      final stdOutStr = lines.last;
      lines.removeLast();
      stdout.addAll(
        {
          'stdout': stdOutStr,
          'logs': jsonEncode(lines),
        },
      );
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      stderrBuffer.write(data);
    });
    final exitCode = await process.exitCode.timeout(
      timeout,
      onTimeout: () async {
        await killContainer(containerName);
        return -1;
      },
    );

    return ContainerProcessResult(
      exitCode: exitCode,
      stdout: stdout,
      stderr: stderrBuffer.toString(),
      isTimeout: exitCode == -1,
      containerConfiguration: {
        'memory_usage': memoryMb,
      },
    );
  }

  @override
  Future<ProcessResult> removeImage(
    String imageTag, {
    bool force = true,
  }) async {
    final args = ['rmi'];
    if (force) args.add('-f');
    args.add(imageTag);

    final result = await Process.run(_executable, args);
    return ImageProcessResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }

  @override
  Future<ProcessResult> killContainer(String containerName) async {
    final result = await Process.run(_executable, ['kill', containerName]);
    return ImageProcessResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run(_executable, ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getVersion() async {
    try {
      final result = await Process.run(_executable, ['--version']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> imageExists(String imageTag) async {
    try {
      final result = await Process.run(_executable, [
        'images',
        '--format',
        '{{.Repository}}:{{.Tag}}',
        imageTag,
      ]);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> prune() async {
    await Process.run(_executable, ['image', 'prune', '-f']);
  }

  @override
  Future<ImageSizeData> getImageSize(String imageTag) async {
    final cmdResult = await Process.run(_executable, [
      'images',
      '--format',
      '"{{.Size}}"',
      imageTag,
    ]);
    final sizeData = cmdResult.stdout as String;
    final size = sizeData.split(' ')[0];
    return (
      size: double.parse(size.trim().replaceAll('\"', '')),
      unit: UniteSize.fromString(sizeData.split(' ')[1]),
    );
  }
}
