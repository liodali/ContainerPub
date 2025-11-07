import 'dart:io';
import 'package:dotenv/dotenv.dart';

class Config {
  static late int port;
  static late String functionsDir;
  static late String databaseUrl;
  static late String jwtSecret;

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
        'postgres://localhost:5432/dart_cloud';
    jwtSecret =
        env['JWT_SECRET'] ??
        Platform.environment['JWT_SECRET'] ??
        'your-secret-key-change-in-production';

    // Ensure functions directory exists
    final dir = Directory(functionsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}
