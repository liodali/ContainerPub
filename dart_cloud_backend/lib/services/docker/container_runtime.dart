import 'dart:async';

/// Result of a process execution
class ProcessResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  bool get isSuccess => exitCode == 0;
}

/// Abstract interface for container runtime operations
///
/// This abstraction allows for:
/// - Easy mocking in tests
/// - Swapping between Docker/Podman/other runtimes
/// - Decoupling business logic from system calls
abstract class ContainerRuntime {
  /// Runtime name (e.g., 'podman', 'docker')
  String get name;

  /// Build a container image from a Dockerfile
  ///
  /// Parameters:
  /// - [imageTag]: Tag for the built image
  /// - [dockerfilePath]: Path to the Dockerfile
  /// - [contextDir]: Build context directory
  /// - [timeout]: Build timeout duration
  /// - [onStdout]: Callback for stdout data
  /// - [onStderr]: Callback for stderr data
  Future<ProcessResult> buildImage({
    required String imageTag,
    required String dockerfilePath,
    required String contextDir,
    Duration timeout = const Duration(minutes: 5),
    void Function(String)? onStdout,
    void Function(String)? onStderr,
  });

  /// Run a container with the specified configuration
  ///
  /// Parameters:
  /// - [imageTag]: Image to run
  /// - [containerName]: Unique name for the container
  /// - [environment]: Environment variables
  /// - [volumeMounts]: Volume mounts (host:container:mode)
  /// - [memoryMb]: Memory limit in MB
  /// - [cpus]: CPU limit
  /// - [network]: Network mode
  /// - [timeout]: Execution timeout
  Future<ProcessResult> runContainer({
    required String imageTag,
    required String containerName,
    Map<String, String> environment = const {},
    List<String> volumeMounts = const [],
    int memoryMb = 128,
    double cpus = 0.5,
    String network = 'none',
    Duration timeout = const Duration(seconds: 30),
  });

  /// Remove a container image
  Future<ProcessResult> removeImage(String imageTag, {bool force = true});

  /// Kill a running container
  Future<ProcessResult> killContainer(String containerName);

  /// Check if the runtime is available
  Future<bool> isAvailable();

  /// Get runtime version
  Future<String?> getVersion();
}

/// Configuration for container execution
class ContainerConfig {
  final String imageTag;
  final String containerName;
  final Map<String, String> environment;
  final List<String> volumeMounts;
  final int memoryMb;
  final double cpus;
  final String network;
  final Duration timeout;

  const ContainerConfig({
    required this.imageTag,
    required this.containerName,
    this.environment = const {},
    this.volumeMounts = const [],
    this.memoryMb = 128,
    this.cpus = 0.5,
    this.network = 'none',
    this.timeout = const Duration(seconds: 30),
  });

  ContainerConfig copyWith({
    String? imageTag,
    String? containerName,
    Map<String, String>? environment,
    List<String>? volumeMounts,
    int? memoryMb,
    double? cpus,
    String? network,
    Duration? timeout,
  }) {
    return ContainerConfig(
      imageTag: imageTag ?? this.imageTag,
      containerName: containerName ?? this.containerName,
      environment: environment ?? this.environment,
      volumeMounts: volumeMounts ?? this.volumeMounts,
      memoryMb: memoryMb ?? this.memoryMb,
      cpus: cpus ?? this.cpus,
      network: network ?? this.network,
      timeout: timeout ?? this.timeout,
    );
  }
}

/// Configuration for image build
class BuildConfig {
  final String imageTag;
  final String dockerfilePath;
  final String contextDir;
  final Duration timeout;

  const BuildConfig({
    required this.imageTag,
    required this.dockerfilePath,
    required this.contextDir,
    this.timeout = const Duration(minutes: 5),
  });
}
