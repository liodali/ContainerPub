enum Environment { local, staging, production }

class OpenBaoConfig {
  final String address;
  final String? namespace;
  final String tokenManager;
  final String policy;
  final String secretPath;
  final String roleId;
  final String roleName;

  OpenBaoConfig({
    required this.address,
    this.namespace,
    required this.tokenManager,
    required this.policy,
    required this.secretPath,
    required this.roleId,
    required this.roleName,
  });

  factory OpenBaoConfig.fromMap(Map<String, dynamic> map) {
    return OpenBaoConfig(
      address: map['address'] as String,
      namespace: map['namespace'] as String?,
      tokenManager: map['token_manager'] as String,
      policy: map['policy'] as String,
      secretPath: map['secret_path'] as String,
      roleId: map['role_id'] as String,
      roleName: map['role_name'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'address': address,
    if (namespace != null) 'namespace': namespace,
    'token_manager': tokenManager,
    'policy': policy,
    'secret_path': secretPath,
    'role_id': roleId,
    'role_name': roleName,
  };
}
