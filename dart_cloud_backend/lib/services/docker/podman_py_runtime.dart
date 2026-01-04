import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_cloud_backend/handlers/logs_utils/log_utils.dart';
import 'package:dart_cloud_backend/services/docker/container_data.dart';
import 'container_runtime.dart';

/// Podman implementation using Python client
///
/// Uses the Python Podman client (podman_client.py) instead of direct shell commands.
/// Supports environment-based socket configuration for different deployment environments.
class PodmanPyRuntime implements ContainerRuntime {
  final String _pythonExecutable;
  final String _pythonClientPath;
  final String _socketPath;

  /// Create a PodmanPyRuntime instance
  ///
  /// [pythonExecutable] defaults to 'python3' but can be overridden
  /// [pythonClientPath] path to the podman_client.py script
  /// [socketPath] path to Podman socket, can be environment-based
  PodmanPyRuntime({
    String pythonExecutable = 'python3',
    String? pythonClientPath,
    String? socketPath,
  }) : _pythonExecutable = pythonExecutable,
       _pythonClientPath = pythonClientPath ?? _getDefaultPythonClientPath(),
       _socketPath = socketPath ?? _getSocketPathFromEnvironment();

  /// Get default Python client path relative to project root
  static String _getDefaultPythonClientPath() {
    return 'podman_client.py';
  }

  /// Get socket path from dart-define
  ///
  /// Read from --dart-define=PODMAN_SOCKET_PATH=/path/to/socket
  /// Falls back to default if not defined
  static String _getSocketPathFromEnvironment() {
    const socketPath = String.fromEnvironment(
      'PODMAN_SOCKET_PATH',
      defaultValue: '/run/podman/podman.sock',
    );
    return socketPath;
  }

  @override
  String get name => 'podman-py';

  /// Execute Python client command and parse JSON response
  Future<Map<String, dynamic>> _executePythonCommand(
    List<String> args, {
    Duration? timeout,
  }) async {
    final fullArgs = [
      _pythonClientPath,
      '--socket',
      _socketPath,
      ...args,
    ];

    final process = await Process.start(_pythonExecutable, fullArgs);

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    process.stdout.transform(utf8.decoder).listen((data) {
      stdoutBuffer.write(data);
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      stderrBuffer.write(data);
    });

    final exitCode = timeout != null
        ? await process.exitCode.timeout(
            timeout,
            onTimeout: () {
              process.kill(ProcessSignal.sigkill);
              return -1;
            },
          )
        : await process.exitCode;

    final stdout = stdoutBuffer.toString();
    final stderr = stderrBuffer.toString();

    if (exitCode != 0) {
      // Try to parse error JSON
      try {
        final errorJson = jsonDecode(stderr.isNotEmpty ? stderr : stdout);
        return {
          'success': false,
          'error': errorJson['error'] ?? 'Unknown error',
          'exit_code': exitCode,
        };
      } catch (exception, trace) {
        LogsUtils.log('containerRuntime', 'error', {
          'error': 'Command failed with exit code $exitCode',
          'trace': trace.toString(),
          'exception': exception.toString(),
          'stderr': stderr,
          'stdout': stdout,
        });
        return {
          'success': false,
          'error': stderr.isNotEmpty ? stderr : 'Command failed with exit code $exitCode',
          'exit_code': exitCode,
        };
      }
    }

    // Parse success JSON
    try {
      if (stdout.isNotEmpty) {
        final result = jsonDecode(stdout);
        return result as Map<String, dynamic>;
      }
      print(stdout);
      return {
        'success': true,
        'data': stdout,
        'exit_code': exitCode,
      };
    } catch (e, trace) {
      LogsUtils.logError('containerRuntime', e.toString(), trace.toString());
      return {
        'success': false,
        'error': 'Failed to parse JSON response: $e',
        'exit_code': -1,
      };
    }
  }

  @override
  Future<Architecture> getArch({String format = '{{.Host.Arch}}'}) async {
    final result = await _executePythonCommand(['info', '--format', format]);

    if (result['success'] == true) {
      // Use platform detection from info
      final platform = result['data'] as String?;
      if (platform == 'arm64') return Architecture.arm64;
      return Architecture.x64;
    }

    // Fallback: detect from system
    final archResult = await Process.run('uname', ['-m']);
    final arch = archResult.stdout.toString().trim();
    if (arch == 'x86_64' || arch == 'amd64') return Architecture.x64;
    if (arch == 'aarch64' || arch == 'arm64') return Architecture.arm64;
    throw Exception('Unsupported architecture: $arch');
  }

  @override
  Future<ArchitecturePlatform> getArchPlatform() async {
    final result = await _executePythonCommand([
      'info',
      '--format',
      '{{.Version.OsArch}}',
    ]);

    if (result['success'] == true) {
      final arch = result['data'] as String?;
      return ArchitecturePlatform.values.firstWhere(
        (element) => element.buildPlatform == arch,
      );
    }
    throw Exception('Unsupported architecture: ${result['error']}');
  }

