import 'dart:io';
import 'package:yaml/yaml.dart';
import 'workspace_detector.dart';

class ConfigManager {
  final WorkspaceInfo workspace;

  ConfigManager(this.workspace);

  /// Check if config file exists
  bool get configExists => File(workspace.configPath).existsSync();

  /// Load existing config as map
  Future<Map<String, dynamic>?> loadConfig() async {
    if (!configExists) return null;

    final content = await File(workspace.configPath).readAsString();
    final yaml = loadYaml(content);
    return _convertYamlToMap(yaml);
  }

  /// Check if environment section exists in config
  Future<bool> hasEnvironmentSection(String environment) async {
    final config = await loadConfig();
    if (config == null) return false;
    return config.containsKey(environment);
  }

  /// Add environment section to existing config if not present
  Future<bool> addEnvironmentSection({
    required String environment,
    required Map<String, dynamic> envConfig,
  }) async {
    if (!configExists) return false;

    final config = await loadConfig();
    if (config == null) return false;

    // Skip if environment already exists
    if (config.containsKey(environment)) {
      return false; // Already exists, skip
    }

    // Read raw content and append environment section
    final content = await File(workspace.configPath).readAsString();
    final envYaml = _generateEnvironmentYaml(environment, envConfig);

    await File(workspace.configPath).writeAsString('$content\n$envYaml');
    return true;
  }

  /// Add OpenBao configuration to an existing environment
  Future<bool> addOpenBaoToEnvironment({
    required String environment,
    required Map<String, dynamic> openbaoConfig,
  }) async {
    if (!configExists) return false;

    final config = await loadConfig();
    if (config == null) return false;

    // Check if environment exists
    if (!config.containsKey(environment)) {
      return false; // Environment doesn't exist
    }

    // Check if OpenBao already exists
    final envConfig = config[environment];
    if (envConfig != null && envConfig['openbao'] != null) {
      return false; // OpenBao already configured
    }

    // Read raw content and add OpenBao section
    final content = await File(workspace.configPath).readAsString();
    final lines = content.split('\n');
    final buffer = StringBuffer();

    bool inTargetEnv = false;
    bool openbaoAdded = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check if we're entering the target environment
      if (line.trim().startsWith('$environment:')) {
        inTargetEnv = true;
        buffer.writeln(line);
        continue;
      }

      // If we're in the target environment and haven't added OpenBao yet
      if (inTargetEnv && !openbaoAdded) {
        // Check if we've reached another top-level key (next environment or section)
        final trimmed = line.trim();
        if (trimmed.isNotEmpty &&
            !line.startsWith(' ') &&
            !line.startsWith('\t') &&
            trimmed.contains(':') &&
            !trimmed.startsWith('#')) {
          // We've reached the next section, add OpenBao before it
          buffer.writeln('  # OpenBao Configuration (for secrets management)');
          buffer.writeln('  openbao:');
          _writeMapAsYaml(buffer, openbaoConfig, indent: 4);
          openbaoAdded = true;
        }
      }

      buffer.writeln(line);
    }

    // If we reached the end and haven't added OpenBao, add it now
    if (inTargetEnv && !openbaoAdded) {
      buffer.writeln('  # OpenBao Configuration (for secrets management)');
      buffer.writeln('  openbao:');
      _writeMapAsYaml(buffer, openbaoConfig, indent: 4);
    }

