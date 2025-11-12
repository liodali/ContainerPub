import 'package:s3_client_dart/s3_client_dart.dart';
import 'package:test/test.dart';

void main() {
  group('S3Client Tests', () {
    late S3Client client;

    setUp(() {
      client = S3Client();
    });

    test('S3Client can be instantiated', () {
      expect(client, isNotNull);
    });

    test('S3Client throws StateError when not initialized', () {
      expect(
        () => client.listObjects(),
        throwsA(isA<StateError>()),
      );
    });

    test('S3Client can be initialized', () {
      expect(
        () => client.initialize(
          configuration: S3Configuration(
            bucketName: 'test-bucket',
            accessKeyId: 'test-key',
            secretAccessKey: 'test-secret',
            sessionToken: 'test-token',
          ),
        ),
        returnsNormally,
      );
    });
  });
}
