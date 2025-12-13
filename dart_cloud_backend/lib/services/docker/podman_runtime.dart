import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

    return ProcessResult(
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
    int memoryMb = 128,
    double cpus = 0.5,
    String network = 'none',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final args = [
      'run',
      '--rm',
      '--name',
      containerName,
      '--memory',
      '${memoryMb}m',
      '--cpus',
      cpus.toString(),
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

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    process.stdout.transform(utf8.decoder).listen((data) {
      stdoutBuffer.write(data);
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

    return ProcessResult(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
    );
  }

  @override
  Future<ProcessResult> removeImage(String imageTag, {bool force = true}) async {
    final args = ['rmi'];
    if (force) args.add('-f');
    args.add(imageTag);

    final result = await Process.run(_executable, args);
    return ProcessResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }

  @override
  Future<ProcessResult> killContainer(String containerName) async {
    final result = await Process.run(_executable, ['kill', containerName]);
    return ProcessResult(
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
}
