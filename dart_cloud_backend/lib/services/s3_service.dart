import 'package:cli_util/cli_logging.dart';
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
    final logger = Logger.verbose();
    logger.stdout('S3 Client initialized');
    logger.stdout('Initializing S3 client:\n');
    logger.stdout('  Endpoint: ${configuration.endpoint}\n');
    logger.stdout('  Region: ${configuration.region}\n');
    logger.stdout('  Access Key ID length: ${configuration.accessKey.length}\n');
    logger.stdout('  Secret Key length: ${configuration.secretKey.length}\n');
    logger.stdout('  Session Token length: ${configuration.sessionToken?.length}\n');
  }
}
