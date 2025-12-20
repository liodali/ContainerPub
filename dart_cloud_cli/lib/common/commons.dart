import 'dart:convert';

import 'package:dart_cloud_cli/services/api_key_storage.dart';

String tryDecode(String encodedData) {
  try {
    final bytes = base64Decode(encodedData);
    return utf8.decode(bytes);
  } catch (_) {
    return encodedData;
  }
}

extension ApiKeyStorageDataExtension on ApiKeyStorageData {
  ApiKeyStorageData setUUID({
    String? uuid,
    
  }){
    return (
      uuid: uuid ?? this.uuid,
      privateKey: this.privateKey,
    );
  }
}