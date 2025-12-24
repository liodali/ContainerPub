# S3 Mock Service Documentation

The `S3MockService` provides in-memory mock implementations of S3 operations for testing and development without requiring actual S3 credentials or network calls.

## Overview

`S3MockService` simulates S3 operations with realistic delays and provides a complete API for:

- Uploading objects (from files or bytes)
- Downloading objects
- Checking object existence
- Deleting objects
- Listing objects with optional prefix filtering
- Retrieving object metadata
- Getting storage statistics
- Clearing all objects

## Usage

### Basic Setup

```dart
import 'package:s3_native_http_client/s3_native_http_client.dart';

final config = S3RequestConfiguration(
  accessKey: 'test-key',
  secretKey: 'test-secret',
  endpoint: 'https://s3.example.com',
  region: 'us-east-1',
  bucket: 'my-bucket',
);

final s3Mock = S3MockService(configuration: config);
```

### Upload Operations

#### Upload from bytes

```dart
final data = 'Hello, S3!'.codeUnits;
final success = await s3Mock.uploadBytes('test.txt', data);
print('Upload result: $success'); // true
```

#### Upload from file

```dart
import 'dart:io';

final file = File('path/to/file.txt');
final success = await s3Mock.upload('remote-file.txt', file);
```

### Download Operations

```dart
final downloaded = await s3Mock.download('test.txt');
if (downloaded != null) {
  final content = String.fromCharCodes(downloaded);
  print('Content: $content'); // Content: Hello, S3!
}
```

### Check Object Existence

```dart
final exists = await s3Mock.exists('test.txt');
print('Object exists: $exists'); // true
```

### Delete Objects

```dart
final deleted = await s3Mock.delete('test.txt');
print('Deleted: $deleted'); // true

final stillExists = await s3Mock.exists('test.txt');
print('Still exists: $stillExists'); // false
```

### List Objects

#### List all objects

```dart
final allObjects = await s3Mock.listObjects();
print('Total objects: ${allObjects.length}');
for (final obj in allObjects) {
  print('  - $obj');
}
```

#### List with prefix filter

```dart
final filtered = await s3Mock.listObjects(prefix: 'documents/');
print('Filtered objects: ${filtered.length}');
```

### Get Object Metadata

```dart
final metadata = await s3Mock.getMetadata('test.txt');
if (metadata != null) {
  print('Key: ${metadata['key']}');
  print('Size: ${metadata['size']} bytes');
  print('Last Modified: ${metadata['lastModified']}');
  print('Bucket: ${metadata['bucket']}');
}
```

### Get Storage Statistics

```dart
final stats = await s3Mock.getStorageStats();
print('Object Count: ${stats['objectCount']}');
print('Total Size: ${stats['totalSize']} bytes');
print('Bucket: ${stats['bucket']}');
print('Endpoint: ${stats['endpoint']}');
```

### Clear All Objects

```dart
await s3Mock.clear();
final remaining = await s3Mock.listObjects();
print('Remaining objects: ${remaining.length}'); // 0
```

## Features

### Realistic Delays

Each operation includes simulated network delays:

- `exists()`: 100ms
- `upload()` / `uploadBytes()`: 200ms
- `download()`: 150ms
- `delete()`: 100ms
- `listObjects()`: 150ms
- `getMetadata()`: 100ms
- `getStorageStats()`: 100ms

### In-Memory Storage

All objects are stored in memory using a `Map<String, List<int>>` for fast access and testing.

### Metadata Tracking

Automatically tracks last modified timestamps for each object.

### Prefix Filtering

`listObjects()` supports optional prefix filtering for realistic bucket browsing.

## Testing

The package includes comprehensive test cases in `test/s3_mock_service_test.dart`:

```bash
dart test
```

Test coverage includes:

- Upload and existence checks
- Download operations
- Delete operations
- List operations with and without prefix
- Metadata retrieval
- Storage statistics
- Clear operations
- Multiple sequential operations

## Example

Run the complete example with 10 different operations:

```bash
dart example/s3_native_http_client_example.dart
```

This demonstrates:

1. Uploading file content
2. Checking object existence
3. Downloading objects
4. Getting object metadata
5. Uploading multiple objects
6. Listing all objects
7. Listing with prefix filter
8. Getting storage statistics
9. Deleting objects
10. Clearing all objects

## Integration with Real S3

To switch from mock to real S3, simply replace `S3MockService` with `S3Service`:

```dart
// Mock (for testing)
final s3 = S3MockService(configuration: config);

// Real S3 (for production)
final s3 = S3Service(configuration: config);
```

Both services implement the same interface, making it easy to swap implementations.

## Error Handling

The mock service handles errors gracefully:

- Returns `false` for failed uploads
- Returns `null` for non-existent downloads
- Returns `false` for deleting non-existent objects
- Returns `null` for metadata of non-existent objects

```dart
final result = await s3Mock.uploadBytes('file.txt', []);
if (!result) {
  print('Upload failed');
}

final data = await s3Mock.download('non-existent.txt');
if (data == null) {
  print('Object not found');
}
```

## Performance Characteristics

- **Memory**: Stores all objects in memory (suitable for testing)
- **Speed**: Instant operations with simulated delays
- **Scalability**: Limited by available RAM
- **Concurrency**: Thread-safe for async operations

## Use Cases

1. **Unit Testing**: Test S3 integration without credentials
2. **Integration Testing**: Simulate S3 behavior in tests
3. **Development**: Develop locally without AWS access
4. **CI/CD**: Run tests without external dependencies
5. **Prototyping**: Quickly prototype S3-based features
