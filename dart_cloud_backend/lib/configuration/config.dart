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

// Import configuration classes
import 'email_configuration.dart';
import 'function_configuration.dart';
import 's3_configuration.dart';
import 'docker_configuration.dart';

class Config {
  static late int port;
  static late String functionsDir;
  static late String functionsDataDir;
  static late String functionsDataBaseHostDir;
  static late String databaseUrl;
  static late bool databaseSSL;
  static late String jwtSecret;

  static late String sentryDsn;

  // Function Configuration - getters for backward compatibility
  static int get functionTimeoutSeconds => FunctionConfiguration.functionTimeoutSeconds;
  static int get functionMaxMemoryMb => FunctionConfiguration.functionMaxMemoryMb;
  static int get functionMaxConcurrentExecutions =>
      FunctionConfiguration.functionMaxConcurrentExecutions;
  static int get functionMaxRequestSizeMb =>
      FunctionConfiguration.functionMaxRequestSizeMb;
  static String? get functionDatabaseUrl => FunctionConfiguration.functionDatabaseUrl;
  static int get functionDatabaseMaxConnections =>
      FunctionConfiguration.functionDatabaseMaxConnections;
  static int get functionDatabaseConnectionTimeoutMs =>
      FunctionConfiguration.functionDatabaseConnectionTimeoutMs;

  // S3 Configuration - getters for backward compatibility
  static String get s3Endpoint => S3Configuration.s3Endpoint;
  static String get s3BucketName => S3Configuration.s3BucketName;
  static String get s3AccessKeyId => S3Configuration.s3AccessKeyId;
  static String get s3SecretAccessKey => S3Configuration.s3SecretAccessKey;
  static String get s3Region => S3Configuration.s3Region;
  static String? get s3SessionToken => S3Configuration.s3SessionToken;
  static String? get s3AccountId => S3Configuration.s3AccountId;
  static String get s3ClientLibraryPath => S3Configuration.s3ClientLibraryPath;

  // Docker Configuration - getters for backward compatibility
  static String get dockerBaseImage => DockerConfiguration.dockerBaseImage;
  static String get dockerRegistry => DockerConfiguration.dockerRegistry;
  static String get sharedVolumeName => DockerConfiguration.sharedVolumeName;

  // Email Service Configuration - getters for backward compatibility
  static String get emailApiKey => EmailConfiguration.emailApiKey;
  static String get emailFromAddress => EmailConfiguration.emailFromAddress;
  static String get emailLogo => EmailConfiguration.emailLogo;
  static String get emailCompanyName => EmailConfiguration.emailCompanyName;
  static String get emailSupportEmail => EmailConfiguration.emailSupportEmail;

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
        getValueFromEnv('FUNCTIONS_DIR') ?? env['FUNCTIONS_DIR'] ?? './functions';
    functionsDataDir =
        getValueFromEnv('FUNCTIONS_DATA_DIR') ??
        env['FUNCTIONS_DATA_DIR'] ??
        '/app/functions/data';
    functionsDataBaseHostDir =
        getValueFromEnv('FUNCTIONS_DATA_BASE_HOST_DIR') ??
        env['FUNCTIONS_DATA_BASE_HOST_DIR'] ??
        '/app/functions/data';
    databaseUrl = //
        getValueFromEnv('DATABASE_URL') ??
        env['DATABASE_URL'] ??
        dbURLGenerator(
          env,
        ); //'postgres://dart_cloud:dart_cloud@postgres:5432/dart_cloud';
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
    // (Moved to FunctionConfiguration.load())

    sentryDsn = env['SENTRY_DSN'] ?? getValueFromEnv('SENTRY_DSN') ?? '';

    // Load all configuration modules
    await FunctionConfiguration.load(env);
    await S3Configuration.load(env);
    await DockerConfiguration.load(env, functionsDir);
    await EmailConfiguration.load(env);

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
    FunctionConfiguration.loadFake();
    S3Configuration.loadFake();
    DockerConfiguration.loadFake();
    EmailConfiguration.loadFake();
  }
}

String dbURLGenerator(DotEnv env) {
  return 'postgres://${env['POSTGRES_USER']}:${env['POSTGRES_PASSWORD']}@${env['POSTGRES_HOST']}:${env['POSTGRES_PORT']}/${env['POSTGRES_DB']}';
}
