# Quick Start Guide

This guide will help you get started with the S3 Client Dart package in just a few minutes.

## Step 1: Build the Go Shared Library

First, you need to build the Go shared library that provides the S3 functionality:

```bash
cd go_ffi

# For macOS
./deploy.sh dylib

# For Linux
./deploy.sh so
```

This will create the shared library in the appropriate platform directory.

## Step 2: Add Dependency

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  s3_client_dart: ^1.0.0
```

## Step 3: Get Your AWS Credentials

You'll need:
- **Bucket Name**: The name of your S3 bucket
- **Access Key ID**: Your AWS access key ID
- **Secret Access Key**: Your AWS secret access key
- **Session Token** (optional): Only needed for temporary credentials

## Step 4: Write Your First S3 Operation

Create a new Dart file and add:

```dart
import 'package:s3_client_dart/s3_client_dart.dart';

void main() async {
  // Create the client
  final s3Client = S3Client();
  
  // Initialize with your credentials
  s3Client.initialize(
    bucketName: 'my-bucket',
    accessKeyId: 'AKIAIOSFODNN7EXAMPLE',
    secretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    sessionToken: '', // Leave empty if not using temporary credentials
  );

  // Upload a file
  print('Uploading...');
  final result = await s3Client.upload(
    '/path/to/myfile.txt',
    'uploads/myfile.txt',
  );
  
  if (result.isNotEmpty) {
    print('✅ Uploaded successfully: $result');
  } else {
    print('❌ Upload failed');
  }

  // List all files
  print('\nListing files...');
  final files = await s3Client.listObjects();
  for (final file in files) {
    print('  📄 $file');
  }
}
```

## Step 5: Run Your Code

```bash
dart run your_file.dart
```

## Common Operations

### Upload a File

```dart
await s3Client.upload('/local/path/file.pdf', 'remote/path/file.pdf');
```

### Download a File

```dart
await s3Client.download('remote/path/file.pdf', '/local/path/file.pdf');
```

### List All Files

```dart
final files = await s3Client.listObjects();
print(files);
```

### Delete a File

```dart
await s3Client.deleteObject('remote/path/file.pdf');
```

### Get a Temporary URL (valid for 1 hour)

```dart
final url = await s3Client.getPresignedUrl(
  'remote/path/file.pdf',
  expirationSeconds: 3600,
);
print('Share this URL: $url');
```

## Error Handling

Most operations return empty strings on success and error messages on failure:

```dart
final result = await s3Client.deleteObject('myfile.txt');
if (result.isEmpty) {
  print('Success!');
} else {
  print('Error: $result');
}
```

## Troubleshooting

### "Library not found" error

Make sure you've built the Go shared library:
```bash
cd go_ffi
./deploy.sh dylib  # or 'so' for Linux
```

### "S3Client not initialized" error

Always call `initialize()` before any other operations:
```dart
s3Client.initialize(
  bucketName: 'your-bucket',
  accessKeyId: 'your-key',
  secretAccessKey: 'your-secret',
);
```

### AWS Credentials Issues

- Verify your credentials are correct
- Check that your IAM user/role has S3 permissions
- Ensure the bucket name is correct and accessible

## Next Steps

- Check out the [full example](example/s3_client_dart_example.dart)
- Read the [complete README](README.md)
- Explore the [Go FFI documentation](go_ffi/README.md)

## Need Help?

- Open an issue on GitHub
- Check the AWS S3 documentation
- Review the example code

Happy coding! 🚀
