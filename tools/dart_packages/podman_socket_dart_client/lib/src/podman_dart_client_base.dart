import 'dart:async';
import 'dart:convert';

import 'package:podman_socket_dart_client/podman_socket_dart_client.dart';
import 'package:podman_socket_dart_client/src/podman_socket_client.dart';

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

  PodmanClient({String? socketPath})
    : podmanSocketClient = PodmanSocketClient(
        socketPath: socketPath ?? '/run/podman/podman.sock',
      );

  /// Pull an image from registry
  /// Example: pullImage('docker.io/library/alpine:latest')
  Future<Map<String, dynamic>> pullImage(String imageRef) async {
    final response = await podmanSocketClient.post(
      'images/pull?reference=$imageRef',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to pull image: ${response.body}');
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': response.body};
    }
  }

  /// Delete an image by ID or name
  /// Example: deleteImage('alpine:latest')
  Future<void> deleteImage(String imageId) async {
    final response = await podmanSocketClient.delete(
      'images/$imageId',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete image: ${response.body}');
    }
  }

  /// Run a container
  /// Example: runContainer('alpine:latest', cmd: ['echo', 'hello'])
  Future<String> runContainer(
    ContainerSpec containerSpec, {
    bool start = true,
  }) async {
    final createBody = jsonEncode(containerSpec.toJson());
    print(createBody);
    final createResponse = await podmanSocketClient.post(
      'containers/create',
      body: createBody,
    );

    if (createResponse.statusCode != 201) {
      throw Exception('Failed to create container: ${createResponse.body}');
    }
    print(createResponse.body);
    final containerId = jsonDecode(createResponse.body)['Id'];

    if (start) {
      final startResponse = await podmanSocketClient.post(
        'containers/$containerId/start',
      );

      if (startResponse.statusCode != 204 && startResponse.statusCode != 304) {
        throw Exception('Failed to start container: ${startResponse.body}');
      }
    }
    return containerId;
  }

  /// Start a container
  /// Example: startContainer('containerId')
  Future<String> startContainer(
    String containerId,
  ) async {
    final startResponse = await podmanSocketClient.post(
      'containers/$containerId/start',
    );

    if (startResponse.statusCode != 204 && startResponse.statusCode != 304) {
      throw Exception('Failed to start container: ${startResponse.body}');
    }
    print(startResponse.body);

    return startResponse.body;
  }
/// Get container stats
  /// Example: statsContainer('containerId')
  Future<String> statsContainer(
    String containerId,
  ) async {
    final statsResponse = await podmanSocketClient.get(
      'containers/$containerId/stats',
    );

    if (statsResponse.statusCode != 200) {
      throw Exception('Failed to get container stats: ${statsResponse.body}');
    }
    print(statsResponse.body);

    return statsResponse.body;
  }
  /// Get container logs
  /// Example: logsContainer('containerId')
  Future<String> logsContainer(
    String containerId,
  ) async {
    final logsResponse = await podmanSocketClient.get(
      'containers/$containerId/logs',
    );

    if (logsResponse.statusCode != 200) {
      throw Exception('Failed to get container logs: ${logsResponse.body}');
    }
    print(logsResponse.body);

    return logsResponse.body;
  }
  /// Delete a container by ID
  /// Example: deleteContainer(containerId)
  Future<void> deleteContainer(String containerId, {bool force = false}) async {
    final query = force ? '?force=true' : '';
    final response = await podmanSocketClient.delete(
      'containers/$containerId$query',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete container: ${response.body}');
    }
  }
  
}
