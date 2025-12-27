import 'dart:convert';

import 'package:podman_socket_dart_client/src/podman_socket_client.dart';

/// Container operations API (compat and libpod endpoints)
class ImagesOperation {
  final PodmanSocketClient _client;

  ImagesOperation(this._client);

  /// Pull an image from registry
  /// Example: pullImage('docker.io/library/alpine:latest')
  Future<bool> existImage(String imageRef) async {
    final response = await _client.get(
      'images/$imageRef/exists',
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to check exists image: ${response.body}');
    }

    try {
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Pull an image from registry
  /// Example: pullImage('docker.io/library/alpine:latest')
  Future<Map<String, dynamic>> pullImage(String imageRef) async {
    final response = await _client.post(
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
    final response = await _client.delete(
      'images/$imageId',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete image: ${response.body}');
    }
  }
}
