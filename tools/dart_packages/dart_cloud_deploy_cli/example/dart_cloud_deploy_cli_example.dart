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

  // Example: OpenBao configuration with per-environment token managers
  final openbaoConfig = OpenBaoConfig(
    address: 'http://localhost:8200',
    local: TokenManagerConfig(
      tokenManager: '../.openbao/local_token',
      policy: 'dart-cloud-local',
      secretPath: 'secret/data/dart_cloud/local',
    ),
    staging: TokenManagerConfig(
      tokenManager: '../.openbao/staging_token',
      policy: 'dart-cloud-staging',
      secretPath: 'secret/data/dart_cloud/staging',
    ),
    production: TokenManagerConfig(
      tokenManager: '../.openbao/prod_token',
      policy: 'dart-cloud-production',
      secretPath: 'secret/data/dart_cloud/production',
    ),
  );

  print('OpenBao address: ${openbaoConfig.address}');
  print('Local secret path: ${openbaoConfig.local?.secretPath}');
  print('Staging policy: ${openbaoConfig.staging?.policy}');
}
