import 'package:dart_cloud_deploy_cli/dart_cloud_deploy_cli.dart';

void main() async {
  // Example: Load configuration from YAML file
  // final config = await DeployConfig.load('deploy.yaml');
  // print('Loaded config for: ${config.name}');
  // print('Environment: ${config.environment.name}');

  // Example: Create container config programmatically
  final containerConfig = ContainerConfig(
    runtime: 'podman',
    composeFile: 'docker-compose.yml',
    projectName: 'dart_cloud',
    services: {
      'backend': 'dart_cloud_backend',
      'postgres': 'dart_cloud_postgres',
    },
  );

  print('Container runtime: ${containerConfig.runtime}');
  print('Compose command: ${containerConfig.composeCommand}');
  print('Services: ${containerConfig.services}');

  // Example: OpenBao configuration
  final openbaoConfig = OpenBaoConfig(
    address: 'http://localhost:8200',
    secretPath: 'secret/data/dart_cloud/dev',
    tokenPath: '~/.openbao/token',
  );

  print('OpenBao address: ${openbaoConfig.address}');
  print('Secret path: ${openbaoConfig.secretPath}');
}
