# S3 Client Dart

A high-performance S3 client for Dart using Go FFI (Foreign Function Interface). This package provides a Dart interface to AWS S3 operations backed by Go's official AWS SDK for optimal performance.

## Features

- ✅ **Upload** files to S3
- ✅ **Download** files from S3
- ✅ **List** objects in a bucket
- ✅ **Delete** objects from S3
- ✅ **Generate presigned URLs** for temporary access
- ⚡ **High performance** using Go's native AWS SDK
- 🔒 **Thread-safe** operations with mutex protection

## Architecture

This package uses Dart FFI to call functions from a Go shared library (`.dylib` on macOS, `.so` on Linux, `.dll` on Windows). The Go library uses the official AWS SDK v2 for Go, providing robust and well-tested S3 operations.

## Prerequisites

Before using this package, you need to build the Go shared library:

```bash
cd go_ffi
# For macOS
./deploy.sh dylib

# For Linux
./deploy.sh so
```

This will generate the platform-specific shared library in the appropriate directory (`darwin/` or `linux/`).

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  s3_client_dart: ^1.0.0
```

## Usage

### Basic Example

```dart
import 'package:s3_client_dart/s3_client_dart.dart';

void main() async {
  // Create and initialize the client
  final s3Client = S3Client();
  
  s3Client.initialize(
    bucketName: 'your-bucket-name',
    accessKeyId: 'your-access-key-id',
    secretAccessKey: 'your-secret-access-key',
    sessionToken: '', // Optional
  );

  // Upload a file
  final uploadResult = await s3Client.upload(
    '/path/to/local/file.txt',
    'remote/path/file.txt',
  );
  print('Uploaded: $uploadResult');

  // List objects
  final objects = await s3Client.listObjects();
  print('Objects: $objects');

  // Download a file
  await s3Client.download(
    'remote/path/file.txt',
    '/path/to/download/file.txt',
  );

  // Get presigned URL (valid for 1 hour)
  final url = await s3Client.getPresignedUrl(
    'remote/path/file.txt',
    expirationSeconds: 3600,
  );
  print('Presigned URL: $url');

  // Delete an object
  await s3Client.deleteObject('remote/path/file.txt');
}
```

## API Reference

### S3Client

#### `void initialize({required String bucketName, required String accessKeyId, required String secretAccessKey, String sessionToken = ''})`

Initialize the S3 client with AWS credentials. Must be called before any other operations.

#### `Future<String> upload(String filePath, String objectKey)`

Upload a file to S3. Returns the object key on success, empty string on failure.

#### `Future<List<String>> listObjects()`

List all objects in the bucket. Returns a list of object keys.

#### `Future<String> deleteObject(String objectKey)`

Delete an object from S3. Returns empty string on success, error message on failure.

#### `Future<String> download(String objectKey, String destinationPath)`

Download an object from S3 to a local file. Returns empty string on success, error message on failure.

#### `Future<String> getPresignedUrl(String objectKey, {int expirationSeconds = 3600})`

Generate a presigned URL for temporary access to an object. Default expiration is 1 hour (3600 seconds).

## Building the Go Shared Library

The Go shared library is located in the `go_ffi/` directory. To build it:

```bash
cd go_ffi

# For macOS (produces .dylib)
./deploy.sh dylib

# For Linux (produces .so)
./deploy.sh so
```

The build script will:
1. Compile the Go code with CGO enabled
2. Generate the shared library with C bindings
3. Place the output in the platform-specific directory

## Platform Support

- ✅ macOS (ARM64 & x86_64)
- ✅ Linux (x86_64)
- ⚠️ Windows (requires additional setup)

## Error Handling

Operations return empty strings on success and error messages on failure. You can check the return value to determine if an operation succeeded:

```dart
final result = await s3Client.deleteObject('key');
if (result.isEmpty) {
  print('Success!');
} else {
  print('Error: $result');
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

BSD-style license
