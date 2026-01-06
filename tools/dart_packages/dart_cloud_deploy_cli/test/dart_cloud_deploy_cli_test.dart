import 'package:dart_cloud_deploy_cli/dart_cloud_deploy_cli.dart';
import 'package:test/test.dart';

void main() {
  group('DeployConfig', () {
    test('Environment enum parsing', () {
      expect(Environment.local.name, equals('local'));
      expect(Environment.dev.name, equals('dev'));
      expect(Environment.production.name, equals('production'));
    });

    test('ContainerConfig defaults', () {
      final config = ContainerConfig(
        composeFile: 'docker-compose.yml',
        services: {'backend': 'dart_cloud_backend'},
      );
      expect(config.runtime, equals('podman'));
      expect(config.projectName, equals('dart_cloud'));
      expect(config.composeCommand, equals('podman-compose'));
    });

    test('HostConfig from map', () {
      final map = {'host': 'example.com', 'port': 22, 'user': 'deploy'};
      final host = HostConfig.fromMap(map);
      expect(host.host, equals('example.com'));
      expect(host.port, equals(22));
      expect(host.user, equals('deploy'));
    });
  });
}
