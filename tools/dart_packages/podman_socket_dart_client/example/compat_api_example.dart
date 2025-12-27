import 'package:podman_socket_dart_client/podman_socket_dart_client.dart';

void main() async {
  // Initialize Podman client
  final client = PodmanClient(socketPath: '/run/podman/podman.sock');

  print('=== Podman Compat API Examples ===\n');

  // Example 1: Create container using compat API
  print('1. Creating container with compat API...');
  final compatConfig = CompatContainerConfig(
    image: 'docker.io/library/alpine:latest',
    name: 'test-compat-container',
    cmd: ['sleep', '3600'],
    hostname: 'test-host',
    env: ['ENV_VAR=test_value'],
    labels: {'app': 'test', 'version': '1.0'},
    hostConfig: CompatHostConfig(
      autoRemove: true,
      memory: 536870912, // 512MB
      cpuShares: 512,
      binds: ['/tmp:/host-tmp:ro'],
      privileged: false,
      dns: ['8.8.8.8', '8.8.4.4'],
      portBindings: {
        '80/tcp': [
          {'HostPort': '8080'},
        ],
      },
    ),
  );

  print('Config: ${compatConfig.toJson()}\n');

  // Example 2: Check if container exists (libpod API)
  print('2. Checking if container exists...');
  final exists = await client.containerOps.containerExists(
    'test-compat-container',
  );
  print('Container exists: $exists\n');

  // Example 3: Kill containers with filter
  print('3. Killing containers with label filter...');
  final killedContainers = await client.containerOps.killContainersWithFilter(
    filters: {
      'label': ['app=test'],
    },
    signal: 'SIGTERM',
  );
  print('Killed containers: $killedContainers\n');

  // Example 4: Pause container
  print('4. Pausing container...');
  final pauseResponse = await client.containerOps.pauseContainer(
    'test-compat-container',
  );
  print('Pause response status: ${pauseResponse.statusCode}\n');

  // Example 5: Unpause container
  print('5. Unpausing container...');
  final unpauseResponse = await client.containerOps.unpauseContainer(
    'test-compat-container',
  );
  print('Unpause response status: ${unpauseResponse.statusCode}\n');

  // Example 6: Restart container with timeout
  print('6. Restarting container with 10s timeout...');
  final restartResponse = await client.containerOps.restartContainer(
    name: 'test-compat-container',
    timeout: 10,
  );
  print('Restart response status: ${restartResponse.statusCode}\n');

  // Example 7: Stop containers with filter
  print('7. Stopping containers with status filter...');
  final stoppedContainers = await client.containerOps.stopContainersWithFilter(
    filters: {
      'status': ['running'],
    },
    timeout: 5,
  );
  print('Stopped containers: $stoppedContainers\n');

  // Example 8: Wait for container condition
  print('8. Waiting for container to stop...');
  final waitResponse = await client.containerOps.waitContainer(
    name: 'test-compat-container',
    condition: 'stopped',
    interval: '500ms',
  );
  print('Wait response: ${waitResponse.body}\n');

  // Example 9: Pause multiple containers with filter
  print('9. Pausing all containers with specific label...');
  final pausedContainers = await client.containerOps.pauseContainersWithFilter(
    filters: {
      'label': ['version=1.0'],
    },
  );
  print('Paused containers: $pausedContainers\n');

  // Example 10: Restart multiple containers with filter
  print('10. Restarting all paused containers...');
  final restartedContainers = await client.containerOps
      .restartContainersWithFilter(
        filters: {
          'status': ['paused'],
        },
        timeout: 10,
      );
  print('Restarted containers: $restartedContainers\n');

  // Example 11: List containers with filters
  print('11. Listing containers with filters...');
  final listResponse = await client.containerOps.listContainers(
    all: true,
    filters: {
      'name': ['test-'],
      'status': ['running', 'paused'],
    },
  );
  print('List response status: ${listResponse.statusCode}');
  print('Containers: ${listResponse.body}\n');

  print('=== Examples Complete ===');
}
