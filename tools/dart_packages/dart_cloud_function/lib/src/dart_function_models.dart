import 'dart:convert';
import 'dart:io';

class CloudRequest {
  final String method;
  final String path;
  final Map<String, String> headers;
  final Map<String, String> query;
  final dynamic body;
  final dynamic raw;

  CloudRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.query,
    this.body,
    this.raw,
  });
  CloudRequest.fromJson(Map<String, dynamic> json, this.raw)
    : method = json['method'] as String,
      path = json['path'] as String,
      headers = Map<String, String>.from(json['headers'] as Map),
      query = Map<String, String>.from(json['query'] as Map),
      body = json['body'];

  CloudRequest copyWith({
    String? method,
    String? path,
    Map<String, String>? headers,
    Map<String, String>? query,
    dynamic body,
    dynamic raw,
  }) {
    return CloudRequest(
      method: method ?? this.method,
      path: path ?? this.path,
      headers: headers ?? this.headers,
      query: query ?? this.query,
      body: body ?? this.body,
      raw: raw ?? this.raw,
    );
  }
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
