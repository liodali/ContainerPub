import 'package:s3_client_dart/s3_client_dart.dart';

void main() {
  LibraryDownloader.downloadLibrary(
    targetDir: '.',
    platformInfo: PlatformInfo.linux(),
  );
}
