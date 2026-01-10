import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dart_cloud_deploy_cli/src/commands/config_command.dart';
import 'package:dart_cloud_deploy_cli/src/commands/deploy_local_command.dart';
import 'package:dart_cloud_deploy_cli/src/commands/deploy_dev_command.dart';
import 'package:dart_cloud_deploy_cli/src/commands/secrets_command.dart';
import 'package:dart_cloud_deploy_cli/src/commands/show_config_command.dart';
import 'package:dart_cloud_deploy_cli/src/commands/init_command.dart';
import 'package:dart_cloud_deploy_cli/src/commands/build_push_command.dart';
import 'package:dart_cloud_deploy_cli/src/utils/console.dart';

void main(List<String> arguments) async {
  final runner =
      CommandRunner<void>(
          'dart_cloud_deploy',
          'Dart Cloud Deployment CLI - Manage dev and production deployments',
        )
        ..addCommand(InitCommand())
        ..addCommand(ConfigCommand())
        ..addCommand(DeployLocalCommand())
        ..addCommand(DeployDevCommand())
        ..addCommand(BuildPushCommand())
        ..addCommand(SecretsCommand())
        ..addCommand(ShowConfigCommand());

  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    Console.error(e.message);
    print(e.usage);
    exit(64);
  } catch (e) {
    Console.error('Error: $e');
    exit(1);
  }
}
