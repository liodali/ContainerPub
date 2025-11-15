import 'dart:convert';
import 'dart:io';

import 'package:dart_cloud_function/src/dart_function_models.dart'
    show CloudResponse, CloudRequest;

abstract class CloudDartFunction {
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  });

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
