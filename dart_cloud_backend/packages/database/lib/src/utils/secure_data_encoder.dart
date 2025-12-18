import 'dart:convert';

/// Utility class for encoding/decoding sensitive data
///
/// Currently uses Base64 encoding, but designed to support
/// future cryptographic encryption with developer-specific keys.
///
/// Usage:
/// ```dart
/// // Encode sensitive data before storing
/// final encoded = SecureDataEncoder.encode(jsonEncode(body));
///
/// // Decode when retrieving (only for authorized users)
/// final decoded = SecureDataEncoder.decode(encoded);
/// final body = jsonDecode(decoded);
/// ```
class SecureDataEncoder {
  /// Encodes data to Base64 string
  ///
  /// This is the first layer of protection. Future versions will
  /// add encryption using developer-specific keys before Base64 encoding.
  static String encode(String data) {
    final bytes = utf8.encode(data);
    return base64Encode(bytes);
  }

  /// Encodes a Map to Base64 string
  ///
  /// Converts the map to JSON first, then encodes to Base64.
  static String encodeMap(Map<String, dynamic> data) {
    return encode(jsonEncode(data));
  }

  /// Decodes Base64 string back to original data
  ///
  /// Future versions will decrypt using developer-specific keys
  /// before decoding from Base64.
  static String decode(String encodedData) {
    final bytes = base64Decode(encodedData);
    return utf8.decode(bytes);
  }

  /// Decodes Base64 string back to original data
  ///
  /// Future versions will decrypt using developer-specific keys
  /// before decoding from Base64.
  static String tryDecode(String encodedData) {
    try {
      final bytes = base64Decode(encodedData);
      return utf8.decode(bytes);
    } catch (_) {
      return encodedData;
    }
  }

  /// Decodes Base64 string back to Map
  ///
  /// Decodes from Base64 first, then parses JSON.
  static Map<String, dynamic> decodeMap(String encodedData) {
    return jsonDecode(decode(encodedData)) as Map<String, dynamic>;
  }

  /// Safely encodes data, returns null if input is null
  static String? encodeOrNull(String? data) {
    if (data == null) return null;
    return encode(data);
  }

  /// Safely encodes a Map, returns null if input is null
  static String? encodeMapOrNull(Map<String, dynamic>? data) {
    if (data == null) return null;
    return encodeMap(data);
  }

  /// Safely decodes data, returns null if input is null
  static String? decodeOrNull(String? encodedData) {
    if (encodedData == null) return null;
    return decode(encodedData);
  }

  /// Safely decodes to Map, returns null if input is null
  static Map<String, dynamic>? decodeMapOrNull(String? encodedData) {
    if (encodedData == null) return null;
    return decodeMap(encodedData);
  }

  /// Checks if a string appears to be Base64 encoded
  ///
  /// This is a basic check and may have false positives.
  static bool isEncoded(String data) {
    try {
      base64Decode(data);
      return true;
    } catch (_) {
      return false;
    }
  }
}
