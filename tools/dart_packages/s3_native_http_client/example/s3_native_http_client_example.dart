import 'dart:convert';
import 'dart:io';

import 'package:s3_native_http_client/s3_native_http_client.dart';

void main() async {
  print('=== S3 Native HTTP Client - Mock API Example ===\n');
  final secretJson = File('example/secret.json').readAsStringSync();
  final secret = jsonDecode(secretJson);
  // Initialize mock service with configuration
  final config = S3RequestConfiguration(
    accessKey: secret['S3_ACCESS_KEY_ID'],
    secretKey: secret['S3_SECRET_ACCESS_KEY'],
    endpoint: secret['S3_ENDPOINT'],
    region: secret['S3_REGION'],
    bucket: secret['S3_BUCKET_NAME'],
  );

  final s3Mock = S3Service(configuration: config);

  try {
    // Example 1: Upload bytes
    print('📤 Example 1: Uploading file content...');
    final testData = 'Hello, S3! ${DateTime.now()} 🎉'.codeUnits;
    final file = File('example/test.txt');
    file.writeAsBytes(testData);
    final uploadSuccess = await s3Mock.upload('example/test.txt', file);
    print('Upload result: $uploadSuccess\n');

    // Example 2: Check if object exists
    print('🔍 Example 2: Checking if object exists...');
    final exists = await s3Mock.exists('example/test.txt');
    print('Object exists: $exists\n');

    // Example 3: Download object
    print('⬇️ Example 3: Downloading object...');
    final downloaded = await s3Mock.download('example/test.txt');
    if (downloaded != null) {
      final content = String.fromCharCodes(downloaded);
      print('Downloaded content: $content\n');
    }



    // Example 6: List objects
    print('📂 Example 6: Listing all objects...');
    final allObjects = await s3Mock.listObjects();
    print('Total objects: ${allObjects.length}');
    for (final obj in allObjects) {
      print('  - $obj');
    }
    print('');

    // Example 7: List objects with prefix
    print('🔎 Example 7: Listing objects with prefix "file"...');
    final filteredObjects = await s3Mock.listObjects(prefix: 'file');
    print('Filtered objects: ${filteredObjects.length}');
    for (final obj in filteredObjects) {
      print('  - $obj');
    }
    print('');


    // Example 9: Delete object
    print('🗑️ Example 9: Deleting object...');
    final deleteSuccess = await s3Mock.delete('example/test.txt');
    print('Delete result: $deleteSuccess');
    final existsAfterDelete = await s3Mock.exists('example/test.txt');
    print('Object exists after delete: $existsAfterDelete\n');

    print('=== All examples completed successfully! ===');
    file.deleteSync();
  } catch (e) {
    print('Error: $e');
  }
}
