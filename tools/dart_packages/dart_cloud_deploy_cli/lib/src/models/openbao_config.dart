enum Environment { local, staging, production }

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

  String? getSecretPath(Environment env) => getEnvConfig(env)?.secretPath;
  String? getPolicy(Environment env) => getEnvConfig(env)?.policy;
  String? getTokenManager(Environment env) => getEnvConfig(env)?.tokenManager;
}
