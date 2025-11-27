import 'dart:io';
import 'package:dart_cloud_backend/services/s3_service.dart' show S3Service;
import 'package:dart_cloud_backend/services/token_service.dart';
import 'package:s3_client_dart/s3_client_dart.dart' show S3Configuration;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:dart_cloud_backend/router.dart';
import 'package:database/database.dart';
import 'package:dart_cloud_backend/configuration/config.dart';

void main() async {
  // Load configuration
  await Config.load();
  await TokenService.instance.initialize();
  // Initialize database
  await Database.initialize(Config.databaseUrl);
  print('Database initialized');
  print('S3 Client Library Path: ${Config.s3ClientLibraryPath}');
  // Initialize S3
  S3Service.initializeS3(
    S3Configuration(
      endpoint: Config.s3Endpoint,
      bucketName: Config.s3BucketName,
      accessKeyId: Config.s3AccessKeyId,
      secretAccessKey: Config.s3SecretAccessKey,
      sessionToken: Config.s3SessionToken ?? '',
      region: Config.s3Region,
      accountId: Config.s3AccountId ?? '',
    ),
    (
      libraryPath: Config.s3ClientLibraryPath, //'./s3_client_dart.so',
      autoDownload: false,
    ),
  );

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
