import 'dart:convert';

import 'package:dart_cloud_backend/configuration/config.dart';

import 'container_runtime.dart';
import 'dockerfile_generator.dart';
import 'file_system.dart';
import 'podman_runtime.dart';

/// Result of a function execution
class ExecutionResult {
  final bool success;
  final String? error;
  final dynamic result;
  final Map<String, dynamic>? logs;

  const ExecutionResult({
    required this.success,
    this.error,
    this.result,
    this.logs,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'error': error,
    'result': result,
    'logs': logs,
  };
}

/// Service for managing containers for function execution
///
/// This service is designed to be modular and testable:
/// - [ContainerRuntime] abstraction for container operations
/// - [FileSystem] abstraction for file operations
/// - [DockerfileGenerator] for Dockerfile creation
///
/// **Usage:**
/// ```dart
/// // Production
/// final service = DockerService();
///
/// // Testing with mocks
/// final service = DockerService(
///   runtime: MockContainerRuntime(),
///   fileSystem: MockFileSystem(),
/// );
/// ```
class DockerService {
  final ContainerRuntime _runtime;
  final FileSystem _fileSystem;
  final DockerfileGenerator _dockerfileGenerator;
  final RequestFileManager _requestFileManager;

  /// Default singleton instance for static method access
  static final DockerService _instance = DockerService._internal();

  /// Private constructor for singleton
  DockerService._internal()
    : _runtime = PodmanRuntime(),
      _fileSystem = const RealFileSystem(),
      _dockerfileGenerator = const DockerfileGenerator(),
      _requestFileManager = const RequestFileManager(RealFileSystem());

  /// Create a DockerService instance
  ///
  /// All dependencies can be injected for testing:
  /// - [runtime]: Container runtime (defaults to PodmanRuntime)
  /// - [fileSystem]: File system operations (defaults to RealFileSystem)
  /// - [dockerfileGenerator]: Dockerfile generator (defaults to DockerfileGenerator)
  factory DockerService({
    ContainerRuntime? runtime,
    FileSystem? fileSystem,
    DockerfileGenerator? dockerfileGenerator,
  }) {
    if (runtime == null && fileSystem == null && dockerfileGenerator == null) {
      return _instance;
    }
    return DockerService._custom(
      runtime: runtime ?? PodmanRuntime(),
      fileSystem: fileSystem ?? const RealFileSystem(),
      dockerfileGenerator: dockerfileGenerator ?? const DockerfileGenerator(),
    );
  }

  /// Custom constructor for dependency injection
  DockerService._custom({
    required ContainerRuntime runtime,
    required FileSystem fileSystem,
    required DockerfileGenerator dockerfileGenerator,
  }) : _runtime = runtime,
       _fileSystem = fileSystem,
       _dockerfileGenerator = dockerfileGenerator,
       _requestFileManager = RequestFileManager(fileSystem);

  /// Build a container image from a function directory
  ///
  /// This method:
  /// 1. Generates a Dockerfile in the function directory
  /// 2. Builds the image using the container runtime
  /// 3. Cleans up intermediate build images
  /// 4. Returns the image tag on success
  ///
  /// Parameters:
  /// - [functionId]: Unique identifier for the function
  /// - [functionDir]: Path to directory containing function code
  ///
  /// Returns: Image tag (e.g., 'localhost:5000/dart-function-id:latest')
  ///
  /// Throws: Exception if build fails or times out
  Future<String> buildImage(
    String functionId,
    String functionDir, {
    String entrypoint = 'bin/main.dart',
  }) async {
    final imageTag = 'dart-function-$functionId:latest';
    final buildStageTag = 'dart-function-build-$functionId';

    // Check base image platform compatibility before building
    // This ensures dart:stable (or configured buildImage) matches host architecture
    final targetPlatform = await _runtime.getArchPlatform();
    await _runtime.ensureImagePlatformCompatibility(
      _dockerfileGenerator.buildImage,
      targetPlatform,
    );

    // Generate and write Dockerfile with the correct entrypoint
    final dockerfilePath = _fileSystem.joinPath(functionDir, 'Dockerfile');
    final dockerfileContent = _dockerfileGenerator.generate(
      buildStageTag: buildStageTag,
      entrypoint: entrypoint,
      targetPlatform: targetPlatform,
    );
    await _fileSystem.writeFile(dockerfilePath, dockerfileContent);

    // Build the image
    final result = await _runtime.buildImage(
      imageTag: imageTag,
      dockerfilePath: dockerfilePath,
      contextDir: functionDir,
      onStdout: (data) => print('[${_runtime.name} Build] $data'),
      onStderr: (data) => print('[${_runtime.name} Build Error] $data'),
    );

    if (!result.isSuccess) {
      throw Exception('${_runtime.name} build failed: ${result.stderr}');
    }

    // Clean up intermediate build image
    await _removeIntermediateImage(buildStageTag);

    return imageTag;
  }

