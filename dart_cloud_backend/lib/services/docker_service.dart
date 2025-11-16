import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:dart_cloud_backend/config/config.dart';

/// Service for managing Podman containers for function execution
///
/// This service uses Podman as the container runtime instead of Docker.
/// Podman is a daemonless container engine that provides a Docker-compatible
/// CLI, making it a drop-in replacement for Docker with better security:
///
/// **Why Podman?**
/// - Daemonless architecture (no root daemon)
/// - Rootless containers by default (better security)
/// - Docker-compatible CLI (same commands work)
/// - OCI-compliant (works with standard container images)
/// - Better resource isolation
/// - No single point of failure
///
/// **Compatibility:**
/// Podman commands are identical to Docker:
/// - `podman build` = `docker build`
/// - `podman run` = `docker run`
/// - `podman rmi` = `docker rmi`
///
/// Simply replace 'docker' with 'podman' in all commands.
class DockerService {
  // Container runtime command (podman instead of docker)
  static const String _containerRuntime = 'podman';

  /// Build a container image from a function directory using Podman
  ///
  /// This method:
  /// 1. Generates a Dockerfile in the function directory
  /// 2. Builds the image using Podman
  /// 3. Tags the image with function ID and version
  /// 4. Returns the image tag on success
  ///
  /// Podman builds are rootless by default, providing better security
  /// than Docker which requires root daemon access.
  ///
  /// Parameters:
  /// - [functionId]: Unique identifier for the function (includes version)
  /// - [functionDir]: Path to directory containing function code
  ///
  /// Returns: Image tag (e.g., 'localhost:5000/dart-function-id-v1:latest')
  ///
  /// Throws: Exception if build fails or times out (5 minute limit)
  static Future<String> buildImage(String functionId, String functionDir) async {
    final imageTag = '${Config.dockerRegistry}/dart-function-$functionId:latest';

    // Create Dockerfile in function directory
    final dockerfile = File(path.join(functionDir, 'Dockerfile'));
    await dockerfile.writeAsString(_generateDockerfile());

    // Build the container image using Podman
    // Podman build is identical to docker build but runs rootless
    final buildProcess = await Process.start(
      _containerRuntime, // 'podman' instead of 'docker'
      [
        'build',
        '-t',
        imageTag,
        '-f',
        dockerfile.path,
        functionDir,
      ],
    );

    final stdout = <String>[];
    final stderr = <String>[];

    buildProcess.stdout.transform(utf8.decoder).listen((data) {
      stdout.add(data);
      print('[Podman Build] $data');
    });

    buildProcess.stderr.transform(utf8.decoder).listen((data) {
      stderr.add(data);
      print('[Podman Build Error] $data');
    });

    // Wait for build to complete with 5 minute timeout
    final exitCode = await buildProcess.exitCode.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        buildProcess.kill(ProcessSignal.sigkill);
        throw Exception('Podman build timed out after 5 minutes');
      },
    );

    if (exitCode != 0) {
      throw Exception('Podman build failed: ${stderr.join()}');
    }

    return imageTag;
  }

  /// Run a Podman container with the function and return the output
  ///
  /// This method executes a function in an isolated Podman container with:
  /// - Memory limits (default: 128MB)
  /// - CPU limits (0.5 cores)
  /// - Network isolation (no network access by default)
  /// - Automatic cleanup (--rm flag)
  /// - Execution timeout
  ///
  /// **Podman Security Benefits:**
  /// - Runs rootless (no root daemon required)
  /// - Better process isolation
  /// - User namespace separation
  /// - No privilege escalation
  ///
  /// Parameters:
  /// - [imageTag]: Container image to run
  /// - [input]: Function input data (body, query, headers)
  /// - [timeoutMs]: Maximum execution time in milliseconds
  ///
  /// Returns: Execution result with success status, result data, and errors
  ///
  /// Container is automatically removed after execution (--rm flag)
  static Future<Map<String, dynamic>> runContainer({
    required String imageTag,
    required Map<String, dynamic> input,
    required int timeoutMs,
  }) async {
    final containerName = 'dart-function-${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Create temporary directory for request.json
      final tempDir = Directory.systemTemp.createTempSync('dart_cloud_request_');
      final requestFile = File(path.join(tempDir.path, 'request.json'));

      // Write request data to request.json
      // This file will be mounted into the container for the function to read
      await requestFile.writeAsString(jsonEncode(input));

      // Prepare environment variables
      final environment = {
        'DART_CLOUD_RESTRICTED': 'true',
        'FUNCTION_TIMEOUT_MS': timeoutMs.toString(),
        'FUNCTION_MAX_MEMORY_MB': Config.functionMaxMemoryMb.toString(),
      };

      // Add database connection if configured
      if (Config.functionDatabaseUrl != null) {
        environment['DATABASE_URL'] = Config.functionDatabaseUrl!;
        environment['DB_MAX_CONNECTIONS'] = Config.functionDatabaseMaxConnections
            .toString();
        environment['DB_TIMEOUT_MS'] = Config.functionDatabaseConnectionTimeoutMs
            .toString();
      }

      // Build podman run command with environment variables
      // Podman CLI is identical to Docker CLI
      final podmanArgs = [
        'run',
        '--rm', // Auto-remove container after execution
        '--name', containerName, // Unique container name
        '--memory', '${Config.functionMaxMemoryMb}m', // Memory limit (default: 128MB)
        '--cpus', '0.5', // CPU limit (0.5 cores)
        '--network', 'none', // Network isolation (no external access)
        // Mount request.json into container at /app/request.json
        '-v', '${requestFile.path}:/app/request.json:ro',
      ];

      // Add environment variables to pass input data to container
      environment.forEach((key, value) {
        podmanArgs.addAll(['-e', '$key=$value']);
      });

      // Add image tag as final argument
      podmanArgs.add(imageTag);

      // Run the container using Podman
      final runProcess = await Process.start(_containerRuntime, podmanArgs);

      final stdout = <String>[];
      final stderr = <String>[];

      runProcess.stdout.transform(utf8.decoder).listen((data) {
        stdout.add(data);
      });

      runProcess.stderr.transform(utf8.decoder).listen((data) {
        stderr.add(data);
      });

      // Wait for process with timeout
      // If timeout occurs, kill the container to prevent resource leaks
      final exitCode = await runProcess.exitCode.timeout(
        Duration(milliseconds: timeoutMs),
        onTimeout: () async {
          // Kill the container using Podman
          await Process.run(_containerRuntime, ['kill', containerName]);
          return -1;
        },
      );

      // Clean up temporary directory
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        print('Failed to cleanup temp directory: $e');
      }

      if (exitCode == -1) {
        return {
          'success': false,
          'error': 'Function execution timed out (${timeoutMs}ms)',
          'result': null,
        };
      }

      if (exitCode != 0) {
        return {
          'success': false,
          'error': 'Function exited with code $exitCode: ${stderr.join()}',
          'result': null,
        };
      }

      // Try to parse output as JSON, otherwise return as string
      final output = stdout.join().trim();
      dynamic result;

      try {
        result = jsonDecode(output);
      } catch (e) {
        result = output;
      }

      return {'success': true, 'error': null, 'result': result};
    } catch (e) {
      return {
        'success': false,
        'error': 'Container execution error: $e',
        'result': null,
      };
    }
  }

  /// Remove a container image using Podman
  ///
  /// This is useful for cleanup operations to free disk space.
  /// Images are removed forcefully (-f flag) to handle running containers.
  ///
  /// Parameters:
  /// - [imageTag]: Image tag to remove
  static Future<void> removeImage(String imageTag) async {
    try {
      await Process.run(_containerRuntime, ['rmi', '-f', imageTag]);
    } catch (e) {
      print('Failed to remove image $imageTag: $e');
    }
  }

  /// Check if Podman is available on the system
  ///
  /// This should be called during application startup to verify
  /// that Podman is installed and accessible.
  ///
  /// Returns: true if Podman is available, false otherwise
  static Future<bool> isPodmanAvailable() async {
    try {
      final result = await Process.run(_containerRuntime, ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if Docker is available (deprecated - use isPodmanAvailable)
  ///
  /// Kept for backward compatibility. This now checks for Podman.
  @deprecated
  static Future<bool> isDockerAvailable() async {
    return isPodmanAvailable();
  }

  /// Generate Dockerfile content for Dart functions
  ///
  /// Creates a standard Dockerfile that:
  /// 1. Uses configured base image (e.g., dart:stable)
  /// 2. Sets working directory to /app
  /// 3. Copies function files
  /// 4. Installs Dart dependencies if pubspec.yaml exists
  /// 5. Sets entrypoint to run main.dart
  ///
  /// This Dockerfile works with both Docker and Podman (OCI-compliant).
  ///
  /// Returns: Dockerfile content as string
  static String _generateDockerfile() {
    return '''
# Base image from configuration (e.g., dart:stable)
FROM ${Config.dockerBaseImage}

# Set working directory
WORKDIR /app

# Copy all function files to container
COPY . .

# Install Dart dependencies if pubspec.yaml exists
# This allows functions to use external packages
RUN if [ -f pubspec.yaml ]; then dart pub get; fi

# Set entrypoint to run the function
# Functions should export a main() function in main.dart
CMD ["dart", "run", "main.dart"]
''';
  }
}
