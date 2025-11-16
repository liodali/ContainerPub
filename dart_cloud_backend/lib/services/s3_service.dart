import 'package:s3_client_dart/s3_client_dart.dart';

class S3Service {
  static S3Client? _s3Client;

  static S3Client get s3Client {
    if (_s3Client == null) {
      throw Exception('S3 client not initialized');
    }
    return _s3Client!;
  }

  static void initializeS3(S3Configuration configuration) {
    _s3Client ??= S3Client();
    _s3Client!.initialize(
      configuration: configuration,
    );
  }
}
