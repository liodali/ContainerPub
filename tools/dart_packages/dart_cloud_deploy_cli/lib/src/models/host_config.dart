import '../utils/config_paths.dart';

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
