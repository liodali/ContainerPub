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
  final String? apiKeyUuid;
  final String? apiKeyPublicKey;
  final String? apiKeyValidity;
  final String? apiKeyExpiresAt;

  FunctionConfig({
    required this.functionName,
    this.functionId,
    this.createdAt,
    this.functionPath,
    this.lastDeployHash,
    this.lastDeployedAt,
    this.deployVersion,
    this.apiKeyUuid,
    this.apiKeyPublicKey,
    this.apiKeyValidity,
    this.apiKeyExpiresAt,
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
      if (apiKeyUuid != null) 'api_key_uuid': apiKeyUuid,
      if (apiKeyPublicKey != null) 'api_key_public_key': apiKeyPublicKey,
      if (apiKeyValidity != null) 'api_key_validity': apiKeyValidity,
      if (apiKeyExpiresAt != null) 'api_key_expires_at': apiKeyExpiresAt,
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
      apiKeyUuid: json['api_key_uuid'] as String?,
      apiKeyPublicKey: json['api_key_public_key'] as String?,
      apiKeyValidity: json['api_key_validity'] as String?,
      apiKeyExpiresAt: json['api_key_expires_at'] as String?,
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
    String? apiKeyUuid,
    String? apiKeyPublicKey,
    String? apiKeyValidity,
    String? apiKeyExpiresAt,
  }) {
    return FunctionConfig(
      functionName: functionName,
      functionId: functionId ?? this.functionId,
      createdAt: createdAt,
      functionPath: functionPath ?? this.functionPath,
      lastDeployHash: lastDeployHash ?? this.lastDeployHash,
      lastDeployedAt: lastDeployedAt ?? this.lastDeployedAt,
      deployVersion: deployVersion ?? this.deployVersion,
      apiKeyUuid: apiKeyUuid ?? this.apiKeyUuid,
      apiKeyPublicKey: apiKeyPublicKey ?? this.apiKeyPublicKey,
      apiKeyValidity: apiKeyValidity ?? this.apiKeyValidity,
      apiKeyExpiresAt: apiKeyExpiresAt ?? this.apiKeyExpiresAt,
    );
  }

  /// Check if the given hash matches the last deployed hash
  bool hasUnchangedCode(String currentHash) {
    return lastDeployHash != null && lastDeployHash == currentHash;
  }

  /// Get the next deploy version
  int get nextVersion => (deployVersion ?? 0) + 1;

  /// Check if function has an API key configured
  bool get hasApiKey => apiKeyUuid != null && apiKeyPublicKey != null;

  /// Load the private API key from .dart_tool/api_key.secret
  /// This file is stored separately and should be gitignored
  static Future<String?> loadPrivateKey(String directoryPath) async {
    try {
      final keyFile = File(
        path.join(directoryPath, '.dart_tool', 'api_key.secret'),
      );

      if (!keyFile.existsSync()) {
        return null;
      }

      return keyFile.readAsStringSync().trim();
    } catch (e) {
      print('Warning: Failed to load private key: $e');
      return null;
    }
  }

  /// Save the private API key to .dart_tool/api_key.secret
  /// This file should be gitignored
  static Future<void> savePrivateKey(
    String directoryPath,
    String privateKey,
  ) async {
    try {
      final dartToolDir = Directory(path.join(directoryPath, '.dart_tool'));
      if (!dartToolDir.existsSync()) {
        dartToolDir.createSync(recursive: true);
      }

      final keyFile = File(
        path.join(dartToolDir.path, 'api_key.secret'),
      );

      keyFile.writeAsStringSync(privateKey, flush: true);

      // Ensure .gitignore includes the secret file
      final gitignoreFile = File(path.join(directoryPath, '.gitignore'));
      if (gitignoreFile.existsSync()) {
        final content = gitignoreFile.readAsStringSync();
        if (!content.contains('.dart_tool/api_key.secret')) {
          gitignoreFile.writeAsStringSync(
            '$content\n# API key secret - DO NOT COMMIT\n.dart_tool/api_key.secret\n',
            flush: true,
          );
        }
      } else {
        gitignoreFile.writeAsStringSync(
          '# API key secret - DO NOT COMMIT\n.dart_tool/api_key.secret\n',
          flush: true,
        );
      }
    } catch (e) {
      print('Warning: Failed to save private key: $e');
    }
  }

  /// Delete the private API key file
  static Future<void> deletePrivateKey(String directoryPath) async {
    try {
      final keyFile = File(
        path.join(directoryPath, '.dart_tool', 'api_key.secret'),
      );

      if (keyFile.existsSync()) {
        keyFile.deleteSync();
      }
    } catch (e) {
      print('Warning: Failed to delete private key: $e');
    }
  }
}
