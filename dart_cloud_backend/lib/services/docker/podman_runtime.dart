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
  Future<ProcessResult> buildImage({
    required String imageTag,
    required String dockerfilePath,
    required String contextDir,
    Duration timeout = const Duration(minutes: 5),
    void Function(String)? onStdout,
    void Function(String)? onStderr,
  }) async {
    final process = await Process.start(
      _executable,
      ['build', '-t', imageTag, '-f', dockerfilePath, contextDir],
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
      '--network',
      network,
    ];

    // Add volume mounts
    for (final mount in volumeMounts) {
      args.addAll(['-v', mount]);
    }

    // Add environment variables
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
}
