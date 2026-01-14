import 'dart:convert';

import 'package:dart_cloud_deploy_cli/dart_cloud_deploy_cli.dart';

class RegistryConfig {
  final String url;
  final String registryCompanyHostName;
  final String username;
  final String tokenBase64;

  RegistryConfig({
    required this.url,
    required this.registryCompanyHostName,
    required this.username,
    required this.tokenBase64,
  });

  factory RegistryConfig.fromMap(Map<String, dynamic> map) {
    return RegistryConfig(
      url: map['url'] as String,
      registryCompanyHostName: map['registry_company_host_name'] as String,
      username: map['username'] as String,
      tokenBase64: map['token_base64'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'url': url,
    'registry_company_host_name': registryCompanyHostName,
    'username': username,
    'token_base64': tokenBase64,
  };

  String get decodedToken {
    try {
      final bytes = base64.decode(tokenBase64);
      return utf8.decode(bytes);
    } catch (e, trace) {
      Console.error('Failed to decode registry token: $e\n$trace');
      throw Exception('Failed to decode registry token: $e\n$trace');
    }
  }
}
