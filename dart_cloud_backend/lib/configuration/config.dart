import 'dart:io';
import 'package:dart_cloud_backend/services/docker/docker_service.dart'
    show DockerService;
import 'package:dart_cloud_backend/services/docker/dockerfile_generator.dart';
import 'package:dart_cloud_backend/services/docker/file_system.dart';
import 'package:dart_cloud_backend/services/docker/podman_py_runtime.dart';
import 'package:dart_cloud_backend/services/docker/podman_runtime.dart'
    show PodmanRuntime;
import 'package:dart_cloud_backend/utils/commons.dart';
import 'package:dotenv/dotenv.dart';

class Config {
  static late int port;
  static late String functionsDir;
  static late String databaseUrl;
  static late bool databaseSSL;
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
        dbURLGenerator(
          env,
        ); //'postgres://dart_cloud:dart_cloud@postgres:5432/dart_cloud';
    print(databaseUrl);
    databaseSSL =
        bool.tryParse(
          env['DATABASE_SSL'] ?? Platform.environment['DATABASE_SSL'] ?? 'false',
        ) ??
        false;
    jwtSecret = env['JWT_SECRET'] ?? Platform.environment['JWT_SECRET'] ?? '';
    if (jwtSecret.isEmpty) {
      throw Exception('JWT_SECRET is not set');
    }
    // Function execution limits
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
    final podmanSocket = getValueFromEnv('PODMAN_SOCKET') ?? env['PODMAN_SOCKET'];
    final pyPodmanCliPath =
        getValueFromEnv('PYTHON_PODMAN_CLI') ?? env['PYTHON_PODMAN_CLI'];
    final usePODCLI =
        getBoolValueFromEnv('USE_PODMAN_CLI', false) ??
        bool.tryParse(env['USE_PODMAN_CLI'] ?? '') ??
        false;

    DockerService.init(
      runtime: usePODCLI
          ? PodmanRuntime()
          : PodmanPyRuntime(
              socketPath: podmanSocket,
              pythonClientPath: '${Directory.current.path}/$pyPodmanCliPath',
            ),
      fileSystem: const RealFileSystem(),
      dockerfileGenerator: const DockerfileGenerator(),
    );
    final isAvailable = await DockerService.instance.isRuntimeAvailable();
    if (!isAvailable) {
      print(podmanSocket);
      print(pyPodmanCliPath);
      print(usePODCLI);
      print('Podman runtime is not available');
      exit(1);
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

String dbURLGenerator(DotEnv env) {
  return 'postgres://${env['POSTGRES_USER']}:${env['POSTGRES_PASSWORD']}@${env['POSTGRES_HOST']}:${env['POSTGRES_PORT']}/${env['POSTGRES_DB']}';
}
