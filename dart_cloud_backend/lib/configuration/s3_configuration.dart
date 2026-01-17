import 'dart:io';
import 'package:dotenv/dotenv.dart';

class S3Configuration {
  static late String s3Endpoint;
  static late String s3BucketName;
  static late String s3AccessKeyId;
  static late String s3SecretAccessKey;
  static late String s3Region;
  static late String? s3SessionToken;
  static late String? s3AccountId;

  // S3 Client Configuration
  static late String s3ClientLibraryPath;

  static Future<void> load(DotEnv env) async {
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

    // S3 Client Configuration
    s3ClientLibraryPath = env['S3_CLIENT_LIBRARY_PATH'] ?? './s3_client_dart.dylib';
  }

  static void loadFake() {
    s3Endpoint = 'https://s3.amazonaws.com';
    s3BucketName = 'dart-cloud-functions';
    s3AccessKeyId = '';
    s3SecretAccessKey = '';
    s3Region = 'us-east-1';
    s3SessionToken = '';
    s3AccountId = null;
    s3ClientLibraryPath = './s3_client_dart.dylib';
  }
}