  /// Run a container with the function and return the output
  ///
  /// Parameters:
  /// - [imageTag]: Container image to run
  /// - [input]: Function input data (body, query, headers)
  /// - [timeoutMs]: Maximum execution time in milliseconds
  ///
  /// Returns: ExecutionResult with success status, result data, and errors
  Future<ExecutionResult> runContainer({
    required String imageTag,
    required Map<String, dynamic> input,
    required int timeoutMs,
  }) async {
    final containerName = 'dart-function-${DateTime.now().millisecondsSinceEpoch}';
    String? tempDirPath;

    try {
      // Create request file
      final requestInfo = await _requestFileManager.createRequestFile(input);
      tempDirPath = requestInfo.tempDirPath;

      // Prepare environment variables
      final environment = _buildEnvironment(timeoutMs);

      // Prepare volume mounts
      final volumeMounts = ['${requestInfo.filePath}:/request.json:ro'];

      // Run the container
      final result = await _runtime.runContainer(
        imageTag: imageTag,
        containerName: containerName,
        environment: environment,
        volumeMounts: volumeMounts,
        memoryMb: Config.functionMaxMemoryMb,
        cpus: 0.5,
        network: 'none',
        timeout: Duration(milliseconds: timeoutMs),
      );

      // Capture container logs (stdout and stderr)
      final containerLogs = {
        'stdout': result.stdout,
        'stderr': result.stderr,
        'exit_code': result.exitCode,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Handle timeout
      if (result.exitCode == -1) {
        return ExecutionResult(
          success: false,
          error: 'Function execution timed out (${timeoutMs}ms)',
          logs: containerLogs,
        );
      }

      // Handle non-zero exit code
      if (!result.isSuccess) {
        return ExecutionResult(
          success: false,
          error: 'Function exited with code ${result.exitCode}: ${result.stderr}',
          logs: containerLogs,
        );
      }

      // Parse output
      final output = result.stdout.trim();
      dynamic parsedResult;
      try {
        parsedResult = jsonDecode(output);
      } catch (e) {
        parsedResult = output;
      }

      return ExecutionResult(success: true, result: parsedResult, logs: containerLogs);
    } catch (e) {
      return ExecutionResult(
        success: false,
        error: 'Container execution error: $e',
      );
    } finally {
      // Clean up temp directory
      if (tempDirPath != null) {
        await _requestFileManager.cleanup(tempDirPath);
      }
    }
  }

  /// Remove a container image
  Future<void> removeImage(String imageTag) async {
    try {
      await _runtime.removeImage(imageTag);
    } catch (e) {
      print('Failed to remove image $imageTag: $e');
    }
  }

  /// Check if the container runtime is available
  Future<bool> isRuntimeAvailable() async {
    return _runtime.isAvailable();
  }

  /// Get the container runtime version
  Future<String?> getRuntimeVersion() async {
    return _runtime.getVersion();
  }

  /// Build environment variables for container execution
  Map<String, String> _buildEnvironment(int timeoutMs) {
    final environment = {
      'DART_CLOUD_RESTRICTED': 'true',
      'FUNCTION_TIMEOUT_MS': timeoutMs.toString(),
      'FUNCTION_MAX_MEMORY_MB': Config.functionMaxMemoryMb.toString(),
    };

    if (Config.functionDatabaseUrl != null) {
      environment['DATABASE_URL'] = Config.functionDatabaseUrl!;
      environment['DB_MAX_CONNECTIONS'] = Config.functionDatabaseMaxConnections
          .toString();
      environment['DB_TIMEOUT_MS'] = Config.functionDatabaseConnectionTimeoutMs
          .toString();
    }

    return environment;
  }

  /// Remove intermediate build image
  Future<void> _removeIntermediateImage(String buildStageTag) async {
    try {
      await _runtime.removeImage(buildStageTag);
      print('[${_runtime.name}] Removed intermediate build image: $buildStageTag');
    } catch (e) {
      print('[${_runtime.name}] Failed to remove intermediate image $buildStageTag: $e');
    }
  }

  // ============================================
  // Static methods for backward compatibility
  // ============================================

  /// Static method to build image (delegates to singleton)
  ///
  /// @deprecated Use instance method instead: `DockerService().buildImage(...)`
  static Future<String> buildImageStatic(
    String functionId,
    String functionDir,
  ) => _instance.buildImage(functionId, functionDir);

  /// Static method to build image with custom entrypoint (delegates to singleton)
  ///
  /// Parameters:
  /// - [functionId]: Unique identifier for the function
  /// - [functionDir]: Path to directory containing function code
  /// - [entrypoint]: Path to main.dart relative to function dir (e.g., 'bin/main.dart')
  static Future<String> buildImageWithEntrypointStatic(
    String functionId,
    String functionDir,
    String entrypoint,
  ) => _instance.buildImage(
    functionId,
    functionDir,
    entrypoint: entrypoint,
  );

  /// Static method to run container (delegates to singleton)
  /// Returns Map for backward compatibility
  ///
  /// @deprecated Use instance method instead: `DockerService().runContainer(...)`
  static Future<Map<String, dynamic>> runContainerStatic({
    required String imageTag,
    required Map<String, dynamic> input,
    required int timeoutMs,
  }) async {
    final result = await _instance.runContainer(
      imageTag: imageTag,
      input: input,
      timeoutMs: timeoutMs,
    );
    return result.toJson();
  }

  /// Static method to remove image (delegates to singleton)
  ///
  /// @deprecated Use instance method instead: `DockerService().removeImage(...)`
  static Future<void> removeImageStatic(String imageTag) =>
      _instance.removeImage(imageTag);

  /// Static method to check runtime availability (delegates to singleton)
  ///
  /// @deprecated Use instance method instead: `DockerService().isRuntimeAvailable()`
  static Future<bool> isPodmanAvailable() => _instance.isRuntimeAvailable();

  /// @deprecated Use isPodmanAvailable instead
  @Deprecated('Use isPodmanAvailable instead')
  static Future<bool> isDockerAvailable() => isPodmanAvailable();
}
