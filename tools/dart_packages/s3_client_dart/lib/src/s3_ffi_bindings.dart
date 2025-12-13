import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'library_downloader.dart';

/// FFI bindings for the Go S3 client shared library
class S3FFIBindings {
  late final DynamicLibrary _dylib;
  final String? _customLibraryPath;
  final bool _autoDownload;

  // Function signatures
  late final void Function(
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
  )
  _initBucket;
  late final Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>) _upload;
  late final Pointer<Utf8> Function() _list;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _delete;
  late final Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>) _download;
  late final Pointer<Utf8> Function(Pointer<Utf8>, int) _getPresignedUrl;
  late final int Function(Pointer<Utf8>) _checkKeyBucketExist;

  /// Create S3FFIBindings with optional custom library path
  ///
  /// [libraryPath] - Optional custom path to the Go shared library.
  /// If not provided, will use platform-specific default paths.
  /// [autoDownload] - If true, automatically download library from GitHub releases if not found.
  S3FFIBindings({
    String? libraryPath,
    bool autoDownload = true,
  }) : _customLibraryPath = libraryPath,
       _autoDownload = autoDownload {
    _dylib = _loadLibrary();
    _initBucket = _dylib
        .lookup<
          NativeFunction<
            Void Function(
              Pointer<Utf8>,
              Pointer<Utf8>,
              Pointer<Utf8>,
              Pointer<Utf8>,
              Pointer<Utf8>,
              Pointer<Utf8>,
              Pointer<Utf8>,
            )
          >
        >('initBucket')
        .asFunction();
    _upload = _dylib
        .lookup<
          NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)>
        >('upload')
        .asFunction();
    _list = _dylib
        .lookup<NativeFunction<Pointer<Utf8> Function()>>('list')
        .asFunction();
    _delete = _dylib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>('delete')
        .asFunction();
    _download = _dylib
        .lookup<
          NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)>
        >('download')
        .asFunction();
    _getPresignedUrl = _dylib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>, Int32)>>(
          'getPresignedUrl',
        )
        .asFunction();
    _checkKeyBucketExist = _dylib
        .lookup<NativeFunction<Int32 Function(Pointer<Utf8>)>>(
          'checkKeyBucketExist',
        )
        .asFunction();
  }

  /// Load the appropriate shared library based on the platform
  ///
  /// Uses [_customLibraryPath] if provided, otherwise uses platform-specific defaults.
  /// If auto-download is enabled and library is not found, downloads from GitHub releases.
  DynamicLibrary _loadLibrary() {
    // If custom path is provided, use it directly
    final customPath = _customLibraryPath;
    if (customPath != null && customPath.isNotEmpty) {
      final fileS3Lib = File(customPath);
      if (fileS3Lib.existsSync()) {
        ///TODO: note we should do build amd64,arm64
        return DynamicLibrary.open(fileS3Lib.path);
      } else if (!_autoDownload) {
        throw Exception('Library not found at: $customPath');
      }
    }

    // Try platform-specific default paths first
    String defaultPath;
    if (Platform.isMacOS) {
      defaultPath = 'go_ffi/darwin/s3_client_dart.dylib';
    } else if (Platform.isLinux) {
      defaultPath = 'go_ffi/linux/s3_client_dart.so';
    } else if (Platform.isWindows) {
      defaultPath = 'go_ffi/windows/s3_client_dart.dll';
    } else {
      throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}',
      );
    }

    // Try to load from default path
    if (File(defaultPath).existsSync()) {
      return DynamicLibrary.open(defaultPath);
    }

    // If auto-download is disabled, throw error
    if (!_autoDownload) {
      throw Exception(
        'Library not found at: $defaultPath\n'
        'Set autoDownload: true to automatically download from GitHub releases.',
      );
    }

    // Auto-download from GitHub releases
    print('Library not found locally, downloading from GitHub releases...');
    try {
      // This is synchronous for simplicity - in production you might want async initialization
      final downloadedPath = _downloadLibrarySync();
      return DynamicLibrary.open(downloadedPath);
    } catch (e) {
      throw Exception(
        'Failed to download library: $e\n'
        'You can manually download from: '
        'https://github.com/liodali/ContainerPub/releases',
      );
    }
  }

  /// Synchronous wrapper for library download
  String _downloadLibrarySync() {
    // Use a simple synchronous approach
    String? downloadedPath;
    Exception? error;

    LibraryDownloader.downloadLibrary()
        .then((path) {
          downloadedPath = path;
        })
        .catchError((e) {
          error = e as Exception;
        });

    // Wait for download to complete (simple polling)
    final startTime = DateTime.now();
    while (downloadedPath == null && error == null) {
      if (DateTime.now().difference(startTime).inSeconds > 60) {
        throw Exception('Download timeout after 60 seconds');
      }
      sleep(Duration(milliseconds: 100));
    }

    if (error != null) {
      throw error!;
    }

    return downloadedPath!;
  }

  /// Initialize the S3 bucket with credentials, region, and endpoint
  void initBucket({
    required String endpoint,
    required String bucketName,
    required String accessKeyId,
    required String secretAccessKey,
    required String sessionToken,
    required String region,
    required String accountId,
  }) {
    final endpointPtr = endpoint.toNativeUtf8();
    final bucketNamePtr = bucketName.toNativeUtf8();
    final accessKeyIdPtr = accessKeyId.toNativeUtf8();
    final secretAccessKeyPtr = secretAccessKey.toNativeUtf8();
    final sessionTokenPtr = sessionToken.toNativeUtf8();
    final regionPtr = region.toNativeUtf8();
    final accountIdPtr = accountId.toNativeUtf8();

    try {
      _initBucket(
        endpointPtr,
        bucketNamePtr,
        accessKeyIdPtr,
        secretAccessKeyPtr,
        sessionTokenPtr,
        regionPtr,
        accountIdPtr,
      );
    } finally {
      malloc.free(endpointPtr);
      malloc.free(bucketNamePtr);
      malloc.free(accessKeyIdPtr);
      malloc.free(secretAccessKeyPtr);
      malloc.free(sessionTokenPtr);
      malloc.free(regionPtr);
      malloc.free(accountIdPtr);
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

  /// Check if an object exists in the bucket
  bool isKeyBucketExist(String objectKey) {
    final objectKeyPtr = objectKey.toNativeUtf8();

    try {
      final result = _checkKeyBucketExist(objectKeyPtr);
      return result == 1;
    } finally {
      malloc.free(objectKeyPtr);
    }
  }
}
