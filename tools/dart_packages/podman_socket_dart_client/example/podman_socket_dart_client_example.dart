import 'package:podman_socket_dart_client/podman_socket_dart_client.dart';

/// Example usage
void main() async {
  final String sock = const String.fromEnvironment('PODMAN_SOCKET_PATH', defaultValue: '/run/podman/podman.sock');
  final client = PodmanClient(
    socketPath: sock,
  );

  try {
    // Pull an image
    print('Pulling alpine image...');
    final exist = await client.imagesOps.existImage('docker.io/library/alpine:latest');
    if (!exist) {
      await client.imagesOps.pullImage('docker.io/library/alpine:latest');
    }else {
      print('Image already exists');
    }
    print('Image pulled successfully');
    // await Future.delayed(const Duration(seconds: 2));

    // Run a container
    print('Running container...');
    final containerId = await client.containerOps.runContainer(
      CompatContainerConfig(
        image: 'alpine:latest',
        cmd: ['echo', 'Hello from Podman! time: ${DateTime.now()}'],
        name: 'my-test-container',
      ),
    );
    print('Container created: $containerId');
    // await Future.delayed(const Duration(seconds: 5));

    // Delete the container
    print('Deleting container...');
    await client.containerOps.deleteContainer(containerId);
    print('Container deleted');

    // Delete the image
    print('Deleting image...');
    // await client.deleteImage('alpine:latest');
    // print('Image deleted');
  } catch (e, trace) {
    print('Error: $e');
    print(trace);
  }
}
