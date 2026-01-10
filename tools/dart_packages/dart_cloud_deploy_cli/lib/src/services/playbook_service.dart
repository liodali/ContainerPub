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

    final container = config.container;
    final ansible = config.ansible;
    final envFile = config.envFilePath;

    if (container == null) {
      throw Exception('Container configuration is required');
    }

    final content = PlaybookTemplates.backend(
      appDir: ansible?.extraVars['app_dir'] as String? ?? '/opt/dart_cloud',
      composeFile: container.composeFile,
      containerRuntime: container.runtime,
      projectName: container.projectName,
      backendService: container.services['backend'] ?? 'backend-cloud',
      envFile: envFile ?? '.env',
    );

    final playbookPath = p.join(playbooksDir, 'backend.yml');
    await File(playbookPath).writeAsString(content);
    Console.info('Generated backend playbook: $playbookPath');
    return playbookPath;
  }

  Future<String> generateDatabasePlaybook(DeployConfig config) async {
    await ensurePlaybooksDir();

    final container = config.container;
    final ansible = config.ansible;

    if (container == null) {
      throw Exception('Container configuration is required');
    }

    final content = PlaybookTemplates.database(
      appDir: ansible?.extraVars['app_dir'] as String? ?? '/opt/dart_cloud',
      composeFile: container.composeFile,
      containerRuntime: container.runtime,
      projectName: container.projectName,
      databaseService: container.services['postgres'] ?? 'postgres',
      postgresUser:
          ansible?.extraVars['postgres_user'] as String? ?? 'dart_cloud',
      postgresDb: ansible?.extraVars['postgres_db'] as String? ?? 'dart_cloud',
      dataDir:
          ansible?.extraVars['data_dir'] as String? ??
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

    final container = config.container;
    final ansible = config.ansible;

    if (container == null) {
      throw Exception('Container configuration is required');
    }

    final content = PlaybookTemplates.backup(
      appDir: ansible?.extraVars['app_dir'] as String? ?? '/opt/dart_cloud',
      composeFile: container.composeFile,
      containerRuntime: container.runtime,
      projectName: container.projectName,
      databaseService: container.services['postgres'] ?? 'postgres',
      postgresUser:
          ansible?.extraVars['postgres_user'] as String? ?? 'dart_cloud',
      postgresDb: ansible?.extraVars['postgres_db'] as String? ?? 'dart_cloud',
      backupDir:
          ansible?.extraVars['backup_dir'] as String? ??
          '/var/backups/dart_cloud',
      backupRetentionDays:
          ansible?.extraVars['backup_retention_days'] as int? ?? 7,
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

  Future<String> generateContainerRegistryPlaybook(
    DeployConfig config, {
    required String imageName,
    required String imageTag,
  }) async {
    await ensurePlaybooksDir();

    if (config.registry == null) {
      throw Exception('Registry configuration is required');
    }

    final container = config.container;
    final ansible = config.ansible;

    if (container == null) {
      throw Exception('Container configuration is required');
    }

    final content = PlaybookTemplates.containerRegistry(
      appDir: ansible?.extraVars['app_dir'] as String? ?? '/opt/dart_cloud',
      registryUrl: config.registry!.url,
      registryUsername: config.registry!.username,
      registryTokenBase64: config.registry!.tokenBase64,
      imageName: imageName,
      imageTag: imageTag,
      containerRuntime: container.runtime,
      projectName: container.projectName,
      serviceName: container.services['backend'] ?? 'backend-cloud',
      composeFile: container.composeFile,
    );

    final playbookPath = p.join(playbooksDir, 'container_registry.yml');
    await File(playbookPath).writeAsString(content);
    Console.info('Generated container registry playbook: $playbookPath');
    return playbookPath;
  }

  Future<void> cleanupPlaybook(String playbookPath) async {
    final file = File(playbookPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
