import 'dart:io';
import 'package:dotenv/dotenv.dart';

class Config {
  static late int port;
  static late String functionsDir;
  static late String databaseUrl;
  static late String jwtSecret;
  
  // Function execution limits
  static late int functionTimeoutSeconds;
  static late int functionMaxMemoryMb;
  static late int functionMaxConcurrentExecutions;
  
  // Database access control
  static late String? functionDatabaseUrl;
  static late int functionDatabaseMaxConnections;
  static late int functionDatabaseConnectionTimeoutMs;

  static Future<void> load() async {
    final env = DotEnv();
    final envFile = File('.env');

    if (await envFile.exists()) {
      env.load();
    }

    port = int.parse(env['PORT'] ?? Platform.environment['PORT'] ?? '8080');
    functionsDir =
        env['FUNCTIONS_DIR'] ??
        Platform.environment['FUNCTIONS_DIR'] ??
        './functions';
    databaseUrl =
        env['DATABASE_URL'] ??
        Platform.environment['DATABASE_URL'] ??
        'postgres://dart_cloud:dart_cloud@postgres:5432/dart_cloud';
    jwtSecret =
        env['JWT_SECRET'] ??
        Platform.environment['JWT_SECRET'] ??
        'your-secret-key-change-in-production';
    
    // Function execution limits
    functionTimeoutSeconds = int.parse(
      env['FUNCTION_TIMEOUT_SECONDS'] ??
      Platform.environment['FUNCTION_TIMEOUT_SECONDS'] ??
      '5',
    );
    
    functionMaxMemoryMb = int.parse(
      env['FUNCTION_MAX_MEMORY_MB'] ??
      Platform.environment['FUNCTION_MAX_MEMORY_MB'] ??
      '128',
    );
    
    functionMaxConcurrentExecutions = int.parse(
      env['FUNCTION_MAX_CONCURRENT'] ??
      Platform.environment['FUNCTION_MAX_CONCURRENT'] ??
      '10',
    );
    
    // Database access for functions
    functionDatabaseUrl = env['FUNCTION_DATABASE_URL'] ??
        Platform.environment['FUNCTION_DATABASE_URL'];
    
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

    // Ensure functions directory exists
    final dir = Directory(functionsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}
