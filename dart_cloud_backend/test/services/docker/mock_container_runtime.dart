import 'package:dart_cloud_backend/services/docker/docker.dart';

/// Mock implementation of ContainerRuntime for testing
///
/// Allows configuring responses for each method to test various scenarios:
/// - Successful builds/runs
/// - Failed builds/runs
/// - Timeouts
/// - Runtime availability
///
/// **Usage:**
/// ```dart
/// final mockRuntime = MockContainerRuntime();
///
/// // Configure successful build
/// mockRuntime.buildImageResult = ProcessResult(
///   exitCode: 0,
///   stdout: 'Build successful',
///   stderr: '',
/// );
///
/// // Configure failed run
/// mockRuntime.runContainerResult = ProcessResult(
///   exitCode: 1,
///   stdout: '',
///   stderr: 'Container failed',
/// );
///
/// // Use in tests
/// final service = DockerService(runtime: mockRuntime);
/// ```
class MockContainerRuntime extends ContainerRuntime {
  /// Result to return from buildImage
  ProcessResult buildImageResult = const ImageProcessResult(
    exitCode: 0,
    stdout: 'Build successful',
    stderr: '',
  );

  /// Result to return from runContainer
  ProcessResult runContainerResult = const ContainerProcessResult(
    exitCode: 0,
    stdout: {"result": "success"},
    stderr: '',
  );

  /// Result to return from removeImage
  ProcessResult removeImageResult = const ImageProcessResult(
    exitCode: 0,
    stdout: 'Image removed',
    stderr: '',
  );

  /// Result to return from killContainer
  ProcessResult killContainerResult = const ImageProcessResult(
    exitCode: 0,
    stdout: 'Container killed',
    stderr: '',
  );

  /// Whether the runtime is available
  bool available = true;

  /// Version string to return
  String? version = 'mock-runtime 1.0.0';

  /// Architecture to return
  Architecture arch = Architecture.arm64;

  /// Architecture platform to return
  ArchitecturePlatform archPlatform = ArchitecturePlatform.linuxArm64;

  /// Image platform to return (null means image doesn't exist)
  String? imagePlatform;

  /// Track method calls for verification
  final List<MethodCall> methodCalls = [];

  /// Whether to throw on buildImage
  Exception? buildImageException;

  /// Whether to throw on runContainer
  Exception? runContainerException;

  @override
  String get name => 'mock';

  @override
  Future<ProcessResult> buildImage({
    required String imageTag,
    required String dockerfilePath,
    required String contextDir,
    Duration timeout = const Duration(minutes: 5),
    void Function(String)? onStdout,
    void Function(String)? onStderr,
  }) async {
    methodCalls.add(
      MethodCall(
        'buildImage',
        {
          'imageTag': imageTag,
          'dockerfilePath': dockerfilePath,
          'contextDir': contextDir,
          'timeout': timeout,
        },
      ),
    );

    if (buildImageException != null) {
      throw buildImageException!;
    }

    if (buildImageResult is ImageProcessResult) {
      onStdout?.call((buildImageResult as ImageProcessResult).stdout);
      if (buildImageResult.stderr.isNotEmpty) {
        onStderr?.call(buildImageResult.stderr);
      }
    }

    return buildImageResult;
  }

  @override
  Future<ProcessResult> runContainer({
    required String imageTag,
    required String containerName,
    Map<String, String> environment = const {},
    String? envFilePath,
    List<String> volumeMounts = const [],
    int memoryMb = 128,
    double cpus = 0.5,
    String network = 'none',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    methodCalls.add(
      MethodCall(
        'runContainer',
        {
          'imageTag': imageTag,
          'containerName': containerName,
          'environment': environment,
          'envFilePath': envFilePath,
          'volumeMounts': volumeMounts,
          'memoryMb': memoryMb,
          'cpus': cpus,
          'network': network,
          'timeout': timeout,
        },
      ),
    );

    if (runContainerException != null) {
      throw runContainerException!;
    }

    return runContainerResult;
  }

  @override
  Future<ProcessResult> removeImage(String imageTag, {bool force = true}) async {
    methodCalls.add(
      MethodCall(
        'removeImage',
        {'imageTag': imageTag, 'force': force},
      ),
    );
    return removeImageResult;
  }

  @override
  Future<ProcessResult> killContainer(String containerName) async {
    methodCalls.add(
      MethodCall(
        'killContainer',
        {'containerName': containerName},
      ),
    );
    return killContainerResult;
  }

  @override
  Future<bool> isAvailable() async {
    methodCalls.add(MethodCall('isAvailable', {}));
    return available;
  }

  @override
  Future<String?> getVersion() async {
    methodCalls.add(MethodCall('getVersion', {}));
    return version;
  }

  @override
  Future<Architecture> getArch() async {
    methodCalls.add(MethodCall('getArch', {}));
    return arch;
  }

  @override
  Future<ArchitecturePlatform> getArchPlatform() async {
    methodCalls.add(MethodCall('getArchPlatform', {}));
    return archPlatform;
  }

  @override
  Future<String?> getImagePlatform(String imageTag) async {
    methodCalls.add(MethodCall('getImagePlatform', {'imageTag': imageTag}));
    return imagePlatform;
  }

  @override
  Future<void> ensureImagePlatformCompatibility(
    String imageTag,
    ArchitecturePlatform targetPlatform,
  ) async {
    methodCalls.add(
      MethodCall('ensureImagePlatformCompatibility', {
        'imageTag': imageTag,
        'targetPlatform': targetPlatform,
      }),
    );
    if (imagePlatform == null) {
      return;
    }
    if (imagePlatform != targetPlatform.buildPlatform) {
      await removeImage(imageTag, force: true);
    }
  }

  /// Reset all method calls
  void reset() {
    methodCalls.clear();
  }

  /// Check if a method was called
  bool wasCalled(String methodName) {
    return methodCalls.any((call) => call.name == methodName);
  }

  /// Get all calls to a specific method
  List<MethodCall> getCallsTo(String methodName) {
    return methodCalls.where((call) => call.name == methodName).toList();
  }

  @override
  Future<bool> imageExists(String imageTag) {
    methodCalls.add(MethodCall('imageExists', {'imageTag': imageTag}));
    return Future.value(true); // Default to true for testing
  }
}

/// Represents a method call for verification
class MethodCall {
  final String name;
  final Map<String, dynamic> arguments;

  const MethodCall(this.name, this.arguments);

  @override
  String toString() => 'MethodCall($name, $arguments)';
}
