import 'dart:convert';
import 'dart:io';

import 'package:podman_socket_dart_client/podman_socket_dart_client.dart';

/// HTTP client that communicates with Podman via Unix socket
class PodmanSocketClient {
  final String socketPath;

  PodmanSocketClient({required this.socketPath});

  /// Make a GET request to Podman API
  Future<PodmanResponse> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _makeRequest('GET', path, headers: headers);
  }

  /// Make a POST request to Podman API
  Future<PodmanResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _makeRequest('POST', path, headers: headers, body: body);
  }

  /// Make a DELETE request to Podman API
  Future<PodmanResponse> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _makeRequest('DELETE', path, headers: headers);
  }

  Future<PodmanResponse> _makeRequest(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      // Connect to Unix socket
      final socket = await Socket.connect(
        InternetAddress(socketPath, type: InternetAddressType.unix),
        0,
      );

      // Send request
      final requestString = _buildHttpRequest(method, path, headers, body);
      socket.add(utf8.encode(requestString));

      // Read response
      final responseBytes = <int>[];
      await for (final chunk in socket) {
        responseBytes.addAll(chunk);
      }

      socket.close();

      final responseString = utf8.decode(responseBytes);
      final response = _parseHttpResponse(responseString);

      return PodmanResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
      );
    } catch (e) {
      throw Exception('Failed to connect to Podman socket: $e');
    }
  }

  String _buildHttpRequest(
    String method,
    String path,
    Map<String, String>? headers,
    Object? body,
  ) {
    final buffer = StringBuffer();
    // Support both compat (/v6.0.0/containers/...) and libpod (/v4.0.0/libpod/...) endpoints
    // Compat endpoints: containers/, images/, networks/, volumes/, etc.
    // Libpod endpoints: libpod/containers/, libpod/images/, etc.
    final apiPath = '/v6.0.0/libpod/$path';
    buffer.writeln('$method $apiPath HTTP/1.1');
    buffer.writeln('Host: localhost');
    buffer.writeln('User-Agent: podman-dart-client/1.0.0');
    buffer.writeln('Content-Type: application/json');

    if (headers != null) {
      headers.forEach((key, value) => buffer.writeln('$key: $value'));
    }

    String? bodyString;
    if (body != null) {
      bodyString = body is String ? body : jsonEncode(body);
      buffer.writeln('Content-Length: ${bodyString.length}');
    }

    buffer.writeln();
    if (bodyString != null) {
      buffer.write(bodyString);
    }

    return buffer.toString();
  }

  ({int statusCode, Map<String, String> headers, String body})
  _parseHttpResponse(String response) {
    final lines = response.split('\r\n');

    // Parse status line
    final statusLine = lines[0];
    final statusCode = int.parse(statusLine.split(' ')[1]);

    // Parse headers
    final headers = <String, String>{};
    int bodyStartIndex = 1;

    for (int i = 1; i < lines.length; i++) {
      if (lines[i].isEmpty) {
        bodyStartIndex = i + 1;
        break;
      }

      final colonIndex = lines[i].indexOf(':');
      if (colonIndex > 0) {
        final key = lines[i].substring(0, colonIndex).trim().toLowerCase();
        final value = lines[i].substring(colonIndex + 1).trim();
        headers[key] = value;
      }
    }

    // Parse body
    final body = lines.skip(bodyStartIndex).join('\r\n');

    return (statusCode: statusCode, headers: headers, body: body);
  }
}
