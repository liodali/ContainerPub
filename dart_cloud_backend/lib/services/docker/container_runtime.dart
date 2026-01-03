import 'dart:async';

import 'package:dart_cloud_backend/services/docker/container_data.dart';

/// Result of a process execution
sealed class ProcessResult {
  final int exitCode;
  final String stderr;

  const ProcessResult({
    required this.exitCode,
    required this.stderr,
  });

  bool get isSuccess => exitCode == 0;
}

class ImageProcessResult extends ProcessResult {
  final String stdout;

  const ImageProcessResult({
    required this.stdout,
    required super.exitCode,
    required super.stderr,
  });

  bool get isSuccess => exitCode == 0;
}

class ContainerProcessResult extends ProcessResult {
  final Map<String, dynamic> stdout;
  final Map<String, dynamic> containerConfiguration;
  final bool isTimeout;

  const ContainerProcessResult({
    required this.stdout,
    this.containerConfiguration = const <String, dynamic>{},
    required super.exitCode,
    required super.stderr,
    this.isTimeout = false,
  });

  bool get isSuccess => exitCode == 0;
}

enum Architecture {
  x64,
  arm64,
}

enum ArchitecturePlatform {
  linuxArm64('linux/arm64'),
  linuxX64('linux/amd64')
  ;

  const ArchitecturePlatform(this.buildPlatform);
  final String buildPlatform;
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

  /// Get architecture of the runtime
  Future<Architecture> getArch();

  /// Get architecture platform of the runtime
  Future<ArchitecturePlatform> getArchPlatform();

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
  /// - [environment]: Environment variables (deprecated, use envFilePath)
  /// - [envFilePath]: Path to .env.config file to inject into container
  /// - [volumeMounts]: Volume mounts (host:container:mode)
  /// - [memoryMb]: Memory limit in MB
  /// - [memoryUnit]: Memory unit m/MB/G
  /// - [cpus]: CPU limit
  /// - [network]: Network mode
  /// - [timeout]: Execution timeout
  /// - [workingDir]: Working directory inside the container
  Future<ProcessResult> runContainer({
    required String imageTag,
    required String containerName,
    Map<String, String> environment = const {},
    String? envFilePath,
    List<String> volumeMounts = const [],
    int memoryMb = 128,
    String memoryUnit = 'm',
    double cpus = 0.5,
    String network = 'none',
    Duration timeout = const Duration(seconds: 30),
    String? workingDir,
  });

  /// Remove a container image
  Future<ProcessResult> removeImage(String imageTag, {bool force = true});

  /// Check if image exists
  Future<bool> imageExists(String imageTag);

  /// Get the platform of an existing image
  /// Returns null if image doesn't exist
  Future<String?> getImagePlatform(String imageTag);

  /// Check if image exists and matches the target platform
  /// If image exists with wrong platform, removes it
  Future<void> ensureImagePlatformCompatibility(
    String imageTag,
    ArchitecturePlatform targetPlatform,
  );

  Future<ImageSizeData> getImageSize(String imageTag);

  /// Kill a running container
  Future<ProcessResult> killContainer(String containerName);

  /// remove <unnamed> images which could be the intermediate image
  Future<void> prune();

  /// Check if the runtime is available
  Future<bool> isAvailable();

  /// Get runtime version
  Future<String?> getVersion();
}
