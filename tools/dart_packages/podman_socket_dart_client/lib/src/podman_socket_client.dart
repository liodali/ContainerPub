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

      final response = _parseHttpResponseBytes(responseBytes);

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
  _parseHttpResponseBytes(List<int> responseBytes) {
    // Find the end of headers (\r\n\r\n)
    int headerEnd = -1;
    for (int i = 0; i < responseBytes.length - 3; i++) {
      if (responseBytes[i] == 13 &&
          responseBytes[i + 1] == 10 &&
          responseBytes[i + 2] == 13 &&
          responseBytes[i + 3] == 10) {
        headerEnd = i;
        break;
      }
    }

    if (headerEnd == -1) {
      throw Exception('Invalid HTTP response: no header end found');
    }

    // Parse headers
    final headerBytes = responseBytes.sublist(0, headerEnd);
    final headerString = utf8.decode(headerBytes);
    final headerLines = headerString.split('\r\n');

    // Parse status line
    final statusLine = headerLines[0];
    final statusCode = int.parse(statusLine.split(' ')[1]);

    // Parse header fields
    final headers = <String, String>{};
    for (int i = 1; i < headerLines.length; i++) {
      final colonIndex = headerLines[i].indexOf(':');
      if (colonIndex > 0) {
        final key = headerLines[i]
            .substring(0, colonIndex)
            .trim()
            .toLowerCase();
        final value = headerLines[i].substring(colonIndex + 1).trim();
        headers[key] = value;
      }
    }

    // Extract body bytes (after \r\n\r\n)
    final bodyBytes = responseBytes.sublist(headerEnd + 4);

    // Handle chunked transfer encoding
    String body;
    if (headers['transfer-encoding']?.toLowerCase() == 'chunked') {
      final decodedBytes = _decodeChunkedBodyBytes(bodyBytes);
      body = utf8.decode(decodedBytes);
    } else {
      body = utf8.decode(bodyBytes);
    }

    return (statusCode: statusCode, headers: headers, body: body);
  }

  List<int> _decodeChunkedBodyBytes(List<int> chunkedBytes) {
    final result = <int>[];
    int position = 0;

    while (position < chunkedBytes.length) {
      // Find the end of the chunk size line (\r\n)
      int chunkSizeEnd = -1;
      for (int i = position; i < chunkedBytes.length - 1; i++) {
        if (chunkedBytes[i] == 13 && chunkedBytes[i + 1] == 10) {
          chunkSizeEnd = i;
          break;
        }
      }

      if (chunkSizeEnd == -1) break;

      // Extract chunk size line
      final chunkSizeBytes = chunkedBytes.sublist(position, chunkSizeEnd);
      final chunkSizeLine = utf8.decode(chunkSizeBytes).trim();

      // Skip empty lines
      if (chunkSizeLine.isEmpty) {
        position = chunkSizeEnd + 2;
        continue;
      }

      // Parse chunk size (hex)
      int chunkSize;
      try {
        chunkSize = int.parse(chunkSizeLine, radix: 16);
      } catch (e) {
        // If we can't parse as hex, skip this line
        position = chunkSizeEnd + 2;
        continue;
      }

      // If chunk size is 0, we've reached the end
      if (chunkSize == 0) {
        break;
      }

      // Move position to start of chunk data (after \r\n)
      position = chunkSizeEnd + 2;

      // Extract chunk data bytes
      if (position + chunkSize <= chunkedBytes.length) {
        result.addAll(chunkedBytes.sublist(position, position + chunkSize));
        position += chunkSize;

        // Skip trailing \r\n after chunk data
        if (position + 1 < chunkedBytes.length &&
            chunkedBytes[position] == 13 &&
            chunkedBytes[position + 1] == 10) {
          position += 2;
        }
      } else {
        // Not enough data, break
        break;
      }
    }

    return result;
  }
}
