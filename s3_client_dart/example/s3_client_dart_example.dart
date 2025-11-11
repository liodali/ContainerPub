import 'package:s3_client_dart/s3_client_dart.dart';

void main() async {
  // Create S3 client instance
  final s3Client = S3Client();

  // Initialize with your AWS credentials
  s3Client.initialize(
    bucketName: 'your-bucket-name',
    accessKeyId: 'your-access-key-id',
    secretAccessKey: 'your-secret-access-key',
    sessionToken: '', // Optional, leave empty if not using temporary credentials
  );

  try {
    // Upload a file
    print('Uploading file...');
    final uploadResult = await s3Client.upload(
      '/path/to/local/file.txt',
      'remote/path/file.txt',
    );
    print('Upload result: $uploadResult');

    // List all objects in the bucket
    print('\nListing objects...');
    final objects = await s3Client.listObjects();
    print('Objects in bucket:');
    for (final object in objects) {
      print('  - $object');
    }

    // Get a presigned URL (valid for 1 hour)
    print('\nGenerating presigned URL...');
    final presignedUrl = await s3Client.getPresignedUrl(
      'remote/path/file.txt',
      expirationSeconds: 3600,
    );
    print('Presigned URL: $presignedUrl');

    // Download a file
    print('\nDownloading file...');
    final downloadResult = await s3Client.download(
      'remote/path/file.txt',
      '/path/to/local/downloaded-file.txt',
    );
    if (downloadResult.isEmpty) {
      print('Download successful');
    } else {
      print('Download error: $downloadResult');
    }

    // Delete an object
    print('\nDeleting object...');
    final deleteResult = await s3Client.deleteObject('remote/path/file.txt');
    if (deleteResult.isEmpty) {
      print('Delete successful');
    } else {
      print('Delete error: $deleteResult');
    }
  } catch (e) {
    print('Error: $e');
  }
}
