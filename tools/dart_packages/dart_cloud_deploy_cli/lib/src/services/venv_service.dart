import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/console.dart';

class VenvService {
  final String venvPath;

  VenvService({String? venvPath})
    : venvPath = venvPath ?? p.join(Directory.current.path, '.venv');

  String get _pythonPath => Platform.isWindows
      ? p.join(venvPath, 'Scripts', 'python.exe')
      : p.join(venvPath, 'bin', 'python');

  String get _pipPath => Platform.isWindows
      ? p.join(venvPath, 'Scripts', 'pip.exe')
      : p.join(venvPath, 'bin', 'pip');

  String get _ansiblePath => Platform.isWindows
      ? p.join(venvPath, 'Scripts', 'ansible.exe')
      : p.join(venvPath, 'bin', 'ansible');

  String get _ansiblePlaybookPath => Platform.isWindows
      ? p.join(venvPath, 'Scripts', 'ansible-playbook.exe')
      : p.join(venvPath, 'bin', 'ansible-playbook');

  String get activateCommand => Platform.isWindows
      ? p.join(venvPath, 'Scripts', 'activate.bat')
      : 'source ${p.join(venvPath, 'bin', 'activate')}';

  Future<bool> pythonExists() async {
    try {
      final result = await Process.run('python3', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      try {
        final result = await Process.run('python', ['--version']);
        return result.exitCode == 0;
      } catch (_) {
        return false;
      }
    }
  }

  Future<String?> getPythonCommand() async {
    try {
      final result = await Process.run('python3', ['--version']);
      if (result.exitCode == 0) return 'python3';
    } catch (_) {}

    try {
      final result = await Process.run('python', ['--version']);
      if (result.exitCode == 0) return 'python';
    } catch (_) {}

    return null;
  }

  Future<bool> venvExists() async {
    final pythonFile = File(_pythonPath);
    return pythonFile.existsSync();
  }

  Future<bool> ansibleInstalled() async {
    final ansibleFile = File(_ansiblePath);
    return ansibleFile.existsSync();
  }

  Future<bool> createVenv() async {
    Console.info('Creating Python virtual environment at $venvPath...');

    final pythonCmd = await getPythonCommand();
    if (pythonCmd == null) {
      Console.error('Python not found. Please install Python 3.8+');
      return false;
    }

    try {
      final result = await Process.run(pythonCmd, [
        '-m',
        'venv',
        venvPath,
      ], runInShell: true);

      if (result.exitCode == 0) {
        Console.success('Virtual environment created');
        return true;
      } else {
        Console.error('Failed to create venv: ${result.stderr}');
        return false;
      }
    } catch (e) {
      Console.error('Failed to create venv: $e');
      return false;
    }
  }

  Future<bool> installAnsible() async {
    Console.info('Installing Ansible in virtual environment...');

    if (!await venvExists()) {
      Console.error('Virtual environment not found. Run init first.');
      return false;
    }

    try {
      // Upgrade pip first
      Console.step('Upgrading pip...');
      var result = await Process.run(_pythonPath, [
        '-m',
        'pip',
        'install',
        '--upgrade',
        'pip',
      ], runInShell: true);

      if (result.exitCode != 0) {
        Console.warning('Failed to upgrade pip: ${result.stderr}');
      }

      // Install ansible
      Console.step('Installing ansible...');
      result = await Process.run(_pipPath, [
        'install',
        'ansible',
      ], runInShell: true);

      if (result.exitCode == 0) {
        Console.success('Ansible installed successfully');
        return true;
      } else {
        Console.error('Failed to install ansible: ${result.stderr}');
        return false;
      }
    } catch (e) {
      Console.error('Failed to install ansible: $e');
      return false;
    }
  }

  Future<bool> installAnsibleCollections() async {
    Console.info('Installing required Ansible collections...');

    if (!await ansibleInstalled()) {
      Console.error('Ansible not installed. Run init first.');
      return false;
    }

    final collections = ['ansible.posix', 'community.general'];

    for (final collection in collections) {
      Console.step('Installing $collection...');
      try {
        final result = await Process.run(
          p.join(venvPath, 'bin', 'ansible-galaxy'),
          ['collection', 'install', collection],
          runInShell: true,
        );

        if (result.exitCode != 0) {
          Console.warning('Failed to install $collection: ${result.stderr}');
        }
      } catch (e) {
        Console.warning('Failed to install $collection: $e');
      }
    }

    Console.success('Ansible collections installed');
    return true;
  }

  Future<bool> initialize() async {
    Console.header('Initializing Deployment Environment');

    // Check Python
    Console.info('Checking Python installation...');
    if (!await pythonExists()) {
      Console.error('Python not found. Please install Python 3.8+');
      Console.info('  macOS: brew install python3');
      Console.info('  Ubuntu: sudo apt install python3 python3-venv');
      return false;
    }
    Console.success('Python found');

    // Create venv if needed
    if (!await venvExists()) {
      if (!await createVenv()) {
        return false;
      }
    } else {
      Console.success('Virtual environment already exists');
    }

    // Install ansible if needed
    if (!await ansibleInstalled()) {
      if (!await installAnsible()) {
        return false;
      }
    } else {
      Console.success('Ansible already installed');
    }

    // Install collections
    await installAnsibleCollections();

    Console.header('Initialization Complete');
    Console.info('Virtual environment: $venvPath');
    Console.info('Ansible: $_ansiblePath');
    Console.info('');
    Console.info('To activate manually:');
    Console.step('  $activateCommand');

    return true;
  }

  Future<bool> checkReady() async {
    if (!await venvExists()) {
      Console.error('Virtual environment not found at $venvPath');
      Console.info('Run: dart_cloud_deploy init');
      return false;
    }

    if (!await ansibleInstalled()) {
      Console.error('Ansible not installed in virtual environment');
      Console.info('Run: dart_cloud_deploy init');
      return false;
    }

    return true;
  }

  Future<ProcessResult> runAnsiblePlaybook(
    String playbookPath,
    List<String> args, {
    String? workingDirectory,
  }) async {
    if (!await checkReady()) {
      throw Exception('Environment not ready. Run: dart_cloud_deploy init');
    }

    return Process.run(
      _ansiblePlaybookPath,
      [playbookPath, ...args],
      workingDirectory: workingDirectory,
      runInShell: true,
    );
  }

  Future<Process> startAnsiblePlaybook(
    String playbookPath,
    List<String> args, {
    String? workingDirectory,
  }) async {
    if (!await checkReady()) {
      throw Exception('Environment not ready. Run: dart_cloud_deploy init');
    }

    return Process.start(
      _ansiblePlaybookPath,
      [playbookPath, ...args],
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.inheritStdio,
    );
  }

  Future<ProcessResult> runAnsible(
    List<String> args, {
    String? workingDirectory,
  }) async {
    if (!await checkReady()) {
      throw Exception('Environment not ready. Run: dart_cloud_deploy init');
    }

    return Process.run(
      _ansiblePath,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
  }

  Future<String?> getAnsibleVersion() async {
    if (!await ansibleInstalled()) return null;

    try {
      final result = await Process.run(_ansiblePath, ['--version']);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final firstLine = output.split('\n').first;
        return firstLine;
      }
    } catch (_) {}
    return null;
  }
}
