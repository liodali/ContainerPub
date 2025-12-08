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
  }) {
    return '''
# ============================================
# Stage 1: Build - Compile Dart to native AOT
# ============================================
FROM $buildImage AS $buildStageTag

# Set working directory
WORKDIR /app

# Copy pubspec files first for better layer caching
COPY pubspec.* ./

# Install dependencies (if pubspec.yaml exists)
RUN if [ -f pubspec.yaml ]; then dart pub get; fi

# Copy all function source files
COPY . .

RUN dart pub get

RUN dart format .

# Compile Dart to native AOT executable
RUN dart compile exe $entrypoint --target-os=linux --target-arch=x64  -o /app/$outputBinary

# ============================================
# Stage 2: Runtime - Minimal image
# ============================================
FROM $runtimeImage

# Copy runtime dependencies (required for Dart AOT on alpine)
COPY --from=$buildStageTag /runtime/ /

# Copy the compiled executable from build stage
COPY --from=$buildStageTag /app/$outputBinary /$outputBinary

# Set the entrypoint to the compiled function
# Request data will be mounted at /request.json at runtime
ENTRYPOINT ["/$outputBinary"]
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
RUN if [ -f pubspec.yaml ]; then dart pub get; fi

COPY . .

CMD ["dart", "run", "$entrypoint"]
''';
  }
}
