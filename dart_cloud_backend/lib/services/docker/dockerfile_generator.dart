import 'package:dart_cloud_backend/services/docker/container_runtime.dart'
    show ArchitecturePlatform;

/// Generates Dockerfile content for Dart cloud functions
///
/// This class is responsible for creating optimized multi-stage Dockerfiles
/// that compile Dart code to native AOT executables.
class DockerfileGenerator {
  /// Base image for the build stage
  final String buildImage;

  /// Base image for the runtime stage
  final String runtimeImage;

  /// Create a DockerfileGenerator
  ///
  /// [buildImage] defaults to 'dart:stable' for compilation
  /// [runtimeImage] defaults to 'alpine' for minimal runtime
  const DockerfileGenerator({
    this.buildImage = 'dart:stable',
    this.runtimeImage = 'alpine',
  });

  /// Generate Dockerfile content for a Dart function
  ///
  /// Creates an optimized multi-stage Dockerfile:
  ///
  /// **Stage 1 (Build):**
  /// - Uses dart:stable to compile Dart code
  /// - Installs dependencies from pubspec.yaml
  /// - Compiles to native AOT executable
  ///
  /// **Stage 2 (Runtime):**
  /// - Uses minimal base image (alpine)
  /// - Copies only the compiled executable
  /// - Results in ~10-20MB image vs ~500MB+
  ///
  /// Parameters:
  /// - [buildStageTag]: Unique tag for the build stage (for cleanup)
  /// - [entrypoint]: Main Dart file to compile (default: 'main.dart')
  /// - [outputBinary]: Name of the output binary (default: 'function')
  ///
  /// Returns: Dockerfile content as string
  String generate({
    required String buildStageTag,
    String entrypoint = 'main.dart',
    String outputBinary = 'function',
    ArchitecturePlatform targetPlatform = ArchitecturePlatform.linuxX64,
  }) {
    final archCMD = targetPlatform == ArchitecturePlatform.linuxX64
        ? '--target-os=linux --target-arch=x64 '
        : '--target-os=linux --target-arch=arm64';

    return '''
# ============================================
# Stage 1: Build - Compile Dart to native AOT
# ============================================
FROM $buildImage AS $buildStageTag

# Set working directory
WORKDIR /app

# Copy pubspec files first for better layer caching
#COPY pubspec.* ./
COPY pubspec.yaml pubspec.lock ./

# Install dependencies (if pubspec.yaml exists)
RUN dart pub get

# Copy all function source files
COPY . .

RUN dart pub get

RUN dart format .

# Compile Dart to native AOT executable
RUN dart compile exe $entrypoint $archCMD -o /app/$outputBinary

# ============================================
# Stage 2: Runtime - Minimal image
# ============================================
FROM $runtimeImage

WORKDIR /runner
# Copy runtime dependencies (required for Dart AOT on alpine)
COPY --from=$buildStageTag /runtime/ /

# Copy the compiled executable from build stage
COPY --from=$buildStageTag /app/$outputBinary /runner/$outputBinary

RUN chmod +x /runner/$outputBinary

# Set the entrypoint to the compiled function
# Request data will be mounted at /request.json at runtime
CMD ["/runner/$outputBinary"]
''';
  }

  /// Generate a simple Dockerfile without multi-stage build
  ///
  /// Useful for development/debugging when you need the full Dart SDK
  String generateDevelopment({
    String entrypoint = 'main.dart',
  }) {
    return '''
# Development Dockerfile (includes full Dart SDK)
FROM $buildImage

WORKDIR /app

COPY pubspec.* ./

RUN dart pub get

COPY . .

CMD ["dart", "run", "$entrypoint"]
''';
  }
}
