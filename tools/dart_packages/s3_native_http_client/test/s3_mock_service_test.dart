import 'package:test/test.dart';
import 'package:s3_native_http_client/s3_native_http_client.dart';

import 's3_mock_service.dart';

void main() {
  group('S3MockService Tests', () {
    late S3MockService s3Mock;
    late S3RequestConfiguration config;

    setUp(() {
      config = S3RequestConfiguration(
        accessKey: 'test-key',
        secretKey: 'test-secret',
        endpoint: 'https://s3.example.com',
        region: 'us-east-1',
        bucket: 'test-bucket',
      );
      s3Mock = S3MockService(configuration: config);
    });

    tearDown(() async {
      await s3Mock.clear();
    });

    test('uploadBytes and exists', () async {
      final data = 'test content'.codeUnits;
      final uploaded = await s3Mock.uploadBytes('test.txt', data);
      expect(uploaded, isTrue);

      final exists = await s3Mock.exists('test.txt');
      expect(exists, isTrue);
    });

    test('download returns uploaded content', () async {
      final data = 'hello world'.codeUnits;
      await s3Mock.uploadBytes('file.txt', data);

      final downloaded = await s3Mock.download('file.txt');
      expect(downloaded, isNotNull);
      expect(downloaded, equals(data));
    });

    test('download returns null for non-existent object', () async {
      final downloaded = await s3Mock.download('non-existent.txt');
      expect(downloaded, isNull);
    });

    test('delete removes object', () async {
      final data = 'content'.codeUnits;
      await s3Mock.uploadBytes('delete-me.txt', data);

      final existsBefore = await s3Mock.exists('delete-me.txt');
      expect(existsBefore, isTrue);

      final deleted = await s3Mock.delete('delete-me.txt');
      expect(deleted, isTrue);

      final existsAfter = await s3Mock.exists('delete-me.txt');
      expect(existsAfter, isFalse);
    });

    test('delete returns false for non-existent object', () async {
      final deleted = await s3Mock.delete('non-existent.txt');
      expect(deleted, isFalse);
    });

    test('listObjects returns all objects', () async {
      await s3Mock.uploadBytes('file1.txt', 'data1'.codeUnits);
      await s3Mock.uploadBytes('file2.txt', 'data2'.codeUnits);
      await s3Mock.uploadBytes('file3.txt', 'data3'.codeUnits);

      final objects = await s3Mock.listObjects();
      expect(objects.length, equals(3));
      expect(objects, containsAll(['file1.txt', 'file2.txt', 'file3.txt']));
    });

    test('listObjects with prefix filters correctly', () async {
      await s3Mock.uploadBytes('file1.txt', 'data1'.codeUnits);
      await s3Mock.uploadBytes('file2.txt', 'data2'.codeUnits);
      await s3Mock.uploadBytes('document.txt', 'data3'.codeUnits);

      final filtered = await s3Mock.listObjects(prefix: 'file');
      expect(filtered.length, equals(2));
      expect(filtered, containsAll(['file1.txt', 'file2.txt']));
      expect(filtered, isNot(contains('document.txt')));
    });

    test('getMetadata returns object information', () async {
      final data = 'test data'.codeUnits;
      await s3Mock.uploadBytes('metadata-test.txt', data);

      final metadata = await s3Mock.getMetadata('metadata-test.txt');
      expect(metadata, isNotNull);
      expect(metadata!['key'], equals('metadata-test.txt'));
      expect(metadata['size'], equals(data.length));
      expect(metadata['bucket'], equals('test-bucket'));
      expect(metadata['lastModified'], isNotNull);
    });

    test('getMetadata returns null for non-existent object', () async {
      final metadata = await s3Mock.getMetadata('non-existent.txt');
      expect(metadata, isNull);
    });

    test('getStorageStats returns correct information', () async {
      await s3Mock.uploadBytes('file1.txt', 'data1'.codeUnits);
      await s3Mock.uploadBytes('file2.txt', 'data2'.codeUnits);

      final stats = await s3Mock.getStorageStats();
      expect(stats['objectCount'], equals(2));
      expect(stats['totalSize'], equals(10)); // 'data1' + 'data2'
      expect(stats['bucket'], equals('test-bucket'));
      expect(stats['endpoint'], equals('https://s3.example.com'));
    });

    test('clear removes all objects', () async {
      await s3Mock.uploadBytes('file1.txt', 'data1'.codeUnits);
      await s3Mock.uploadBytes('file2.txt', 'data2'.codeUnits);

      var objects = await s3Mock.listObjects();
      expect(objects.length, equals(2));

      await s3Mock.clear();

      objects = await s3Mock.listObjects();
      expect(objects.length, equals(0));
    });

    test('multiple uploads and downloads', () async {
      final files = {
        'file1.txt': 'content1',
        'file2.txt': 'content2',
        'file3.txt': 'content3',
      };

      for (final entry in files.entries) {
        await s3Mock.uploadBytes(entry.key, entry.value.codeUnits);
      }

      for (final entry in files.entries) {
        final downloaded = await s3Mock.download(entry.key);
        expect(downloaded, isNotNull);
        expect(String.fromCharCodes(downloaded!), equals(entry.value));
      }
    });

    test('storage stats after operations', () async {
      var stats = await s3Mock.getStorageStats();
      expect(stats['objectCount'], equals(0));
      expect(stats['totalSize'], equals(0));

      await s3Mock.uploadBytes('file1.txt', 'hello'.codeUnits);
      stats = await s3Mock.getStorageStats();
      expect(stats['objectCount'], equals(1));
      expect(stats['totalSize'], equals(5));

      await s3Mock.uploadBytes('file2.txt', 'world'.codeUnits);
      stats = await s3Mock.getStorageStats();
      expect(stats['objectCount'], equals(2));
      expect(stats['totalSize'], equals(10));

      await s3Mock.delete('file1.txt');
      stats = await s3Mock.getStorageStats();
      expect(stats['objectCount'], equals(1));
      expect(stats['totalSize'], equals(5));
    });
  });
}
