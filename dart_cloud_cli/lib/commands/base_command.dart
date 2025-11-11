import 'package:dart_cloud_cli/config/config.dart';

class BaseCommand {
  BaseCommand() : _config = Config();
  BaseCommand.local() : _config = Config();
  final Config _config;

  Config get config => _config;
}
