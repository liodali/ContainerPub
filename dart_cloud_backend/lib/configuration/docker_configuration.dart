import 'dart:io';
import 'package:dart_cloud_backend/utils/commons.dart';
import 'package:dotenv/dotenv.dart';

class DockerConfiguration {
  static late String dockerBaseImage;
  static late String dockerRegistry;
  static late String sharedVolumeName;

  static Future<void> load(DotEnv env, String functionsDir) async {
    dockerBaseImage =
        env['DOCKER_BASE_IMAGE'] ??
        Platform.environment['DOCKER_BASE_IMAGE'] ??
        'dart:stable';
    dockerRegistry =
        env['DOCKER_REGISTRY'] ??
        Platform.environment['DOCKER_REGISTRY'] ??
        'localhost:5000';
    sharedVolumeName =
        getValueFromEnv('SHARED_VOLUME_NAME') ??
        env['SHARED_VOLUME_NAME'] ??
        'functions_data';
  }

  static void loadFake() {
    dockerRegistry = 'localhost:5000';
  }
}
