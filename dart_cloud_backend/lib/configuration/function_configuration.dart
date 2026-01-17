import 'dart:io';
import 'package:dotenv/dotenv.dart';

class FunctionConfiguration {
  static late int functionTimeoutSeconds;
  static late int functionMaxMemoryMb;
  static late int functionMaxConcurrentExecutions;
  static late int functionMaxRequestSizeMb;

  // Database access control
  static late String? functionDatabaseUrl;
  static late int functionDatabaseMaxConnections;
  static late int functionDatabaseConnectionTimeoutMs;

  static Future<void> load(DotEnv env) async {
    functionTimeoutSeconds = int.parse(
      env['FUNCTION_TIMEOUT_SECONDS'] ??
          Platform.environment['FUNCTION_TIMEOUT_SECONDS'] ??
          '5',
    );

    functionMaxMemoryMb = int.parse(
      env['FUNCTION_MAX_MEMORY_MB'] ??
          Platform.environment['FUNCTION_MAX_MEMORY_MB'] ??
          '20',
    );

    functionMaxConcurrentExecutions = int.parse(
      env['FUNCTION_MAX_CONCURRENT'] ??
          Platform.environment['FUNCTION_MAX_CONCURRENT'] ??
          '10',
    );

    functionMaxRequestSizeMb = int.parse(
      env['FUNCTION_MAX_REQUEST_SIZE_MB'] ??
          Platform.environment['FUNCTION_MAX_REQUEST_SIZE_MB'] ??
          '5',
    );

    // Database access for functions
    functionDatabaseUrl =
        env['FUNCTION_DATABASE_URL'] ?? Platform.environment['FUNCTION_DATABASE_URL'];

    functionDatabaseMaxConnections = int.parse(
      env['FUNCTION_DB_MAX_CONNECTIONS'] ??
          Platform.environment['FUNCTION_DB_MAX_CONNECTIONS'] ??
          '5',
    );

    functionDatabaseConnectionTimeoutMs = int.parse(
      env['FUNCTION_DB_TIMEOUT_MS'] ??
          Platform.environment['FUNCTION_DB_TIMEOUT_MS'] ??
          '5000',
    );
  }

  static void loadFake() {
    functionMaxMemoryMb = 128;
    functionDatabaseUrl = 'postgres://dart_cloud:dart_cloud@postgres:5432/dart_cloud';
    functionDatabaseMaxConnections = 5;
    functionDatabaseConnectionTimeoutMs = 5000;
  }
}
