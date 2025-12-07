import 'package:dart_cloud_backend/configuration/config.dart';
import 'package:dart_cloud_backend/services/docker/container_runtime.dart';
import 'package:dart_cloud_backend/services/docker/docker_service.dart';
import 'package:dart_cloud_backend/services/docker/dockerfile_generator.dart';
import 'package:test/test.dart';

import 'mock_container_runtime.dart';
import 'mock_file_system.dart';

void main() {
  group('DockerService', () {
    late MockContainerRuntime mockRuntime;
    late MockFileSystem mockFs;
    late DockerService service;

    setUp(() {
      Config.loadFake();
      mockRuntime = MockContainerRuntime();
      mockFs = MockFileSystem();
      service = DockerService(
        runtime: mockRuntime,
        fileSystem: mockFs,
      );
    });

    group('buildImage', () {
      test('generates Dockerfile and builds image successfully', () async {
        // Arrange
        mockRuntime.buildImageResult = const ProcessResult(
          exitCode: 0,
          stdout: 'Build successful',
          stderr: '',
        );

        // Act
        final imageTag = await service.buildImage('test-func', '/path/to/func');

        // Assert
        expect(imageTag, contains('dart-function-test-func'));
        expect(mockRuntime.wasCalled('buildImage'), isTrue);
        expect(mockFs.wasFileWritten('/path/to/func/Dockerfile'), isTrue);

        // Verify Dockerfile content
        final dockerfile = mockFs.getFileContent('/path/to/func/Dockerfile');
        expect(dockerfile, contains('FROM dart:stable'));
        expect(dockerfile, contains('dart compile exe'));
        expect(dockerfile, contains('FROM alpine'));
      });

      test('throws exception on build failure', () async {
        // Arrange
        mockRuntime.buildImageResult = const ProcessResult(
          exitCode: 1,
          stdout: '',
          stderr: 'Build failed: missing dependency',
        );

        // Act & Assert
        expect(
          () => service.buildImage('test-func', '/path/to/func'),
          throwsException,
        );
      });

      test('cleans up intermediate build image after successful build', () async {
        // Arrange
        mockRuntime.buildImageResult = const ProcessResult(
          exitCode: 0,
          stdout: 'Build successful',
          stderr: '',
        );

        // Act
        await service.buildImage('test-func', '/path/to/func');

        // Assert - removeImage should be called for intermediate image
        final removeImageCalls = mockRuntime.getCallsTo('removeImage');
        expect(removeImageCalls.length, greaterThanOrEqualTo(1));
        expect(
          removeImageCalls.first.arguments['imageTag'],
          contains('dart-function-build-test-func'),
        );
      });
    });

    group('runContainer', () {
      test('runs container and returns successful result', () async {
        // Arrange
        mockRuntime.runContainerResult = const ProcessResult(
          exitCode: 0,
          stdout: '{"message": "Hello, World!"}',
          stderr: '',
        );

        // Act
        final result = await service.runContainer(
          imageTag: 'test-image:latest',
          input: {'body': 'test'},
          timeoutMs: 5000,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.error, isNull);
        expect(result.result, isA<Map>());
        expect(result.result['message'], equals('Hello, World!'));
      });

      test('returns error on container failure', () async {
        // Arrange
        mockRuntime.runContainerResult = const ProcessResult(
          exitCode: 1,
          stdout: '',
          stderr: 'Container crashed',
        );

        // Act
        final result = await service.runContainer(
          imageTag: 'test-image:latest',
          input: {'body': 'test'},
          timeoutMs: 5000,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('exited with code 1'));
      });

      test('returns timeout error when container times out', () async {
        // Arrange
        mockRuntime.runContainerResult = const ProcessResult(
          exitCode: -1, // Timeout exit code
          stdout: '',
          stderr: '',
        );

        // Act
        final result = await service.runContainer(
          imageTag: 'test-image:latest',
          input: {'body': 'test'},
          timeoutMs: 5000,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('timed out'));
      });

      test('creates and cleans up request file', () async {
        // Arrange
        mockRuntime.runContainerResult = const ProcessResult(
          exitCode: 0,
          stdout: '{"result": "ok"}',
          stderr: '',
        );

        // Act
        await service.runContainer(
          imageTag: 'test-image:latest',
          input: {'body': 'test data'},
          timeoutMs: 5000,
        );

        // Assert - temp directory should be created and cleaned up
        expect(mockFs.createdTempDirs.length, equals(1));
        expect(mockFs.deletedDirs.length, equals(1));
      });

      test('passes correct environment variables', () async {
        // Arrange
        mockRuntime.runContainerResult = const ProcessResult(
          exitCode: 0,
          stdout: '{}',
          stderr: '',
        );

        // Act
        await service.runContainer(
          imageTag: 'test-image:latest',
          input: {'body': 'test'},
          timeoutMs: 10000,
        );

        // Assert
        final runCalls = mockRuntime.getCallsTo('runContainer');
        expect(runCalls.length, equals(1));

        final environment =
            runCalls.first.arguments['environment'] as Map<String, String>;
        expect(environment['DART_CLOUD_RESTRICTED'], equals('true'));
        expect(environment['FUNCTION_TIMEOUT_MS'], equals('10000'));
      });
    });

    group('removeImage', () {
      test('removes image successfully', () async {
        // Act
        await service.removeImage('test-image:latest');

        // Assert
        expect(mockRuntime.wasCalled('removeImage'), isTrue);
        final calls = mockRuntime.getCallsTo('removeImage');
        expect(calls.first.arguments['imageTag'], equals('test-image:latest'));
      });
    });

    group('isRuntimeAvailable', () {
      test('returns true when runtime is available', () async {
        // Arrange
        mockRuntime.available = true;

        // Act
        final result = await service.isRuntimeAvailable();

        // Assert
        expect(result, isTrue);
      });

      test('returns false when runtime is not available', () async {
        // Arrange
        mockRuntime.available = false;

        // Act
        final result = await service.isRuntimeAvailable();

        // Assert
        expect(result, isFalse);
      });
    });
  });

  group('DockerfileGenerator', () {
    test('generates multi-stage Dockerfile', () {
      // Arrange
      const generator = DockerfileGenerator();

      // Act
      final dockerfile = generator.generate(buildStageTag: 'test-build');

      // Assert
      expect(dockerfile, contains('FROM dart:stable AS test-build'));
      expect(dockerfile, contains('dart compile exe main.dart'));
      expect(dockerfile, contains('FROM alpine'));
      expect(dockerfile, contains('COPY --from=test-build'));
      expect(dockerfile, contains('ENTRYPOINT'));
    });

    test('generates development Dockerfile', () {
      // Arrange
      const generator = DockerfileGenerator();

      // Act
      final dockerfile = generator.generateDevelopment();

      // Assert
      expect(dockerfile, contains('FROM dart:stable'));
      expect(dockerfile, contains('dart pub get'));
      expect(dockerfile, contains('CMD ["dart", "run"'));
      expect(dockerfile, isNot(contains('dart compile exe')));
    });

    test('uses custom base images', () {
      // Arrange
      const generator = DockerfileGenerator(
        buildImage: 'dart:3.2',
        runtimeImage: 'scratch',
      );

      // Act
      final dockerfile = generator.generate(buildStageTag: 'build');

      // Assert
      expect(dockerfile, contains('FROM dart:3.2 AS build'));
      expect(dockerfile, contains('FROM scratch'));
    });
  });
}
