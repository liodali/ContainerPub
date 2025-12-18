import 'package:cloud_panel/common/web_url_platform/stub.dart'
    if (dart.library.io) 'package:cloud_panel/common/web_url_platform/io_url.dart'
    if (dart.library.html) 'package:cloud_panel/common/web_url_platform/web_url.dart';

class PlatformUrl {
  static void useWebUrlStrategy() {
    useWebUrl();
  }
}
