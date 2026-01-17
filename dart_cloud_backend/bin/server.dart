import 'dart:async';
import 'dart:io';
import 'package:dart_cloud_backend/services/s3_service.dart' show S3Service;
import 'package:dart_cloud_backend/services/token_service.dart';
import 'package:dart_cloud_backend/services/email_verification_service.dart';
import 'package:s3_native_http_client/s3_native_http_client.dart'
    show S3RequestConfiguration;
import 'package:sentry/sentry.dart';
// import 'package:s3_client_dart/s3_client_dart.dart' show S3Configuration;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:dart_cloud_backend/router.dart';
import 'package:database/database.dart';
import 'package:dart_cloud_backend/configuration/config.dart';

void main() async {
  // Load configuration
  await Config.load();
  await TokenService.instance.initialize(directoryApp: Config.functionsDir);
  // Initialize database
  await Database.initialize(Config.databaseUrl);
  print('Database initialized');

  // Initialize email verification service
  EmailVerificationService().initialize();
  print('Email verification service initialized');

  await initCrashlytics();
  // Initialize S3
  S3Service.initializeS3(
    S3RequestConfiguration(
      endpoint: Config.s3Endpoint,
      bucket: Config.s3BucketName,
      accessKey: Config.s3AccessKeyId,
      secretKey: Config.s3SecretAccessKey,
      sessionToken: Config.s3SessionToken ?? '',
      region: Config.s3Region,
      // accountId: Config.s3AccountId ?? '',
    ),
  );

  // Create router
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(createRouter());

  runZonedGuarded(
    () async {
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
    },
    (exception, stackTrace) async {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    },
  );
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
Future<void> initCrashlytics() async {
  await Sentry.init((options) {
    options.dsn = Config.sentryDsn;
    // Adds request headers and IP for users, for more info visit:
    // https://docs.sentry.io/platforms/dart/data-management/data-collected/
    options.sendDefaultPii = true;
  });
}
