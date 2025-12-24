# S3 Native HTTP Client

A Dart package for making AWS Signature V4 signed HTTP requests to S3-compatible services (AWS S3, Cloudflare R2, MinIO, etc.) without native FFI bindings.

## Features

- **AWS Signature V4 Signing**: Properly signed HTTP requests for S3 API compatibility
- **S3-Compatible Services**: Works with AWS S3, Cloudflare R2, MinIO, DigitalOcean Spaces, and other S3-compatible services
- **Core S3 Operations**:
  - Check object existence (HEAD)
  - Upload objects (PUT)
  - Download objects (GET)
  - Delete objects (DELETE)
  - List objects with prefix filtering
  - Get object metadata
  - Storage statistics
- **Mock Service**: In-memory mock implementation for testing without credentials
- **Pure Dart**: No native dependencies or FFI bindings required
- **Async/Await**: Full async support for all operations

## Getting started

### Prerequisites

- Dart 3.10.4 or higher
- S3 credentials (access key and secret key)
- S3 endpoint URL and region

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  s3_native_http_client: ^1.0.0
```

## Usage

### Real S3 Operations

```dart
import 'package:s3_native_http_client/s3_native_http_client.dart';

void main() async {
  // Configure S3 connection
  final config = S3RequestConfiguration(
    accessKey: 'your-access-key',
    secretKey: 'your-secret-key',
    endpoint: 'https://s3.amazonaws.com', // or your S3-compatible endpoint
    region: 'us-east-1',
    bucket: 'my-bucket',
  );

  final s3 = S3Service(configuration: config);

  // Upload a file
  final file = File('path/to/file.txt');
  final uploaded = await s3.upload('remote-file.txt', file);
  print('Upload successful: $uploaded');

  // Download a file
  final data = await s3.download('remote-file.txt');
  if (data != null) {
    print('Downloaded ${data.length} bytes');
  }

  // Check if object exists
  final exists = await s3.exists('remote-file.txt');
  print('Object exists: $exists');
}
```

### Mock Service (for Testing)

```dart
import 'package:s3_native_http_client/s3_native_http_client.dart';

void main() async {
  // Use mock service for testing
  final config = S3RequestConfiguration(
    accessKey: 'test-key',
    secretKey: 'test-secret',
    endpoint: 'https://s3.example.com',
    region: 'us-east-1',
    bucket: 'test-bucket',
  );

  final s3Mock = S3MockService(configuration: config);

  // Upload bytes
  final data = 'Hello, S3!'.codeUnits;
  await s3Mock.uploadBytes('test.txt', data);

  // Download
  final downloaded = await s3Mock.download('test.txt');
  print('Content: ${String.fromCharCodes(downloaded!)}');

  // List objects
  final objects = await s3Mock.listObjects();
  print('Objects: $objects');

  // Get storage stats
  final stats = await s3Mock.getStorageStats();
  print('Total size: ${stats['totalSize']} bytes');
}
```

### Supported S3 Endpoints

#### AWS S3

```dart
final config = S3RequestConfiguration(
  accessKey: 'AKIAIOSFODNN7EXAMPLE',
  secretKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
  endpoint: 'https://s3.amazonaws.com',
  region: 'us-east-1',
  bucket: 'my-bucket',
);
```

#### Cloudflare R2

```dart
final config = S3RequestConfiguration(
  accessKey: 'your-r2-access-key',
  secretKey: 'your-r2-secret-key',
  endpoint: 'https://<account-id>.r2.cloudflarestorage.com',
  region: 'auto',
  bucket: 'my-bucket',
);
```

#### MinIO

```dart
final config = S3RequestConfiguration(
  accessKey: 'minioadmin',
  secretKey: 'minioadmin',
  endpoint: 'http://localhost:9000',
  region: 'us-east-1',
  bucket: 'my-bucket',
);
```

## API Reference

### S3Service (Real S3)

- `Future<bool> exists(String objectKey)` - Check if object exists
- `Future<bool> upload(String objectKey, File file)` - Upload file
- `Future<List<int>?> download(String objectKey)` - Download object

### S3MockService (Testing)

- `Future<bool> exists(String objectKey)` - Check if object exists
- `Future<bool> upload(String objectKey, File file)` - Upload file
- `Future<bool> uploadBytes(String objectKey, List<int> bytes)` - Upload bytes
- `Future<List<int>?> download(String objectKey)` - Download object
- `Future<bool> delete(String objectKey)` - Delete object
- `Future<List<String>> listObjects({String? prefix})` - List objects
- `Future<Map<String, dynamic>?> getMetadata(String objectKey)` - Get metadata
- `Future<Map<String, dynamic>> getStorageStats()` - Get storage statistics
- `Future<void> clear()` - Clear all objects

## Examples

See the `/example` folder for complete examples:

```bash
dart example/s3_native_http_client_example.dart
```

For detailed mock service documentation, see [MOCK_SERVICE.md](MOCK_SERVICE.md).

## Testing

Run the test suite:

```bash
dart test
```

Tests include:

- Upload and download operations
- Object existence checks
- Delete operations
- List operations with filtering
- Metadata retrieval
- Storage statistics
- Error handling

## Configuration

### S3RequestConfiguration

```dart
class S3RequestConfiguration {
  final String accessKey;        // AWS access key ID
  final String secretKey;        // AWS secret access key
  final String endpoint;         // S3 endpoint URL
  final String region;           // AWS region (e.g., 'us-east-1', 'auto' for R2)
  final String bucket;           // S3 bucket name

  String get uri => '$endpoint/$bucket';
}
```

## Security Considerations

- **Credentials**: Never hardcode credentials. Use environment variables or secure configuration management
- **HTTPS**: Always use HTTPS endpoints in production
- **Access Control**: Use IAM policies to restrict S3 access to specific buckets and operations
- **Signature V4**: All requests are signed with AWS Signature V4 for authentication

## Troubleshooting

### Authentication Errors

- Verify access key and secret key are correct
- Check that credentials have S3 permissions
- Ensure endpoint URL is correct for your region

### Connection Errors

- Verify endpoint URL is accessible
- Check network connectivity
- For MinIO, ensure server is running

### Upload/Download Failures

- Check bucket permissions
- Verify object key is valid
- Ensure sufficient disk space for downloads

## Additional Information

For more information about AWS Signature V4, see the [AWS documentation](https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).

For S3 API reference, see the [AWS S3 API documentation](https://docs.aws.amazon.com/AmazonS3/latest/API/Welcome.html).
