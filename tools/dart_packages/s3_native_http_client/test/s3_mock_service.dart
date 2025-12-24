import 'dart:io';
import 'package:s3_native_http_client/src/s3_configuration.dart';

class S3MockService {
  final S3RequestConfiguration configuration;
  final Map<String, List<int>> _storage = {};
  final Map<String, DateTime> _metadata = {};

  S3MockService({required this.configuration});

  /// Mock: Check if Object Exists (HEAD Request)
  Future<bool> exists(String objectKey) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _storage.containsKey(objectKey);
  }

  /// Mock: Upload Object (PUT Request)
  Future<bool> upload(String objectKey, File file) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final bytes = await file.readAsBytes();
      _storage[objectKey] = bytes;
      _metadata[objectKey] = DateTime.now();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mock: Upload Object from bytes (PUT Request)
  Future<bool> uploadBytes(String objectKey, List<int> bytes) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      _storage[objectKey] = bytes;
      _metadata[objectKey] = DateTime.now();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mock: Download Object (GET Request)
  Future<List<int>?> download(String objectKey) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _storage[objectKey];
  }

  /// Mock: Delete Object (DELETE Request)
  Future<bool> delete(String objectKey) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_storage.containsKey(objectKey)) {
      _storage.remove(objectKey);
      _metadata.remove(objectKey);
      return true;
    }
    return false;
  }

  /// Mock: List Objects in bucket
  Future<List<String>> listObjects({String? prefix}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final keys = _storage.keys.toList();
    if (prefix != null) {
      return keys.where((key) => key.startsWith(prefix)).toList();
    }
    return keys;
  }

  /// Mock: Get object metadata
  Future<Map<String, dynamic>?> getMetadata(String objectKey) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_storage.containsKey(objectKey)) {
      return {
        'key': objectKey,
        'size': _storage[objectKey]!.length,
        'lastModified': _metadata[objectKey],
        'bucket': configuration.bucket,
      };
    }
    return null;
  }

  /// Mock: Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    await Future.delayed(const Duration(milliseconds: 100));
    int totalSize = 0;
    for (final bytes in _storage.values) {
      totalSize += bytes.length;
    }
    return {
      'objectCount': _storage.length,
      'totalSize': totalSize,
      'bucket': configuration.bucket,
      'endpoint': configuration.endpoint,
    };
  }

  /// Mock: Clear all stored objects
  Future<void> clear() async {
    _storage.clear();
    _metadata.clear();
  }
}
