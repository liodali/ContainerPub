import 'package:args/command_runner.dart';
import '../services/venv_service.dart';
import '../utils/console.dart';
import '../utils/config_paths.dart';
import '../utils/venv_detector.dart';

class InitCommand extends Command<void> {
  @override
  final String name = 'init';

  @override
  final String description =
      'Initialize deployment environment (Python venv + Ansible)';

  InitCommand() {
    argParser
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
    final force = argResults!['force'] as bool;
    final skipCollections = argResults!['skip-collections'] as bool;

    if (force) {
      Console.warning('Force mode: will reinstall everything');
    }

    Console.header('Initializing Deployment Environment');

    // Ensure config directory exists
    Console.info('Creating config directory...');
    await ConfigPaths.ensureAllDirsExist();
    Console.success('Config directory: ${ConfigPaths.configDir}');

    // Detect venv location
    Console.info('Detecting Python virtual environment location...');
    final venvLocation = await VenvDetector.detectVenvLocation();

    if (venvLocation.exists && !force) {
      Console.success(
        'Using existing virtual environment in ${venvLocation.description}: ${venvLocation.path}',
      );
    } else if (venvLocation.isParent && venvLocation.exists) {
      Console.success(
        'Found virtual environment in parent directory: ${venvLocation.path}',
      );
    } else {
      Console.info(
        'Virtual environment will be created in ${venvLocation.description}: ${venvLocation.path}',
      );
    }

    final venvService = VenvService(venvPath: venvLocation.path);

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
    Console.keyValue('Config Directory', ConfigPaths.configDir);
    Console.keyValue('Virtual Environment', venvLocation.path);
    Console.keyValue('Venv Location', venvLocation.description);
    Console.keyValue(
      'Ansible',
      await venvService.getAnsibleVersion() ?? 'installed',
    );
    Console.divider();
    Console.info('');
    Console.info('You can now use:');
    Console.step('  dart_cloud_deploy deploy-dev    # Deploy to remote server');
    Console.step('  dart_cloud_deploy deploy-local  # Deploy locally');
    Console.step('  dart_cloud_deploy prune         # Clean config directory');
    Console.info('');
    Console.info('To activate venv manually:');
    Console.step('  ${venvService.activateCommand}');
  }
}
