import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class FunctionConfig {
  final String functionName;
  final String? functionId;
  final String? createdAt;

  FunctionConfig({
    required this.functionName,
    this.functionId,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'function_name': functionName,
      if (functionId != null) 'function_id': functionId,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  factory FunctionConfig.fromJson(Map<String, dynamic> json) {
    return FunctionConfig(
      functionName: json['function_name'] as String? ?? 'function',
      functionId: json['function_id'] as String?,
      createdAt: json['created_at'] as String?,
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

  /// Update the function ID in the config
  FunctionConfig copyWith({String? functionId}) {
    return FunctionConfig(
      functionName: functionName,
      functionId: functionId ?? this.functionId,
      createdAt: createdAt,
    );
  }
}