  @override
  Future<String?> getImagePlatform(String imageTag) async {
    final result = await _executePythonCommand([
      'inspect',
      imageTag,
      '--format',
      '{{.Os}}/{{.Architecture}}',
    ]);

    if (result['success'] == true) {
      return result['data'] as String?;
    }
    return null;
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
        '[PodmanPy] Image $imageTag has platform $currentPlatform, '
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
    final args = [
      'build',
      contextDir,
      '--tag',
      imageTag,
      '--file',
      dockerfilePath,
    ];

    final result = await _executePythonCommand(args, timeout: timeout);

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final logs = data['logs'] as List<dynamic>? ?? [];

      // Call callbacks if provided
      for (final log in logs) {
        onStdout?.call(log.toString());
      }

      return ImageProcessResult(
        exitCode: 0,
        stdout: logs.join('\n'),
        stderr: '',
      );
    } else {
      final error = result['error']?.toString() ?? 'Build failed';
      onStderr?.call(error);

      return ImageProcessResult(
        exitCode: result['exit_code'] as int? ?? 1,
        stdout: '',
        stderr: error,
      );
    }
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
    String? workingDir,
  }) async {
    final args = [
      'run',
      imageTag,
      '--name',
      containerName,
      '--entrypoint',
      '/runner/function',
      '--network',
      network,
      '--memory',
      '$memoryMb$memoryUnit',
      '--memory-swap',
      '50m',
      '--cpus',
      cpus.toString(),
      '--timeout',
      timeout.inSeconds.toString(),
    ];

    // Add volume mounts
    for (final mount in volumeMounts) {
      args.addAll(['--volume', mount]);
    }

    // Add environment variables
    for (final entry in environment.entries) {
      args.addAll(['-e', '${entry.key}=${entry.value}']);
    }

    // Add working directory if specified
    if (workingDir != null) {
      args.addAll(['--workdir', workingDir]);
    }

    print('run container args: $args');
    final result = await _executePythonCommand(args, timeout: timeout);
    print('run container result: ${result}');
    if (result['success'] == true &&  result['data'] is String ) {
      final data = json.decode(result['data']) as Map<String, dynamic>;

      return ContainerProcessResult(
        exitCode: 0,
        stdout: {
          'container_id': data['container_id'],
          'name': data['name'],
          'status': data['status'],
        },
        stderr: '',
        containerConfiguration: {
          'memory_usage': memoryMb,
        },
      );
    } else {
      final error = result['error']?.toString() ?? 'Run failed';
      final exitCode = result['exit_code'] as int? ?? 1;

      return ContainerProcessResult(
        exitCode: exitCode,
        stdout: {},
        stderr: error,
        isTimeout: exitCode == -1,
        containerConfiguration: {
          'memory_usage': memoryMb,
        },
      );
    }
  }

  @override
  Future<ProcessResult> removeImage(
    String imageTag, {
    bool force = true,
  }) async {
    final args = ['rmi', imageTag];
    if (force) {
      args.add('--force');
    }

    final result = await _executePythonCommand(args);

    if (result['success'] == true) {
      return ImageProcessResult(
        exitCode: 0,
        stdout: 'Image removed successfully',
        stderr: '',
      );
    } else {
      return ImageProcessResult(
        exitCode: result['exit_code'] as int? ?? 1,
        stdout: '',
        stderr: result['error']?.toString() ?? 'Remove failed',
      );
    }
  }

  @override
  Future<ProcessResult> killContainer(String containerName) async {
    final result = await _executePythonCommand(['kill', containerName]);

    if (result['success'] == true) {
      return ImageProcessResult(
        exitCode: 0,
        stdout: 'Container killed successfully',
        stderr: '',
      );
    } else {
      return ImageProcessResult(
        exitCode: result['exit_code'] as int? ?? 1,
        stdout: '',
        stderr: result['error']?.toString() ?? 'Kill failed',
      );
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await _executePythonCommand(['ping']);
      if (result['success'] != true) {
        print(result['error']);
        return false;
      }
      return true;
    } catch (e, trace) {
      print(e);
      print(trace);
      return false;
    }
  }

  @override
  Future<String?> getVersion() async {
    try {
      final result = await _executePythonCommand(['version']);
      if (result['success'] == true) {
        return result['data'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> imageExists(String imageTag) async {
    final result = await _executePythonCommand(['exists', imageTag]);
    print('check $imageTag image exists: ${result['data']}');
    if (result['success'] == true && result['data'] == true) {
      return true;
    }
    return false;
  }

  @override
  Future<void> prune() async {
    await _executePythonCommand(['prune']);
  }

  @override
  Future<ImageSizeData> getImageSize(String imageTag) async {
    final result = await _executePythonCommand([
      'inspect',
      imageTag,
      '--format',
      '{{.Size}}',
    ]);

    if (result['success'] == true) {
      final size = int.parse(result['data'] as String);
      final sizeMb = size / (1024 * 1024);
      return (
        size: sizeMb,
        unit: UniteSize.MB,
      );
    }

    return (
      size: 0.0,
      unit: UniteSize.MB,
    );
  }
}
