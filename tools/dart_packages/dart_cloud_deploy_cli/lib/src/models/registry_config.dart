import 'dart:convert';

class RegistryConfig {
  final String url;
  final String username;
  final String tokenBase64;

  RegistryConfig({
    required this.url,
    required this.username,
    required this.tokenBase64,
  });

  factory RegistryConfig.fromMap(Map<String, dynamic> map) {
    return RegistryConfig(
      url: map['url'] as String,
      username: map['username'] as String,
      tokenBase64: map['token_base64'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'url': url,
    'username': username,
    'token_base64': tokenBase64,
  };

  String get decodedToken {
    try {
      final bytes = base64.decode(tokenBase64);
      return utf8.decode(bytes);
    } catch (e) {
      throw Exception('Failed to decode registry token: $e');
    }
  }
}
