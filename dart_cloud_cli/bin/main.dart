import 'dart:io';
import 'package:args/args.dart';
import 'package:dart_cloud_cli/commands/deploy_command.dart';
import 'package:dart_cloud_cli/commands/list_command.dart';
import 'package:dart_cloud_cli/commands/logs_command.dart';
import 'package:dart_cloud_cli/commands/delete_command.dart';
import 'package:dart_cloud_cli/commands/login_command.dart';
import 'package:dart_cloud_cli/commands/logout_command.dart';
import 'package:dart_cloud_cli/commands/invoke_command.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Show version');

  if (arguments.isEmpty) {
    printUsage();
    exit(0);
  }
  final commandParsed = parser.parse(arguments);
  final command = commandParsed.command?.name;;
  final commandArgs = commandParsed.arguments;

  try {
    switch (command) {
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
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

void printUsage() {
  print('''
Dart Cloud CLI - Deploy and manage Dart serverless functions

Usage: dart_cloud <command> [arguments]

Available commands:
  login              Authenticate with the Dart Cloud platform
  logout             Clear authentication token and logout
  deploy <path>      Deploy a Dart function from the specified path
  list               List all deployed functions
  logs <id>          View logs for a specific function
  invoke <id>        Invoke a deployed function
  delete <id>        Delete a deployed function
  help               Show this help message
  version            Show version information

Examples:
  dart_cloud login
  dart_cloud logout
  dart_cloud deploy ./my_function
  dart_cloud list
  dart_cloud logs my-function-id
  dart_cloud invoke my-function-id --data '{"key": "value"}'
  dart_cloud delete my-function-id

For more information, visit: https://github.com/yourusername/ContainerPub
''');
}
