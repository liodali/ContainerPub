import 'package:collection/collection.dart';

/// Configuration for container execution
class ContainerConfig {
  final String imageTag;
  final String containerName;
  final Map<String, String> environment;
  final List<String> volumeMounts;
  final int memoryMb;
  final String memoryUnit;
  final double cpus;
  final String network;
  final Duration timeout;

  const ContainerConfig({
    required this.imageTag,
    required this.containerName,
    this.environment = const {},
    this.volumeMounts = const [],
    this.memoryMb = 128,
    this.memoryUnit = 'm',
    this.cpus = 0.5,
    this.network = 'none',
    this.timeout = const Duration(seconds: 30),
  });

  ContainerConfig copyWith({
    String? imageTag,
    String? containerName,
    Map<String, String>? environment,
    List<String>? volumeMounts,
    int? memoryMb,
    double? cpus,
    String? network,
    Duration? timeout,
  }) {
    return ContainerConfig(
      imageTag: imageTag ?? this.imageTag,
      containerName: containerName ?? this.containerName,
      environment: environment ?? this.environment,
      volumeMounts: volumeMounts ?? this.volumeMounts,
      memoryMb: memoryMb ?? this.memoryMb,
      cpus: cpus ?? this.cpus,
      network: network ?? this.network,
      timeout: timeout ?? this.timeout,
    );
  }
}

/// Configuration for image build
class BuildConfig {
  final String imageTag;
  final String dockerfilePath;
  final String contextDir;
  final Duration timeout;

  const BuildConfig({
    required this.imageTag,
    required this.dockerfilePath,
    required this.contextDir,
    this.timeout = const Duration(minutes: 5),
  });
}

typedef ImageSizeData = ({double size, UniteSize unit});

enum UniteSize {
  G('G', 'g'),
  MB('MB', 'm'),
  KB('KB', 'kb')
  ;

  const UniteSize(this.value, this.memoryUnit);
  final String value;
  final String memoryUnit;

  static UniteSize fromString(String unit) {
    final size = UniteSize.values.firstWhereOrNull((element) => element.value == unit);
    return size ?? UniteSize.MB;
  }
}
