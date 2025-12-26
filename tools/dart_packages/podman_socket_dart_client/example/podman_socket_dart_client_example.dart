import 'package:podman_socket_dart_client/podman_socket_dart_client.dart';

/// Example usage
void main() async {
  final client = PodmanClient(
    socketPath:
        '/var/folders/yz/57p58qc10vqdt6d3j66wkjp80000gn/T/podman/podman-machine-default-api.sock',
  );

  try {
    // Pull an image
    print('Pulling alpine image...');
    await client.pullImage('docker.io/library/alpine:latest');
    print('Image pulled successfully');
    // await Future.delayed(const Duration(seconds: 2));

    // Run a container
    print('Running container...');
    final containerId = await client.runContainer(
      ContainerSpec(
        image: 'alpine:latest',
        cmd: ['echo', 'Hello from Podman! time: ${DateTime.now()}'],
        name: 'my-test-container',
      ),
    );
    print('Container created: $containerId');
    // await Future.delayed(const Duration(seconds: 5));

    // Delete the container
    print('Deleting container...');
    await client.deleteContainer(containerId);
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
