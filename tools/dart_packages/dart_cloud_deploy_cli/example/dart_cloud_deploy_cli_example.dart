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

  // Example: OpenBao configuration (per-environment)
  final localOpenbaoConfig = OpenBaoConfig(
    address: 'http://localhost:8200',
    tokenManager: '../.openbao/local_token',
    policy: 'dart-cloud-local',
    secretPath: 'secret/data/dart_cloud/local',
    roleId: 'dart-cloud-local',
    roleName: 'stg-local',
  );

  final stagingOpenbaoConfig = OpenBaoConfig(
    address: 'http://localhost:8200',
    tokenManager: '../.openbao/staging_token',
    policy: 'dart-cloud-staging',
    secretPath: 'secret/data/dart_cloud/staging',
    roleId: 'dart-cloud-staging',
    roleName: 'stg-staging',
  );

  print('Local OpenBao address: ${localOpenbaoConfig.address}');
  print('Local secret path: ${localOpenbaoConfig.secretPath}');
  print('Staging policy: ${stagingOpenbaoConfig.policy}');
}
