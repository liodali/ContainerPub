import 'package:s3_native_http_client/s3_native_http_client.dart';

typedef S3PathConfiguration = ({String? libraryPath, bool autoDownload});

class S3Service {
  static S3NativeHttpClient? _s3Client;

  static S3NativeHttpClient get s3Client {
    if (_s3Client == null) {
      throw Exception('S3 client not initialized');
    }
    return _s3Client!;
  }

  static void initializeS3(
    S3RequestConfiguration configuration,
  ) {
    _s3Client ??= S3NativeHttpClient(
      configuration: configuration,
    );
  }
}
