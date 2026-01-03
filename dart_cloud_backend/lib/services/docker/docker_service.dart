import 'dart:convert';
import 'dart:io';

import 'package:dart_cloud_backend/configuration/config.dart';
import 'package:dart_cloud_backend/handlers/logs_utils/log_utils.dart';
import 'package:dart_cloud_backend/utils/commons.dart';
import 'package:sentry/sentry.dart';

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
  static DockerService? _instance;
  static DockerService get instance {
    if (_instance == null) {
      throw StateError('DockerService not initialized');
    }
    return _instance!;
  }

  static void init({
    ContainerRuntime? runtime,
    FileSystem? fileSystem,
    DockerfileGenerator? dockerfileGenerator,
  }) {
    _instance ??= DockerService(
      runtime: runtime,
      fileSystem: fileSystem,
      dockerfileGenerator: dockerfileGenerator,
    );
  }

  /// Private constructor for singleton
  // DockerService._internal()
  //   : _runtime = PodmanRuntime(),
  //     _fileSystem = const RealFileSystem(),
  //     _dockerfileGenerator = const DockerfileGenerator(),
  //     _requestFileManager = const RequestFileManager(RealFileSystem());

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
    _instance ??= DockerService._custom(
      runtime: runtime ?? PodmanRuntime(),
      fileSystem: fileSystem ?? const RealFileSystem(),
      dockerfileGenerator: dockerfileGenerator ?? const DockerfileGenerator(),
    );
    return _instance!;
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
    String functionName,
    String functionDir, {
    String entrypoint = 'bin/main.dart',
  }) async {
    final imageTag = '$functionName-$functionId:latest';
    final buildStageTag = '$functionName-build-$functionId';

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
  /// - [functionUUID]: Function UUID for result storage location
  /// - [version]: Deployment version for result storage location
  ///
  /// Returns: ExecutionResult with success status, result data, and errors
  ///
  /// **Result Handling:**
  /// - Function writes result to /result.json (mounted volume)
  /// - Result file stored at: Config.functionsDir/functionUUID/version/result.json
  /// - stdout/stderr are captured as logs only
  /// - This separates function output from debug logs
  Future<ExecutionResult> runContainer({
    required String imageTag,
    required Map<String, dynamic> input,
    required int timeoutMs,
    required String functionUUID,
    required int version,
  }) async {
    final containerName = 'dart-function-${DateTime.now().millisecondsSinceEpoch}';
    String? tempDirPath;

    try {
      // Create request file for container
      // final requestInfo = await _requestFileManager.createRequestFile(
      //   containerName,
      //   input,
      // );
      // tempDirPath = requestInfo.tempDirPath;
      // // Create logs temporary file for container
      // final logsInfo = await _requestFileManager.createLogsFile(tempDirPath, input);

      // Create result directory at deployment location: functionsDir/functionUUID/version/
      final resultDir = _fileSystem.joinPaths(Config.functionsDir, [
        functionUUID,
        'v$version',
        containerName,
      ]);
      tempDirPath = resultDir;
      // Ensure result directory exists
      await Directory(resultDir).create(recursive: true);
      // Create request.json file (empty, will be written by function)
      final reqFilePath = await _requestFileManager.createRequestFile(resultDir, input);
      // Create result.json file (empty, will be written by function)
      final resultFilePath = _fileSystem.joinPath(resultDir, 'result.json');
      await _fileSystem.writeFile(resultFilePath, '');

      // Create logs.json file (empty, will be written by function logger)
      final logsFilePath = _fileSystem.joinPath(resultDir, 'logs.json');
      await _fileSystem.writeFile(logsFilePath, '');
      // // Create env.json file (empty, will be written by function logger)
      // final envFilePath = _fileSystem.joinPath(resultDir, 'env.json');
      // await _fileSystem.writeFile(envFilePath, '');
      // Prepare environment variables and create .env.config file
      final envConfigPath = await _createEnvConfigFile(
        resultDir,
        _buildEnvironment(timeoutMs),
      );

      // Prepare volume mounts (request.json, .env.config, result.json, and logs.json)
      final volumeMounts = [
        '${reqFilePath.filePath}:/request.json:ro',
        '$envConfigPath:/.env.config:ro',
        '$resultFilePath:/result.json:rw', // Writable for function to write result
        '$logsFilePath:/logs.json:rw', // Writable for function to write logs
      ];

      final imageSize = await _runtime.getImageSize(imageTag);
      // Run the container with env file mounted as volume
      final result = await _runtime.runContainer(
        imageTag: imageTag,
        containerName: containerName,
        volumeMounts: volumeMounts,
        memoryMb: (imageSize.size / 2).toInt(),
        memoryUnit: imageSize.unit.memoryUnit,
        cpus: 0.5,
        network: 'none',
        timeout: Duration(milliseconds: timeoutMs),
      );
      
      // Capture container logs (stdout and stderr) - these are now pure logs
      final containerLogs = <String, dynamic>{
        'stderr': result.stderr,
        'exit_code': result.exitCode,
        'timestamp': DateTime.now().toIso8601String(),
        'memory_usage':
            (result as ContainerProcessResult).containerConfiguration['memory_usage'],
      };
      containerLogs.addAll(result.stdout);

      // Read function logs from logs.json (written by CloudLogger)
      Map<String, dynamic>? functionLogs;
      try {
        final logsContent = await _fileSystem.readFile(logsFilePath);
        if (logsContent.isNotEmpty) {
          functionLogs = jsonDecode(logsContent);
        }
        await _fileSystem.deleteFile(logsFilePath);
      } catch (e) {
        // logs.json may be empty or invalid - not critical
        print('Warning: Could not read function logs: $e');
      }

      // Add function logs to container logs
      if (functionLogs != null) {
        containerLogs['function_logs'] = functionLogs;
      }

      // Handle timeout
      if (result.exitCode == -1) {
        LogsUtils.logError(
          'runContainer',
          'Function Error',
          containerLogs.toString(),
        );
        return ExecutionResult(
          success: false,
          error: 'Function execution timed out (${timeoutMs}ms)',
          logs: containerLogs,
        );
      }
      print('Container result: ${result.stdout}');
      print('Container error: ${result.stderr}');
      // Read result from result.json (written by function)
      Map<String, dynamic> parsedResult = Map.from(
        jsonDecode(result.stdout['stdout']),
      );
      try {
        final resultContent = await _fileSystem.readFile(resultFilePath);
        if (resultContent.isNotEmpty) {
          parsedResult = jsonDecode(resultContent);
        }
        await _fileSystem.deleteFile(resultFilePath);
      } catch (e, stackTrace) {
        LogsUtils.logError(
          'runContainer',
          e.toString(),
          stackTrace.toString(),
        );
        Sentry.captureException(e, stackTrace: stackTrace);
        // If result.json is empty or invalid, check if function failed
        if (!result.isSuccess) {
          return ExecutionResult(
            success: false,
            error: 'Function exited with code ${result.exitCode}: ${result.stderr}',
            logs: containerLogs,
          );
        }
        // Function succeeded but no result file - unexpected
        return ExecutionResult(
          success: false,
          error: 'Function completed but no result found',
          logs: containerLogs,
        );
      }

      // Handle non-zero exit code (function may have written error to result.json)
      if (!result.isSuccess) {
        return ExecutionResult(
          success: false,
          error: 'Function exited with code ${result.exitCode}',
          result: parsedResult,
          logs: containerLogs,
        );
      }

      return ExecutionResult(
        success: true,
        result: parsedResult['body'],
        logs: containerLogs,
      );
    } catch (e, trace) {
      LogsUtils.log(
        LogLevels.error.name,
        'runContainer',
        {
          'trace': trace.toString(),
          'error': e.toString(),
        },
      );
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
  /// Returns a map of environment variables to be written to .env.config
  Map<String, String> _buildEnvironment(int timeoutMs) {
    final environment = {
      'DART_CLOUD_RESTRICTED': 'true',
      'FUNCTION_TIMEOUT_MS': timeoutMs.toString(),
      'FUNCTION_MAX_MEMORY_MB': Config.functionMaxMemoryMb.toString(),
    };

    return environment;
  }

  /// Create .env.config file with environment variables
  /// Returns the path to the created file
  Future<String> _createEnvConfigFile(
    String tempDirPath,
    Map<String, String> environment,
  ) async {
    final envConfigPath = _fileSystem.joinPath(tempDirPath, '.env.config');
    final envContent = environment.entries.map((e) => '${e.key}=${e.value}').join('\n');
    await _fileSystem.writeFile(envConfigPath, envContent);
    return envConfigPath;
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
    String functionName,
    String functionDir,
  ) => _instance!.buildImage(
    functionId,
    functionName,
    functionDir,
  );

  /// Static method to build image with custom entrypoint (delegates to singleton)
  ///
  /// Parameters:
  /// - [functionId]: Unique identifier for the function
  /// - [functionName]: Name of the function
  /// - [functionDir]: Path to directory containing function code
  /// - [entrypoint]: Path to main.dart relative to function dir (e.g., 'bin/main.dart')
  static Future<String> buildImageWithEntrypointStatic(
    String functionId,
    String functionName,
    String functionDir,
    String entrypoint,
  ) => instance.buildImage(
    functionId,
    functionName,
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
    required String functionUUID,
    required int version,
  }) async {
    // Check if image exists before running
    final imageExists = await instance.isImageExist(imageTag);
    if (!imageExists) {
      throw Exception('Container image does not exist: $imageTag');
    }

    final result = await instance.runContainer(
      imageTag: imageTag,
      input: input,
      timeoutMs: timeoutMs,
      functionUUID: functionUUID,
      version: version,
    );
    return result.toJson();
  }

  static Future<bool> isContainerImageExist(String imageTag) =>
      instance.isImageExist(imageTag);

  Future<bool> isImageExist(String imageTag) => _runtime.imageExists(imageTag);

  static Future<void> pruneIntermediateImages() => instance.prune();
  Future<void> prune() => _runtime.prune();

  /// Static method to remove image (delegates to singleton)
  ///
  /// @deprecated Use instance method instead: `DockerService().removeImage(...)`
  static Future<void> removeImageStatic(String imageTag) =>
      instance.removeImage(imageTag);

  /// Static method to check runtime availability (delegates to singleton)
  ///
  /// @deprecated Use instance method instead: `DockerService().isRuntimeAvailable()`
  static Future<bool> isPodmanAvailable() => instance.isRuntimeAvailable();

  /// @deprecated Use isPodmanAvailable instead
  @Deprecated('Use isPodmanAvailable instead')
  static Future<bool> isDockerAvailable() => isPodmanAvailable();
}
