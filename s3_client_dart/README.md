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

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  s3_client_dart: ^1.0.0
```

### Automatic Library Download

The package will **automatically download** the appropriate native library for your platform from GitHub releases on first use. No manual setup required!

The library is downloaded to `~/.s3_client_dart/lib/` and reused for subsequent runs.

### Manual Library Setup (Optional)

If you prefer to build the library yourself or use a custom version:

```bash
cd go_ffi
# For macOS
./deploy.sh dylib

# For Linux
./deploy.sh so

# For Windows
go build -buildmode=c-shared -ldflags="-s -w" -o windows/s3_client_dart.dll main.go
```

Then specify the custom path:

```dart
final client = S3Client(
  libraryPath: '/path/to/s3_client_dart.dylib',
  autoDownload: false,
);
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

## Advanced Usage

### Manual Library Download

You can manually control library downloads:

```dart
import 'package:s3_client_dart/s3_client_dart.dart';

void main() async {
  // Download specific version
  final libraryPath = await LibraryDownloader.downloadLibrary(
    version: 'v1.0.0',  // or 'latest'
  );
  
  print('Library downloaded to: $libraryPath');
  
  // Use the downloaded library
  final client = S3Client(
    libraryPath: libraryPath,
    autoDownload: false,
  );
}
```

### Disable Auto-Download

If you want to use only locally built libraries:

```dart
final client = S3Client(
  autoDownload: false,  // Will throw error if library not found
);
```

## Platform Support

- ✅ macOS (ARM64 & x86_64) - Auto-download supported
- ✅ Linux (x86_64) - Auto-download supported
- ✅ Windows (x86_64) - Auto-download supported

Pre-built libraries are available for all platforms via GitHub releases.

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
