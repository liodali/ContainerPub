import 'package:args/command_runner.dart';
import '../services/venv_service.dart';
import '../utils/console.dart';

class InitCommand extends Command<void> {
  @override
  final String name = 'init';

  @override
  final String description =
      'Initialize deployment environment (Python venv + Ansible)';

  InitCommand() {
    argParser
      ..addOption(
        'venv-path',
        help: 'Path for Python virtual environment',
        defaultsTo: '.venv',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force reinstall even if already exists',
        defaultsTo: false,
      )
      ..addFlag(
        'skip-collections',
        help: 'Skip installing Ansible collections',
        defaultsTo: false,
      );
  }

  @override
  Future<void> run() async {
    final venvPath = argResults!['venv-path'] as String;
    final force = argResults!['force'] as bool;
    final skipCollections = argResults!['skip-collections'] as bool;

    final venvService = VenvService(venvPath: venvPath);

    if (force) {
      Console.warning('Force mode: will reinstall everything');
    }

    Console.header('Initializing Deployment Environment');

    // Check Python
    Console.info('Checking Python installation...');
    if (!await venvService.pythonExists()) {
      Console.error('Python not found. Please install Python 3.8+');
      Console.info('');
      Console.info('Installation instructions:');
      Console.step('  macOS: brew install python3');
      Console.step('  Ubuntu/Debian: sudo apt install python3 python3-venv');
      Console.step('  Fedora: sudo dnf install python3');
      Console.step('  Windows: Download from https://python.org');
      return;
    }

    final pythonCmd = await venvService.getPythonCommand();
    Console.success('Python found: $pythonCmd');

    // Create venv
    final venvExists = await venvService.venvExists();
    if (!venvExists || force) {
      Console.info('Creating Python virtual environment...');
      if (!await venvService.createVenv()) {
        Console.error('Failed to create virtual environment');
        return;
      }
    } else {
      Console.success('Virtual environment already exists');
    }

    // Install ansible
    final ansibleInstalled = await venvService.ansibleInstalled();
    if (!ansibleInstalled || force) {
      Console.info('Installing Ansible...');
      if (!await venvService.installAnsible()) {
        Console.error('Failed to install Ansible');
        return;
      }
    } else {
      final version = await venvService.getAnsibleVersion();
      Console.success('Ansible already installed: $version');
    }

    // Install collections
    if (!skipCollections) {
      await venvService.installAnsibleCollections();
    }

    // Print summary
    Console.header('Initialization Complete');
    Console.divider();
    Console.keyValue('Virtual Environment', venvPath);
    Console.keyValue(
      'Ansible',
      await venvService.getAnsibleVersion() ?? 'installed',
    );
    Console.divider();
    Console.info('');
    Console.info('You can now use:');
    Console.step('  dart_cloud_deploy deploy-dev    # Deploy to remote server');
    Console.step('  dart_cloud_deploy deploy-local  # Deploy locally');
    Console.info('');
    Console.info('To activate venv manually:');
    Console.step('  ${venvService.activateCommand}');
  }
}
