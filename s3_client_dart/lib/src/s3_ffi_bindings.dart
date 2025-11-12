import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

/// FFI bindings for the Go S3 client shared library
class S3FFIBindings {
  late final DynamicLibrary _dylib;
  final String? _customLibraryPath;
  
  // Function signatures
  late final void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>) _initBucket;
  late final Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>) _upload;
  late final Pointer<Utf8> Function() _list;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _delete;
  late final Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>) _download;
  late final Pointer<Utf8> Function(Pointer<Utf8>, int) _getPresignedUrl;

  /// Create S3FFIBindings with optional custom library path
  /// 
  /// [libraryPath] - Optional custom path to the Go shared library.
  /// If not provided, will use platform-specific default paths.
  S3FFIBindings({String? libraryPath}) : _customLibraryPath = libraryPath {
    _dylib = _loadLibrary();
    _initBucket = _dylib
        .lookup<NativeFunction<Void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)>>('initBucket')
        .asFunction();
    _upload = _dylib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)>>('upload')
        .asFunction();
    _list = _dylib
        .lookup<NativeFunction<Pointer<Utf8> Function()>>('list')
        .asFunction();
    _delete = _dylib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>('delete')
        .asFunction();
    _download = _dylib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)>>('download')
        .asFunction();
    _getPresignedUrl = _dylib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>, Int32)>>('getPresignedUrl')
        .asFunction();
  }

  /// Load the appropriate shared library based on the platform
  /// 
  /// Uses [_customLibraryPath] if provided, otherwise uses platform-specific defaults.
  DynamicLibrary _loadLibrary() {
    // If custom path is provided, use it directly
    final customPath = _customLibraryPath;
    if (customPath != null && customPath.isNotEmpty) {
      return DynamicLibrary.open(customPath);
    }

    // Use platform-specific default paths
    if (Platform.isMacOS) {
      return DynamicLibrary.open('go_ffi/darwin/s3_client_dart.dylib');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('go_ffi/linux/s3_client_dart.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('go_ffi/windows/s3_client_dart.dll');
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }
  }

  /// Initialize the S3 bucket with credentials
  void initBucket(String bucketName, String accessKeyId, String secretAccessKey, String sessionToken) {
    final bucketNamePtr = bucketName.toNativeUtf8();
    final accessKeyIdPtr = accessKeyId.toNativeUtf8();
    final secretAccessKeyPtr = secretAccessKey.toNativeUtf8();
    final sessionTokenPtr = sessionToken.toNativeUtf8();

    try {
      _initBucket(bucketNamePtr, accessKeyIdPtr, secretAccessKeyPtr, sessionTokenPtr);
    } finally {
      malloc.free(bucketNamePtr);
      malloc.free(accessKeyIdPtr);
      malloc.free(secretAccessKeyPtr);
      malloc.free(sessionTokenPtr);
    }
  }

  /// Upload a file to S3
  String upload(String filePath, String objectKey) {
    final filePathPtr = filePath.toNativeUtf8();
    final objectKeyPtr = objectKey.toNativeUtf8();

    try {
      final resultPtr = _upload(filePathPtr, objectKeyPtr);
      final result = resultPtr.toDartString();
      malloc.free(resultPtr);
      return result;
    } finally {
      malloc.free(filePathPtr);
      malloc.free(objectKeyPtr);
    }
  }

  /// List all objects in the bucket
  String list() {
    final resultPtr = _list();
    final result = resultPtr.toDartString();
    malloc.free(resultPtr);
    return result;
  }

  /// Delete an object from S3
  String delete(String objectKey) {
    final objectKeyPtr = objectKey.toNativeUtf8();

    try {
      final resultPtr = _delete(objectKeyPtr);
      final result = resultPtr.toDartString();
      malloc.free(resultPtr);
      return result;
    } finally {
      malloc.free(objectKeyPtr);
    }
  }

  /// Download an object from S3 to a local file
  String download(String objectKey, String destinationPath) {
    final objectKeyPtr = objectKey.toNativeUtf8();
    final destinationPathPtr = destinationPath.toNativeUtf8();

    try {
      final resultPtr = _download(objectKeyPtr, destinationPathPtr);
      final result = resultPtr.toDartString();
      malloc.free(resultPtr);
      return result;
    } finally {
      malloc.free(objectKeyPtr);
      malloc.free(destinationPathPtr);
    }
  }

  /// Get a presigned URL for an object
  String getPresignedUrl(String objectKey, int expirationSeconds) {
    final objectKeyPtr = objectKey.toNativeUtf8();

    try {
      final resultPtr = _getPresignedUrl(objectKeyPtr, expirationSeconds);
      final result = resultPtr.toDartString();
      malloc.free(resultPtr);
      return result;
    } finally {
      malloc.free(objectKeyPtr);
    }
  }
}
