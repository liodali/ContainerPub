import 'dart:io';
import 'package:args/args.dart';
import 'package:dart_cloud_cli/commands/deploy_command.dart';
import 'package:dart_cloud_cli/commands/list_command.dart';
import 'package:dart_cloud_cli/commands/logs_command.dart';
import 'package:dart_cloud_cli/commands/delete_command.dart';
import 'package:dart_cloud_cli/commands/login_command.dart';
import 'package:dart_cloud_cli/commands/logout_command.dart';
import 'package:dart_cloud_cli/commands/invoke_command.dart';
import 'package:dart_cloud_cli/commands/init_command.dart';
import 'package:dart_cloud_cli/commands/status_command.dart';
import 'package:dart_cloud_cli/commands/apikey_command.dart';
import 'package:dart_cloud_cli/commands/rollback_command.dart';
import 'package:dart_cloud_cli/common/args_parsers.dart';
import 'package:dart_cloud_cli/services/cache.dart' show AuthCache;

void main(List<String> arguments) async {
  print('welcome to dart_cloud_cli');
  await AuthCache.init();
  final loginArgs = ArgParser()
    ..addOption('email', abbr: 'e', help: 'Email address')
    ..addOption('password', abbr: 'p', help: 'Password', hide: true);



  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Show version')
    ..addCommand('init')
    ..addCommand('status')
    ..addCommand('login', loginArgs)
    ..addCommand('logout')
    ..addCommand(
      'deploy',
      ArgParser()
        ..addFlag(
          'force',
          abbr: 'f',
          help: 'Force deployment even if no changes detected',
        ),
    )
    ..addCommand('list')
    ..addCommand('logs')
    ..addCommand('delete')
    ..addCommand('invoke', invokeArgs)
    ..addCommand('apikey', apiKeyParser)
    ..addCommand('rollback');

  if (arguments.isEmpty) {
    printUsage();
    exit(0);
  }
  final commandParsed = parser.parse(arguments);
  final command = commandParsed.command?.name;
  final commandArgs = commandParsed.command?.arguments ?? [];
  try {
    switch (command) {
      case 'init':
        await InitCommand().execute(commandArgs);
        break;
      case 'status':
        await StatusCommand().execute(commandArgs);
        break;
      case 'login':
        await LoginCommand().execute(commandArgs);
        break;
      case 'logout':
        await LogoutCommand().execute(commandArgs);
        break;
      case 'deploy':
        await DeployCommand().execute(commandArgs);
        break;
      case 'list':
        await ListCommand().execute(commandArgs);
        break;
      case 'logs':
        await LogsCommand().execute(commandArgs);
        break;
      case 'delete':
        await DeleteCommand().execute(commandArgs);
        break;
      case 'invoke':
        await InvokeCommand().execute(commandArgs);
        break;
      case 'apikey':
        await ApiKeyCommand().execute(commandArgs);
        break;
      case 'rollback':
        await RollbackCommand().execute(commandArgs);
        break;
      case 'help':
      case '--help':
      case '-h':
        printUsage();
        break;
      case 'version':
      case '--version':
      case '-v':
        print('dart_cloud_cli version 1.0.0');
        break;
      default:
        print('Unknown command: $command');
        printUsage();
        exit(1);
    }
    await AuthCache.close();
  } catch (e) {
    print('Error: $e');
    await AuthCache.close();
    exit(1);
  }
}

void printUsage() {
  print('''
Dart Cloud CLI - Deploy and manage Dart serverless functions

Usage: dart_cloud_cli <command> [arguments]

Available commands:
  init               Initialize function config in .dart_tool directory
  status             Show function status and deployment hash
  login              Authenticate with the Dart Cloud platform
  logout             Clear authentication token and logout
  deploy [path]      Deploy a Dart function (use -f to force deploy)
  list               List all deployed functions
  logs <id>          View logs for a specific function
  invoke <id>        Invoke a deployed function
  delete <id>        Delete a deployed function
  apikey             Manage API keys for function signing
  rollback           Rollback function to a previous version
  help               Show this help message
  version            Show version information

Examples:
  dart_cloud_cli init
  dart_cloud_cli status
  dart_cloud_cli login
  dart_cloud_cli logout
  dart_cloud_cli deploy ./my_function
  dart_cloud_cli deploy -f              # Force deploy even if no changes
  dart_cloud_cli list
  dart_cloud_cli logs my-function-id
  dart_cloud_cli invoke my-function-id --data '{"key": "value"}'
  dart_cloud_cli delete my-function-id
  dart_cloud_cli apikey generate --validity 1d
  dart_cloud_cli apikey info
  dart_cloud_cli apikey revoke
  dart_cloud_cli apikey list
  dart_cloud_cli apikey roll --key-id <uuid>
  dart_cloud_cli rollback <function-id>          # Interactive version selection
  dart_cloud_cli rollback <function-id> <version> # Direct rollback

For more information, visit: https://github.com/yourusername/ContainerPub
''');
}
