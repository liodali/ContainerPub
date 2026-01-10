import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/deploy_config.dart';
import '../utils/console.dart';
import '../utils/config_paths.dart';
import 'venv_service.dart';
import 'playbook_service.dart';

class AnsibleService {
  final AnsibleConfig config;
  final HostConfig host;
  final String workingDirectory;
  final VenvService venvService;
  final PlaybookService playbookService;
  String? _tempInventoryPath;

  AnsibleService({
    required this.config,
    required this.host,
    required this.workingDirectory,
    VenvService? venvService,
    PlaybookService? playbookService,
  }) : venvService = venvService ?? VenvService(venvPath: ConfigPaths.venvDir),
       playbookService =
           playbookService ??
           PlaybookService(workingDirectory: workingDirectory);

  Future<bool> checkAnsible() async {
    return venvService.ansibleInstalled();
  }

  Future<bool> checkEnvironment() async {
    if (!await venvService.checkReady()) {
      Console.error('Deployment environment not initialized');
      Console.info('Run: dart_cloud_deploy init');
      return false;
    }
    return true;
  }

  Future<String> generateInventory() async {
    final buffer = StringBuffer();
    buffer.writeln('[dart_cloud_servers]');
    buffer.write(host.host);
    buffer.write(' ansible_port=${host.port}');
    buffer.write(' ansible_user=${host.user}');

    if (host.sshKeyPath != null) {
      buffer.write(' ansible_ssh_private_key_file=${host.sshKeyPath}');
    }

    buffer.writeln();
    buffer.writeln();
    buffer.writeln('[dart_cloud_servers:vars]');
    buffer.writeln('ansible_python_interpreter=/usr/bin/python3');

    for (final entry in config.extraVars.entries) {
      buffer.writeln('${entry.key}=${entry.value}');
    }

    final tempDir = Directory.systemTemp;
    final inventoryFile = File(
      p.join(
        tempDir.path,
        'dart_cloud_inventory_${DateTime.now().millisecondsSinceEpoch}.ini',
      ),
    );
    await inventoryFile.writeAsString(buffer.toString());
    _tempInventoryPath = inventoryFile.path;

    Console.info('Generated temporary inventory: ${inventoryFile.path}');
    return inventoryFile.path;
  }

  Future<void> cleanup() async {
    if (_tempInventoryPath != null) {
      final file = File(_tempInventoryPath!);
      if (await file.exists()) {
        await file.delete();
        Console.info('Cleaned up temporary inventory');
      }
    }
  }

  String get _inventoryPath => config.inventoryPath ?? _tempInventoryPath ?? '';

  Future<bool> runPlaybook(
    String playbookPath, {
    Map<String, String>? extraVars,
    bool verbose = false,
    List<String>? tags,
    List<String>? skipTags,
  }) async {
    if (!await checkEnvironment()) {
      return false;
    }

    if (_inventoryPath.isEmpty) {
      Console.error('No inventory available. Generate inventory first.');
      return false;
    }

    final args = <String>['-i', _inventoryPath, playbookPath];

    if (verbose) {
      args.add('-vvv');
    }

    if (extraVars != null && extraVars.isNotEmpty) {
      final varsJson = extraVars.entries
          .map((e) => '${e.key}=${e.value}')
          .join(' ');
      args.addAll(['-e', varsJson]);
    }

    if (tags != null && tags.isNotEmpty) {
      args.addAll(['--tags', tags.join(',')]);
    }

    if (skipTags != null && skipTags.isNotEmpty) {
      args.addAll(['--skip-tags', skipTags.join(',')]);
    }

    Console.header('Running Ansible Playbook');
    Console.step('ansible-playbook ${args.join(' ')}');

    final process = await venvService.startAnsiblePlaybook(playbookPath, [
      '-i',
      _inventoryPath,
      ...args.skip(3),
    ], workingDirectory: workingDirectory);

    final exitCode = await process.exitCode;
    return exitCode == 0;
  }

  Future<bool> deployBackend({
    Map<String, String>? extraVars,
    bool verbose = false,
  }) async {
    Console.header('Deploying Backend');
    return runPlaybook(
      config.backendPlaybook,
      extraVars: extraVars,
      verbose: verbose,
    );
  }

  Future<bool> deployDatabase({
    Map<String, String>? extraVars,
    bool verbose = false,
  }) async {
    Console.header('Deploying Database');
    return runPlaybook(
      config.databasePlaybook,
      extraVars: extraVars,
      verbose: verbose,
    );
  }

  Future<bool> runBackup({
    Map<String, String>? extraVars,
    bool verbose = false,
  }) async {
    Console.header('Running Backup');
    return runPlaybook(
      config.backupPlaybook,
      extraVars: extraVars,
      verbose: verbose,
    );
  }

  Future<bool> ping() async {
    if (!await checkEnvironment()) {
      return false;
    }

    if (_inventoryPath.isEmpty) {
      await generateInventory();
    }

    Console.info('Testing connection to ${host.host}...');

    final result = await venvService.runAnsible([
      '-i',
      _inventoryPath,
      'all',
      '-m',
      'ping',
    ], workingDirectory: workingDirectory);

    if (result.exitCode == 0) {
      Console.success('Connection successful');
      return true;
    } else {
      Console.error('Connection failed: ${result.stderr}');
      return false;
    }
  }

  Future<void> cleanupPlaybooks() async {
    await playbookService.cleanup();
  }
}
