import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:dart_cloud_backend/router.dart';
import 'package:database/database.dart';
import 'package:dart_cloud_backend/config/config.dart';

void main() async {
  // Load configuration
  await Config.load();

  // Initialize database
  await Database.initialize(Config.databaseUrl);

  // Create router
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(createRouter());

  // Start server
  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    Config.port,
  );

  print(
    '🚀 Dart Cloud Backend running on http://${server.address.host}:${server.port}',
  );
  print('📊 Function storage: ${Config.functionsDir}');
  print('🔐 Database: ${Config.databaseUrl}');
}

Middleware _corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }

      final response = await handler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

final _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};
