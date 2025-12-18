import 'dart:convert';

String tryDecode(String encodedData) {
  try {
    final bytes = base64Decode(encodedData);
    return utf8.decode(bytes);
  } catch (_) {
    return encodedData;
  }
}
