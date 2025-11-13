import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:dart_cloud_backend/config/config.dart';

/// Service for managing Docker containers for function execution
class DockerService {
  /// Build a Docker image from a function directory
  /// Returns the image tag on success, throws exception on failure
  static Future<String> buildImage(String functionId, String functionDir) async {
    final imageTag = '${Config.dockerRegistry}/dart-function-$functionId:latest';

    // Create Dockerfile in function directory
    final dockerfile = File(path.join(functionDir, 'Dockerfile'));
    await dockerfile.writeAsString(_generateDockerfile());

    // Build the Docker image
    final buildProcess = await Process.start(
      'docker',
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
      print('[Docker Build] $data');
    });

    buildProcess.stderr.transform(utf8.decoder).listen((data) {
      stderr.add(data);
      print('[Docker Build Error] $data');
    });

    final exitCode = await buildProcess.exitCode.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        buildProcess.kill(ProcessSignal.sigkill);
        throw Exception('Docker build timed out after 5 minutes');
      },
    );

    if (exitCode != 0) {
      throw Exception('Docker build failed: ${stderr.join()}');
    }

    return imageTag;
  }

  /// Run a Docker container with the function and return the output
  /// Container is automatically removed after execution
  static Future<Map<String, dynamic>> runContainer({
    required String imageTag,
    required Map<String, dynamic> input,
    required int timeoutMs,
  }) async {
    final containerName = 'dart-function-${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Prepare environment variables
      final environment = {
        'FUNCTION_INPUT': jsonEncode(input),
        'HTTP_BODY': jsonEncode(input['body'] ?? {}),
        'HTTP_QUERY': jsonEncode(input['query'] ?? {}),
        'HTTP_METHOD': input['method'] ?? 'POST',
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

      // Build docker run command with environment variables
      final dockerArgs = [
        'run',
        '--rm',
        '--name', containerName,
        '--memory', '${Config.functionMaxMemoryMb}m',
        '--cpus', '0.5',
        '--network', 'none', // Isolate network by default
      ];

      // Add environment variables
      environment.forEach((key, value) {
        dockerArgs.addAll(['-e', '$key=$value']);
      });

      dockerArgs.add(imageTag);

      // Run the container
      final runProcess = await Process.start('docker', dockerArgs);

      final stdout = <String>[];
      final stderr = <String>[];

      runProcess.stdout.transform(utf8.decoder).listen((data) {
        stdout.add(data);
      });

      runProcess.stderr.transform(utf8.decoder).listen((data) {
        stderr.add(data);
      });

      // Wait for process with timeout
      final exitCode = await runProcess.exitCode.timeout(
        Duration(milliseconds: timeoutMs),
        onTimeout: () async {
          // Kill the container
          await Process.run('docker', ['kill', containerName]);
          return -1;
        },
      );

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

  /// Remove a Docker image
  static Future<void> removeImage(String imageTag) async {
    try {
      await Process.run('docker', ['rmi', '-f', imageTag]);
    } catch (e) {
      print('Failed to remove image $imageTag: $e');
    }
  }

  /// Check if Docker is available
  static Future<bool> isDockerAvailable() async {
    try {
      final result = await Process.run('docker', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Generate Dockerfile content for Dart functions
  static String _generateDockerfile() {
    return '''
FROM ${Config.dockerBaseImage}

WORKDIR /app

# Copy function files
COPY . .

# Install dependencies if pubspec.yaml exists
RUN if [ -f pubspec.yaml ]; then dart pub get; fi

# Set entrypoint
CMD ["dart", "run", "main.dart"]
''';
  }
}
