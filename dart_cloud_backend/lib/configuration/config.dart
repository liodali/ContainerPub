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
  static late int functionMaxRequestSizeMb;

  // Database access control
  static late String? functionDatabaseUrl;
  static late int functionDatabaseMaxConnections;
  static late int functionDatabaseConnectionTimeoutMs;

  // S3 Configuration
  static late String s3Endpoint;
  static late String s3BucketName;
  static late String s3AccessKeyId;
  static late String s3SecretAccessKey;
  static late String s3Region;
  static late String? s3SessionToken;
  static late String? s3AccountId;

  // S3 Client Configuration
  static late String s3ClientLibraryPath;

  // Docker Configuration
  static late String dockerBaseImage;
  static late String dockerRegistry;

  static String get fileEnv {
    return String.fromEnvironment('FILE_ENV', defaultValue: '.env');
  }

  static Future<void> load() async {
    final env = DotEnv();
    final envFile = File(fileEnv);

    if (await envFile.exists()) {
      env.load([fileEnv]);
    }

    port = int.parse(env['PORT'] ?? Platform.environment['PORT'] ?? '8080');
    functionsDir =
        env['FUNCTIONS_DIR'] ?? Platform.environment['FUNCTIONS_DIR'] ?? './functions';
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

    // S3 Client Configuration
    s3ClientLibraryPath = env['S3_CLIENT_LIBRARY_PATH'] ?? './s3_client_dart.dylib';

    // S3 Configuration
    s3Endpoint =
        env['S3_ENDPOINT'] ??
        Platform.environment['S3_ENDPOINT'] ??
        'https://s3.amazonaws.com';
    s3BucketName =
        env['S3_BUCKET_NAME'] ??
        Platform.environment['S3_BUCKET_NAME'] ??
        'dart-cloud-functions';
    s3AccessKeyId =
        env['S3_ACCESS_KEY_ID'] ?? Platform.environment['S3_ACCESS_KEY_ID'] ?? '';
    s3SecretAccessKey =
        env['S3_SECRET_ACCESS_KEY'] ?? Platform.environment['S3_SECRET_ACCESS_KEY'] ?? '';
    s3Region = env['S3_REGION'] ?? Platform.environment['S3_REGION'] ?? 'us-east-1';
    s3SessionToken =
        ''; //env['S3_SESSION_TOKEN'] ?? Platform.environment['S3_SESSION_TOKEN'];
    s3AccountId = env['S3_ACCOUNT_ID'] ?? Platform.environment['S3_ACCOUNT_ID'];

    // Docker Configuration
    dockerBaseImage =
        env['DOCKER_BASE_IMAGE'] ??
        Platform.environment['DOCKER_BASE_IMAGE'] ??
        'dart:stable';
    dockerRegistry =
        env['DOCKER_REGISTRY'] ??
        Platform.environment['DOCKER_REGISTRY'] ??
        'localhost:5000';

    // Ensure functions directory exists
    final dir = Directory(functionsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  static void loadFake() {
    dockerRegistry = 'localhost:5000';
    functionMaxMemoryMb = 128;
    functionDatabaseUrl = 'postgres://dart_cloud:dart_cloud@postgres:5432/dart_cloud';
    functionDatabaseMaxConnections = 5;
    functionDatabaseConnectionTimeoutMs = 5000;
  }
}
