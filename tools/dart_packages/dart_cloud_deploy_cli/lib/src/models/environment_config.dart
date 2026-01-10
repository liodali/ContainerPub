import 'container_config.dart';
import 'host_config.dart';
import 'ansible_config.dart';
import 'openbao_config.dart';

class EnvironmentConfig {
  final Environment environment;
  final ContainerConfig container;
  final HostConfig? host;
  final String? envFilePath;
  final AnsibleConfig? ansible;

  EnvironmentConfig({
    required this.environment,
    required this.container,
    this.host,
    this.envFilePath,
    this.ansible,
  });

  factory EnvironmentConfig.fromMap(
    Environment environment,
    Map<String, dynamic> map,
  ) {
    return EnvironmentConfig(
      environment: environment,
      container: ContainerConfig.fromMap(
        Map<String, dynamic>.from(map['container'] as Map),
      ),
      host: map['host'] != null
          ? HostConfig.fromMap(Map<String, dynamic>.from(map['host'] as Map))
          : null,
      envFilePath: map['env_file_path'] as String?,
      ansible: map['ansible'] != null
          ? AnsibleConfig.fromMap(
              Map<String, dynamic>.from(map['ansible'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'container': container.toMap(),
    if (host != null) 'host': host!.toMap(),
    if (envFilePath != null) 'env_file_path': envFilePath,
    if (ansible != null) 'ansible': ansible!.toMap(),
  };

  bool get isLocal => environment == Environment.local;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;
  bool get requiresAnsible => !isLocal && ansible != null;
}
