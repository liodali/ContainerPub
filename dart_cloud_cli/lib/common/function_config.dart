import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class FunctionConfig {
  final String functionName;
  final String? functionId;
  final String? createdAt;
  final String? functionPath;
  final String? lastDeployHash;
  final String? lastDeployedAt;
  final int? deployVersion;

  FunctionConfig({
    required this.functionName,
    this.functionId,
    this.createdAt,
    this.functionPath,
    this.lastDeployHash,
    this.lastDeployedAt,
    this.deployVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'function_name': functionName,
      if (functionId != null) 'function_id': functionId,
      if (createdAt != null) 'created_at': createdAt,
      if (functionPath != null) 'function_path': functionPath,
      if (lastDeployHash != null) 'last_deploy_hash': lastDeployHash,
      if (lastDeployedAt != null) 'last_deployed_at': lastDeployedAt,
      if (deployVersion != null) 'deploy_version': deployVersion,
    };
  }

  factory FunctionConfig.fromJson(Map<String, dynamic> json) {
    return FunctionConfig(
      functionName: json['function_name'] as String? ?? 'function',
      functionId: json['function_id'] as String?,
      createdAt: json['created_at'] as String?,
      functionPath: json['function_path'] as String?,
      lastDeployHash: json['last_deploy_hash'] as String?,
      lastDeployedAt: json['last_deployed_at'] as String?,
      deployVersion: json['deploy_version'] as int?,
    );
  }

  /// Load function config from the current directory's .dart_tool
  static Future<FunctionConfig?> load(String directoryPath) async {
    try {
      final configFile = File(
        path.join(directoryPath, '.dart_tool', 'function_config.json'),
      );

      if (!configFile.existsSync()) {
        return null;
      }

      final content = configFile.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return FunctionConfig.fromJson(json);
    } catch (e) {
      print('Warning: Failed to load function config: $e');
      return null;
    }
  }

  /// Save function config to the current directory's .dart_tool
  Future<void> save(String directoryPath) async {
    try {
      final dartToolDir = Directory(path.join(directoryPath, '.dart_tool'));
      if (!dartToolDir.existsSync()) {
        dartToolDir.createSync(recursive: true);
      }

      final configFile = File(
        path.join(dartToolDir.path, 'function_config.json'),
      );

      configFile.writeAsStringSync(
        jsonEncode(toJson()),
        flush: true,
      );
    } catch (e) {
      print('Warning: Failed to save function config: $e');
    }
  }

  /// Update the function config fields
  FunctionConfig copyWith({
    String? functionId,
    String? functionPath,
    String? lastDeployHash,
    String? lastDeployedAt,
    int? deployVersion,
  }) {
    return FunctionConfig(
      functionName: functionName,
      functionId: functionId ?? this.functionId,
      createdAt: createdAt,
      functionPath: functionPath ?? this.functionPath,
      lastDeployHash: lastDeployHash ?? this.lastDeployHash,
      lastDeployedAt: lastDeployedAt ?? this.lastDeployedAt,
      deployVersion: deployVersion ?? this.deployVersion,
    );
  }

  /// Check if the given hash matches the last deployed hash
  bool hasUnchangedCode(String currentHash) {
    return lastDeployHash != null && lastDeployHash == currentHash;
  }

  /// Get the next deploy version
  int get nextVersion => (deployVersion ?? 0) + 1;
}
