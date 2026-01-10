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
