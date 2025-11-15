import 'dart:convert';
import 'dart:io';

class CloudRequest {
  final String method;
  final String path;
  final Map<String, String> headers;
  final Map<String, String> query;
  final dynamic body;
  final HttpRequest? raw;

  CloudRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.query,
    this.body,
    this.raw,
  });
}

class CloudResponse {
  final int statusCode;
  final Map<String, String> headers;
  final dynamic body;

  CloudResponse({
    this.statusCode = 200,
    Map<String, String>? headers,
    this.body,
  }) : headers = headers ?? {};

  void writeTo(HttpResponse res) {
    headers.forEach((k, v) => res.headers.set(k, v));
    if (body == null) {
      res.statusCode = statusCode;
      res.close();
      return;
    }
    if (body is List<int>) {
      res.statusCode = statusCode;
      res.add(body as List<int>);
      res.close();
      return;
    }
    if (body is String) {
      res.statusCode = statusCode;
      res.headers.set('content-type', 'text/plain; charset=utf-8');
      res.write(body as String);
      res.close();
      return;
    }
    res.statusCode = statusCode;
    res.headers.set('content-type', 'application/json; charset=utf-8');
    res.write(jsonEncode(body));
    res.close();
  }

  static CloudResponse json(
    Object body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return CloudResponse(statusCode: statusCode, headers: headers, body: body);
  }

  static CloudResponse text(
    String body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return CloudResponse(statusCode: statusCode, headers: headers, body: body);
  }
}

abstract class CloudDartFunction {
  Future<CloudResponse> handle(CloudRequest request);

  Future<HttpServer> serve({int port = 8080, InternetAddress? address}) async {
    final addr = address ?? InternetAddress.anyIPv4;
    final server = await HttpServer.bind(addr, port);
    server.listen((HttpRequest req) async {
      try {
        final cloudReq = await _parseRequest(req);
        final resp = await handle(cloudReq);
        resp.headers['x-powered-by'] ??= 'dart_cloud_function';
        resp.writeTo(req.response);
      } catch (e) {
        req.response.statusCode = 500;
        req.response.headers.set(
          'content-type',
          'application/json; charset=utf-8',
        );
        req.response.write(
          jsonEncode({'error': 'internal_error', 'message': e.toString()}),
        );
        req.response.close();
      }
    });
    return server;
  }

  Future<CloudRequest> _parseRequest(HttpRequest req) async {
    dynamic body;
    if (req.method != 'GET' && req.method != 'HEAD') {
      final bytes = await req.fold<List<int>>(<int>[], (p, e) {
        p.addAll(e);
        return p;
      });
      final contentType = req.headers.contentType?.mimeType ?? '';
      if (contentType == 'application/json') {
        try {
          body = jsonDecode(utf8.decode(bytes));
        } catch (_) {
          body = utf8.decode(bytes);
        }
      } else {
        body = utf8.decode(bytes);
      }
    }
    final headerMapEntry = <MapEntry<String, String>>[];
    req.headers.forEach((k, v) => headerMapEntry.add(MapEntry(k, v.join(','))));
    return CloudRequest(
      method: req.method,
      path: req.uri.path,
      headers: Map<String, String>.fromEntries(
        headerMapEntry,
      ),
      query: req.uri.queryParameters,
      body: body,
      raw: req,
    );
  }
}
