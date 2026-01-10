class ContainerConfig {
  final String runtime;
  final String composeFile;
  final String projectName;
  final String networkName;
  final Map<String, String> services;
  final String rebuildStrategy;

  ContainerConfig({
    this.runtime = 'podman',
    required this.composeFile,
    this.projectName = 'dart_cloud',
    this.networkName = 'dart_cloud_network',
    required this.services,
    this.rebuildStrategy = 'all',
  });

  factory ContainerConfig.fromMap(Map<String, dynamic> map) {
    return ContainerConfig(
      runtime: map['runtime'] as String? ?? 'podman',
      composeFile: map['compose_file'] as String,
      projectName: map['project_name'] as String? ?? 'dart_cloud',
      networkName: map['network_name'] as String? ?? 'dart_cloud_network',
      services: Map<String, String>.from(map['services'] as Map? ?? {}),
      rebuildStrategy: map['rebuild_strategy'] as String? ?? 'all',
    );
  }

  Map<String, dynamic> toMap() => {
    'runtime': runtime,
    'compose_file': composeFile,
    'project_name': projectName,
    'network_name': networkName,
    'services': services,
    'rebuild_strategy': rebuildStrategy,
  };

  String get composeCommand =>
      runtime == 'podman' ? 'podman-compose' : 'docker compose';
  String get containerCommand => runtime == 'podman' ? 'podman' : 'sudo docker';
}
