import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/deploy_config.dart';
import '../templates/playbook_templates.dart';
import '../utils/console.dart';

class PlaybookService {
  final String workingDirectory;
  final String playbooksDir;

  PlaybookService({required this.workingDirectory, String? playbooksDir})
    : playbooksDir =
          playbooksDir ?? p.join(workingDirectory, '.deploy_playbooks');

  Future<void> ensurePlaybooksDir() async {
    final dir = Directory(playbooksDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<String> generateBackendPlaybook(DeployConfig config) async {
    await ensurePlaybooksDir();

    final content = PlaybookTemplates.backend(
      appDir:
          config.ansible?.extraVars['app_dir'] as String? ?? '/opt/dart_cloud',
      composeFile: config.container.composeFile,
      containerRuntime: config.container.runtime,
      projectName: config.container.projectName,
      backendService: config.container.services['backend'] ?? 'backend-cloud',
      envFile: config.envFilePath ?? '.env',
    );

    final playbookPath = p.join(playbooksDir, 'backend.yml');
    await File(playbookPath).writeAsString(content);
    Console.info('Generated backend playbook: $playbookPath');
    return playbookPath;
  }

  Future<String> generateDatabasePlaybook(DeployConfig config) async {
    await ensurePlaybooksDir();

    final content = PlaybookTemplates.database(
      appDir:
          config.ansible?.extraVars['app_dir'] as String? ?? '/opt/dart_cloud',
      composeFile: config.container.composeFile,
      containerRuntime: config.container.runtime,
      projectName: config.container.projectName,
      databaseService: config.container.services['postgres'] ?? 'postgres',
      postgresUser:
          config.ansible?.extraVars['postgres_user'] as String? ?? 'dart_cloud',
      postgresDb:
          config.ansible?.extraVars['postgres_db'] as String? ?? 'dart_cloud',
      dataDir:
          config.ansible?.extraVars['data_dir'] as String? ??
          '/var/lib/dart_cloud/postgres',
    );

    final playbookPath = p.join(playbooksDir, 'database.yml');
    await File(playbookPath).writeAsString(content);
    Console.info('Generated database playbook: $playbookPath');
    return playbookPath;
  }

  Future<String> generateBackupPlaybook(
    DeployConfig config, {
    String backupType = 'full',
  }) async {
    await ensurePlaybooksDir();

    final content = PlaybookTemplates.backup(
      appDir:
          config.ansible?.extraVars['app_dir'] as String? ?? '/opt/dart_cloud',
      composeFile: config.container.composeFile,
      containerRuntime: config.container.runtime,
      projectName: config.container.projectName,
      databaseService: config.container.services['postgres'] ?? 'postgres',
      postgresUser:
          config.ansible?.extraVars['postgres_user'] as String? ?? 'dart_cloud',
      postgresDb:
          config.ansible?.extraVars['postgres_db'] as String? ?? 'dart_cloud',
      backupDir:
          config.ansible?.extraVars['backup_dir'] as String? ??
          '/var/backups/dart_cloud',
      backupRetentionDays:
          config.ansible?.extraVars['backup_retention_days'] as int? ?? 7,
      backupType: backupType,
    );

    final playbookPath = p.join(playbooksDir, 'backup.yml');
    await File(playbookPath).writeAsString(content);
    Console.info('Generated backup playbook: $playbookPath');
    return playbookPath;
  }

  Future<void> cleanup() async {
    final dir = Directory(playbooksDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      Console.info('Cleaned up generated playbooks');
    }
  }

  Future<void> cleanupPlaybook(String playbookPath) async {
    final file = File(playbookPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