    await File(workspace.configPath).writeAsString(buffer.toString());
    return true;
  }

  /// Create new config file with all sections
  Future<void> createConfig({
    required String name,
    required String environment,
    String format = 'yaml',
    Map<String, dynamic>? openbao,
    Map<String, dynamic>? container,
    Map<String, dynamic>? host,
    Map<String, dynamic>? ansible,
  }) async {
    // Ensure .dart_tool exists
    if (workspace.isDartProject) {
      await WorkspaceDetector.ensureDartToolExists(workspace.path);
    }

    final content = format == 'toml'
        ? _generateFullConfigToml(
            name: name,
            environment: environment,
            openbao: openbao,
            container: container,
            host: host,
            ansible: ansible,
          )
        : _generateFullConfig(
            name: name,
            environment: environment,
            openbao: openbao,
            container: container,
            host: host,
            ansible: ansible,
          );

    await File(workspace.configPath).writeAsString(content);
  }

  /// Generate missing OpenBao config with defaults for a specific environment
  static Map<String, dynamic> generateOpenBaoDefaults({
    String? address,
    String? secretPath,
    String? roleId,
    String? roleName,
    String? namespace,
    String environment = 'local',
  }) {
    return {
      'address': address ?? 'http://localhost:8200',
      if (namespace != null) 'namespace': namespace,
      'token_manager': 'approle',
      'policy': '$environment-policy',
      'secret_path': secretPath ?? 'secret/data/app/$environment',
      'role_id': roleId ?? '<ROLE_ID>',
      'role_name': roleName ?? '$environment-role',
    };
  }

  /// Generate container config defaults
  static Map<String, dynamic> generateContainerDefaults({
    String? runtime,
    String? composeFile,
    String? projectName,
    String? networkName,
    Map<String, String>? services,
  }) {
    return {
      'runtime': runtime ?? 'podman',
      'compose_file': composeFile ?? 'docker-compose.yml',
      'project_name': projectName ?? 'dart_cloud',
      'network_name': networkName ?? 'dart_cloud_network',
      'services':
          services ??
          {
            'backend': 'dart_cloud_backend',
            'postgres': 'dart_cloud_postgres',
          },
    };
  }

  String _generateFullConfig({
    required String name,
    required String environment,
    Map<String, dynamic>? openbao,
    Map<String, dynamic>? container,
    Map<String, dynamic>? host,
    Map<String, dynamic>? ansible,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('# Dart Cloud Deployment Configuration');
    buffer.writeln('# Generated by dart_cloud_deploy CLI');
    buffer.writeln('');
    buffer.writeln('name: $name');
    buffer.writeln('project_path: .');
    buffer.writeln('');

    // Environment section
    buffer.writeln('# Environment: $environment');
    buffer.writeln('$environment:');
    buffer.writeln('  env_file_path: .env');

    if (container != null) {
      buffer.writeln('  container:');
      _writeMapAsYaml(buffer, container, indent: 4);
    }

    // OpenBao section (per-environment)
    if (openbao != null) {
      buffer.writeln('  # OpenBao Configuration (for secrets management)');
      buffer.writeln('  openbao:');
      _writeMapAsYaml(buffer, openbao, indent: 4);
    }

    if (host != null && environment != 'local') {
      buffer.writeln('  host:');
      _writeMapAsYaml(buffer, host, indent: 4);
    }

    if (ansible != null && environment != 'local') {
      buffer.writeln('  ansible:');
      _writeMapAsYaml(buffer, ansible, indent: 4);
    }

    return buffer.toString();
  }

  String _generateEnvironmentYaml(
    String environment,
    Map<String, dynamic> config,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('# Environment: $environment');
    buffer.writeln('$environment:');
    _writeMapAsYaml(buffer, config, indent: 2);
    return buffer.toString();
  }

  void _writeMapAsYaml(
    StringBuffer buffer,
    Map<String, dynamic> map, {
    int indent = 0,
  }) {
    final prefix = ' ' * indent;
    for (final entry in map.entries) {
      if (entry.value is Map) {
        buffer.writeln('$prefix${entry.key}:');
        _writeMapAsYaml(
          buffer,
          Map<String, dynamic>.from(entry.value as Map),
          indent: indent + 2,
        );
      } else if (entry.value is List) {
        buffer.writeln('$prefix${entry.key}:');
        for (final item in entry.value as List) {
          buffer.writeln('$prefix  - $item');
        }
      } else {
        buffer.writeln('$prefix${entry.key}: ${entry.value}');
      }
    }
  }

  static dynamic _convertYamlToMap(dynamic yaml) {
    /// this wrong should be fixed
    if (yaml is YamlMap) {
      return yaml.map(
        (key, value) => MapEntry(key.toString(), _convertYamlToMap(value)),
      );
    } else if (yaml is YamlList) {
      return {'list': yaml.map(_convertYamlToMap).toList()};
    }
    return yaml is Map ? Map<String, dynamic>.from(yaml) : yaml;
  }

  String _generateFullConfigToml({
    required String name,
    required String environment,
    Map<String, dynamic>? openbao,
    Map<String, dynamic>? container,
    Map<String, dynamic>? host,
    Map<String, dynamic>? ansible,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('# Dart Cloud Deployment Configuration');
    buffer.writeln('# Generated by dart_cloud_deploy CLI');
    buffer.writeln('');
    buffer.writeln('name = "$name"');
    buffer.writeln('project_path = "."');
    buffer.writeln('');

    // Environment section
    buffer.writeln('# Environment: $environment');
    buffer.writeln('[$environment]');
    buffer.writeln('env_file_path = ".env"');
    buffer.writeln('');

    if (container != null) {
      buffer.writeln('[$environment.container]');
      _writeMapAsToml(buffer, container, prefix: '');
      buffer.writeln('');
    }

    // OpenBao section (per-environment)
    if (openbao != null) {
      buffer.writeln('# OpenBao Configuration (for secrets management)');
      buffer.writeln('[$environment.openbao]');
      _writeMapAsToml(buffer, openbao, prefix: '');
      buffer.writeln('');
    }

    if (host != null && environment != 'local') {
      buffer.writeln('[$environment.host]');
      _writeMapAsToml(buffer, host, prefix: '');
      buffer.writeln('');
    }

    if (ansible != null && environment != 'local') {
      buffer.writeln('[$environment.ansible]');
      _writeMapAsToml(buffer, ansible, prefix: '');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  void _writeMapAsToml(
    StringBuffer buffer,
    Map<String, dynamic> map, {
    String prefix = '',
  }) {
    for (final entry in map.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      if (entry.value is Map) {
        _writeMapAsToml(
          buffer,
          Map<String, dynamic>.from(entry.value as Map),
          prefix: key,
        );
      } else if (entry.value is String) {
        buffer.writeln('${entry.key} = "${entry.value}"');
      } else if (entry.value is int ||
          entry.value is double ||
          entry.value is bool) {
        buffer.writeln('${entry.key} = ${entry.value}');
      } else if (entry.value is List) {
        final items = (entry.value as List).map((e) => '"$e"').join(', ');
        buffer.writeln('${entry.key} = [$items]');
      }
    }
  }
}
