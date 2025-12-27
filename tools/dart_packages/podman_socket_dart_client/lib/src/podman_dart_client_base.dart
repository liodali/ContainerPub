import 'package:podman_socket_dart_client/podman_socket_dart_client.dart';
import 'package:podman_socket_dart_client/src/api/images_operation.dart';

/// Response model for API calls
class PodmanResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  PodmanResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });
}

/// Podman client for managing containers and images
class PodmanClient {
  final PodmanSocketClient podmanSocketClient;
  late final ContainerOperations containerOps;
  late final ImagesOperation imagesOps;

  PodmanClient({String? socketPath})
    : podmanSocketClient = PodmanSocketClient(
        socketPath: socketPath ?? '/run/podman/podman.sock',
      ) {
    containerOps = ContainerOperations(podmanSocketClient);
    imagesOps = ImagesOperation(podmanSocketClient);
  }
}
