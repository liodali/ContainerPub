import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:toml/toml.dart';
import 'package:path/path.dart' as p;
import '../utils/config_paths.dart';

enum Environment { local, staging, production }

class HostConfig {
  final String host;
  final int port;
  final String user;
  final String? sshKeyPath;
  final String? password;

  HostConfig({
    required this.host,
    this.port = 22,
    required this.user,
    this.sshKeyPath,
    this.password,
  });

  factory HostConfig.fromMap(Map<String, dynamic> map) {
    final sshKeyPath = map['ssh_key_path'] as String?;
    return HostConfig(
      host: map['host'] as String,
      port: map['port'] as int? ?? 22,
      user: map['user'] as String,
      sshKeyPath: sshKeyPath != null
          ? ConfigPaths.expandPath(sshKeyPath)
          : null,
      password: map['password'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'host': host,
    'port': port,
    'user': user,
    if (sshKeyPath != null) 'ssh_key_path': sshKeyPath,
    if (password != null) 'password': password,
  };
}

/// Configuration for a specific environment's token manager
class TokenManagerConfig {
  final String tokenManager;
  final String policy;
  final String secretPath;
  final String roleId;
  final String roleName;

  TokenManagerConfig({
    required this.tokenManager,
    required this.policy,
    required this.secretPath,
    required this.roleId,
    required this.roleName,
  });

  factory TokenManagerConfig.fromMap(Map<String, dynamic> map) {
    return TokenManagerConfig(
      tokenManager: map['token_manager'] as String,
      policy: map['policy'] as String,
      secretPath: map['secret_path'] as String,
      roleId: map['role_id'] as String,
      roleName: map['role_name'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'token_manager': tokenManager,
    'policy': policy,
    'secret_path': secretPath,
    'role_id': roleId,
    'role_name': roleName,
  };
}

class OpenBaoConfig {
  final String address;
  final String? namespace;
  final TokenManagerConfig? local;
  final TokenManagerConfig? staging;
  final TokenManagerConfig? production;

  OpenBaoConfig({
    required this.address,
    this.namespace,
    this.local,
    this.staging,
    this.production,
  });

  factory OpenBaoConfig.fromMap(Map<String, dynamic> map) {
    return OpenBaoConfig(
      address: map['address'] as String,
      namespace: map['namespace'] as String?,
      local: map['local'] != null
          ? TokenManagerConfig.fromMap(
              Map<String, dynamic>.from(map['local'] as Map),
            )
          : null,
      staging: map['staging'] != null
          ? TokenManagerConfig.fromMap(
              Map<String, dynamic>.from(map['staging'] as Map),
            )
          : null,
      production: map['production'] != null
          ? TokenManagerConfig.fromMap(
              Map<String, dynamic>.from(map['production'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'address': address,
    if (namespace != null) 'namespace': namespace,
    if (local != null) 'local': local!.toMap(),
    if (staging != null) 'staging': staging!.toMap(),
    if (production != null) 'production': production!.toMap(),
  };

  /// Get token manager config for a specific environment
  TokenManagerConfig? getEnvConfig(Environment env) {
    switch (env) {
      case Environment.local:
        return local;
      case Environment.staging:
        return staging;
      case Environment.production:
        return production;
    }
  }

  /// Get secret path for a specific environment
  String? getSecretPath(Environment env) => getEnvConfig(env)?.secretPath;

  /// Get policy for a specific environment
  String? getPolicy(Environment env) => getEnvConfig(env)?.policy;

  /// Get token manager path for a specific environment
  String? getTokenManager(Environment env) => getEnvConfig(env)?.tokenManager;
}

class ContainerConfig {
  final String runtime;
  final String composeFile;
  final String projectName;
  final String networkName;
  final Map<String, String> services;

  ContainerConfig({
    this.runtime = 'podman',
    required this.composeFile,
    this.projectName = 'dart_cloud',
    this.networkName = 'dart_cloud_network',
    required this.services,
  });

  factory ContainerConfig.fromMap(Map<String, dynamic> map) {
    return ContainerConfig(
      runtime: map['runtime'] as String? ?? 'podman',
      composeFile: map['compose_file'] as String,
      projectName: map['project_name'] as String? ?? 'dart_cloud',
      networkName: map['network_name'] as String? ?? 'dart_cloud_network',
      services: Map<String, String>.from(map['services'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'runtime': runtime,
    'compose_file': composeFile,
    'project_name': projectName,
    'network_name': networkName,
    'services': services,
  };

  String get composeCommand =>
      runtime == 'podman' ? 'podman-compose' : 'docker compose';
  String get containerCommand => runtime == 'podman' ? 'podman' : 'sudo docker';
}

class AnsibleConfig {
  final String? inventoryPath;
  final String backendPlaybook;
  final String databasePlaybook;
  final String backupPlaybook;
  final Map<String, dynamic> extraVars;

  AnsibleConfig({
    this.inventoryPath,
    required this.backendPlaybook,
    required this.databasePlaybook,
    required this.backupPlaybook,
    this.extraVars = const {},
  });

  factory AnsibleConfig.fromMap(Map<String, dynamic> map) {
    return AnsibleConfig(
      inventoryPath: map['inventory_path'] as String?,
      backendPlaybook:
          map['backend_playbook'] as String? ?? 'playbooks/backend.yml',
      databasePlaybook:
          map['database_playbook'] as String? ?? 'playbooks/database.yml',
      backupPlaybook:
          map['backup_playbook'] as String? ?? 'playbooks/backup.yml',
      extraVars: Map<String, dynamic>.from(map['extra_vars'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    if (inventoryPath != null) 'inventory_path': inventoryPath,
    'backend_playbook': backendPlaybook,
    'database_playbook': databasePlaybook,
    'backup_playbook': backupPlaybook,
    'extra_vars': extraVars,
  };
}

class DeployConfig {
  final String name;
  final Environment environment;
  final String projectPath;
  final String? envFilePath;
  final HostConfig? host;
  final OpenBaoConfig? openbao;
  final ContainerConfig container;
  final AnsibleConfig? ansible;

  DeployConfig({
    required this.name,
    required this.environment,
    required this.projectPath,
    this.envFilePath,
    this.host,
    this.openbao,
    required this.container,
    this.ansible,
  });

  factory DeployConfig.fromMap(Map<String, dynamic> map) {
    final envStr = map['environment'] as String? ?? 'local';
    final environment = Environment.values.firstWhere(
      (e) => e.name == envStr,
      orElse: () => Environment.local,
    );

    return DeployConfig(
      name: map['name'] as String,
      environment: environment,
      projectPath: map['project_path'] as String,
      envFilePath: map['env_file_path'] as String?,
      host: map['host'] != null
          ? HostConfig.fromMap(Map<String, dynamic>.from(map['host'] as Map))
          : null,
      openbao: map['openbao'] != null
          ? OpenBaoConfig.fromMap(
              Map<String, dynamic>.from(map['openbao'] as Map),
            )
          : null,
      container: ContainerConfig.fromMap(
        Map<String, dynamic>.from(map['container'] as Map? ?? {}),
      ),
      ansible: map['ansible'] != null
          ? AnsibleConfig.fromMap(
              Map<String, dynamic>.from(map['ansible'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'environment': environment.name,
    'project_path': projectPath,
    if (envFilePath != null) 'env_file_path': envFilePath,
    if (host != null) 'host': host!.toMap(),
    if (openbao != null) 'openbao': openbao!.toMap(),
    'container': container.toMap(),
    if (ansible != null) 'ansible': ansible!.toMap(),
  };

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

  static Map<String, dynamic> _convertYamlToMap(dynamic yaml) {
    if (yaml is YamlMap) {
      return yaml.map(
        (key, value) => MapEntry(key.toString(), _convertYamlToMap(value)),
      );
    } else if (yaml is YamlList) {
      return {'list': yaml.map(_convertYamlToMap).toList()};
    }
    return yaml is Map ? Map<String, dynamic>.from(yaml) : yaml;
  }

  bool get isLocal => environment == Environment.local;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;
  bool get requiresAnsible => !isLocal && ansible != null;
}
