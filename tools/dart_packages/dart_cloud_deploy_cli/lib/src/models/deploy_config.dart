import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:toml/toml.dart';
import 'package:path/path.dart' as p;

import 'environment_config.dart';
import 'openbao_config.dart';
import 'registry_config.dart';
import 'container_config.dart';
import 'host_config.dart';
import 'ansible_config.dart';

export 'environment_config.dart';
export 'openbao_config.dart';
export 'host_config.dart';
export 'container_config.dart';
export 'ansible_config.dart';
export 'registry_config.dart';

class DeployConfig {
  final String name;
  final String projectPath;
  final RegistryConfig? registry;
  final EnvironmentConfig? local;
  final EnvironmentConfig? staging;
  final EnvironmentConfig? production;

  Environment? _currentEnvironment;

  DeployConfig({
    required this.name,
    required this.projectPath,
    this.registry,
    this.local,
    this.staging,
    this.production,
    Environment? environment,
  }) : _currentEnvironment = environment;

  factory DeployConfig.fromMap(Map<String, dynamic> map) {
    return DeployConfig(
      name: map['name'] as String,
      projectPath: map['project_path'] as String,
      registry: map['registry'] != null
          ? RegistryConfig.fromMap(
              Map<String, dynamic>.from(map['registry'] as Map),
            )
          : null,
      local: map['local'] != null
          ? EnvironmentConfig.fromMap(
              Environment.local,
              Map<String, dynamic>.from(map['local'] as Map),
            )
          : null,
      staging: map['staging'] != null
          ? EnvironmentConfig.fromMap(
              Environment.staging,
              Map<String, dynamic>.from(map['staging'] as Map),
            )
          : null,
      production: map['production'] != null
          ? EnvironmentConfig.fromMap(
              Environment.production,
              Map<String, dynamic>.from(map['production'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'project_path': projectPath,
    if (registry != null) 'registry': registry!.toMap(),
    if (local != null) 'local': local!.toMap(),
    if (staging != null) 'staging': staging!.toMap(),
    if (production != null) 'production': production!.toMap(),
  };

  EnvironmentConfig? getEnvironmentConfig(Environment env) {
    switch (env) {
      case Environment.local:
        return local;
      case Environment.staging:
        return staging;
      case Environment.production:
        return production;
    }
  }

  void setCurrentEnvironment(Environment env) {
    _currentEnvironment = env;
  }

  EnvironmentConfig? get _activeEnvironment {
    if (_currentEnvironment != null) {
      return getEnvironmentConfig(_currentEnvironment!);
    }
    return local ?? staging ?? production;
  }

  Environment? get environment => _currentEnvironment;

  ContainerConfig? get container => _activeEnvironment?.container;

  HostConfig? get host => _activeEnvironment?.host;

  String? get envFilePath => _activeEnvironment?.envFilePath;

  AnsibleConfig? get ansible => _activeEnvironment?.ansible;

  bool get isLocal => _currentEnvironment == Environment.local;
  bool get isStaging => _currentEnvironment == Environment.staging;
  bool get isProduction => _currentEnvironment == Environment.production;
  bool get requiresAnsible => !isLocal && ansible != null;

  static Future<DeployConfig> load(String configPath) async {
    final file = File(configPath);
    if (!await file.exists()) {
      throw Exception('Config file not found: $configPath');
    }

    final content = await file.readAsString();
    final ext = p.extension(configPath).toLowerCase();

    Map<String, dynamic> map;
    if (ext == '.yaml' || ext == '.yml') {
      final yaml = loadYaml(content);
      map = _convertYamlToMap(yaml);
    } else if (ext == '.toml') {
      final toml = TomlDocument.parse(content);
      map = toml.toMap();
    } else {
      throw Exception(
        'Unsupported config format: $ext (use .yaml, .yml, or .toml)',
      );
    }

    return DeployConfig.fromMap(map);
  }

  static dynamic _convertYamlToMap(dynamic yaml) {
    if (yaml is YamlMap) {
      return yaml.map(
        (key, value) => MapEntry(key.toString(), _convertYamlToMap(value)),
      );
    } else if (yaml is YamlList) {
      return {'list': yaml.map(_convertYamlToMap).toList()};
    }
    return yaml is Map ? Map<String, dynamic>.from(yaml) : yaml;
  }

  bool hasEnvironment(Environment env) => getEnvironmentConfig(env) != null;
}
