/// Docker/Podman container management module
///
/// This module provides a modular, testable architecture for container operations:
///
/// **Core Components:**
/// - [DockerService] - Main service for building and running containers
/// - [ContainerRuntime] - Abstract interface for container runtimes
/// - [PodmanRuntime] - Podman implementation of ContainerRuntime
/// - [DockerfileGenerator] - Generates optimized multi-stage Dockerfiles
/// - [FileSystem] - Abstract interface for file operations
///
/// **Usage:**
/// ```dart
/// import 'package:dart_cloud_backend/services/docker/docker.dart';
///
/// // Production usage
/// final service = DockerService();
/// final imageTag = await service.buildImage('my-function', '/path/to/function');
/// final result = await service.runContainer(
///   imageTag: imageTag,
///   input: {'body': 'hello'},
///   timeoutMs: 30000,
/// );
///
/// // Testing with mocks
/// final service = DockerService(
///   runtime: MockContainerRuntime(),
///   fileSystem: MockFileSystem(),
/// );
/// ```
// 
library;

export 'container_runtime.dart';
export 'docker_service.dart';
export 'dockerfile_generator.dart';
export 'file_system.dart';
export 'podman_runtime.dart';
