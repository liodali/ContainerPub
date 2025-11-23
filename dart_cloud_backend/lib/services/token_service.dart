import 'dart:convert' show base64;
import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as path;

class TokenService {
  static const String _authTokenBoxName = 'auth_tokens';
  static const String _blacklistBoxName = 'blacklist_tokens';
  static const String _refreshTokenBoxName = 'refresh_tokens';
  static const String _tokenLinkBoxName =
      'token_links'; // Maps refreshToken -> accessToken

  late LazyBox<String> _authTokenBox;
  late LazyBox<String> _blacklistBox;
  late LazyBox<String> _refreshTokenBox;
  late LazyBox<String> _tokenLinkBox;

  final String directory = './data';
  final String _keyPath = 'key.txt';

  static TokenService? _instance;

  static TokenService get instance {
    if (_instance == null) {
      _instance = TokenService._internal();
    }
    return _instance!;
  }

  factory TokenService() {
    if (_instance == null) {
      _instance = TokenService._internal();
    }
    return _instance!;
  }

  TokenService._internal();

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    Hive.init(
      '$directory/tokens',
    );
    final cipher = _generateCipher();
    _authTokenBox = await Hive.openLazyBox<String>(
      _authTokenBoxName,
      encryptionCipher: cipher,
    );
    _blacklistBox = await Hive.openLazyBox<String>(
      _blacklistBoxName,
    );
    _refreshTokenBox = await Hive.openLazyBox<String>(
      _refreshTokenBoxName,
      encryptionCipher: cipher,
    );
    _tokenLinkBox = await Hive.openLazyBox<String>(
      _tokenLinkBoxName,
      encryptionCipher: cipher,
    );
  }

  /// Add a token to the valid auth tokens
  Future<void> addAuthToken({
    required String token,
    required String userId,
  }) async {
    if (token.isEmpty || userId.isEmpty) {
      throw ArgumentError('Token and userId must not be empty');
    }
    await _authTokenBox.put(token, userId);
  }

  /// Check if a token is valid (exists in auth_tokens and not in blacklist)
  bool isTokenValid(String token) {
    // Token must exist in auth tokens and not be blacklisted
    return _authTokenBox.containsKey(token) && !_blacklistBox.containsKey(token);
  }

  /// Blacklist a token (invalidate it)
  Future<void> blacklistToken(String token) async {
    await _blacklistBox.put(token, DateTime.now().toIso8601String());
    // Optionally remove from auth tokens
    await _authTokenBox.delete(token);
  }

  /// Remove a token from auth tokens (e.g., on logout)
  Future<void> removeAuthToken(String token) async {
    await _authTokenBox.delete(token);
  }

  /// Check if a token is blacklisted
  bool isTokenBlacklisted(String token) {
    return _blacklistBox.containsKey(token);
  }

  /// Add a refresh token and link it to an access token
  Future<void> addRefreshToken({
    required String refreshToken,
    required String userId,
    required String accessToken,
  }) async {
    if (refreshToken.isEmpty || userId.isEmpty || accessToken.isEmpty) {
      throw ArgumentError('Refresh token, userId, and accessToken must not be empty');
    }
    await _refreshTokenBox.put(refreshToken, userId);
    // Link refresh token to access token
    await _tokenLinkBox.put(refreshToken, accessToken);
  }

  /// Check if refresh token is valid
  bool isRefreshTokenValid(String refreshToken) {
    return _refreshTokenBox.containsKey(refreshToken) &&
        !_blacklistBox.containsKey(refreshToken);
  }

  /// Get user ID from refresh token
  Future<String?> getUserIdFromRefreshToken(String refreshToken) async {
    if (!isRefreshTokenValid(refreshToken)) {
      return null;
    }
    return await _refreshTokenBox.get(refreshToken);
  }

  /// Remove refresh token and its link
  Future<void> removeRefreshToken(String refreshToken) async {
    await _refreshTokenBox.delete(refreshToken);
    await _tokenLinkBox.delete(refreshToken);
  }

  /// Get the current access token linked to a refresh token
  Future<String?> getLinkedAccessToken(String refreshToken) async {
    return await _tokenLinkBox.get(refreshToken);
  }

  /// Update the access token linked to a refresh token
  /// This blacklists the old access token and links the new one
  Future<void> updateLinkedAccessToken({
    required String refreshToken,
    required String newAccessToken,
  }) async {
    // Get the old access token
    final oldAccessToken = await _tokenLinkBox.get(refreshToken);

    // Blacklist the old access token if it exists
    if (oldAccessToken != null && oldAccessToken.isNotEmpty) {
      await blacklistToken(oldAccessToken);
    }

    // Link the new access token to the refresh token
    await _tokenLinkBox.put(refreshToken, newAccessToken);
  }

  /// Close boxes when shutting down
  Future<void> close() async {
    await _authTokenBox.close();
    await _blacklistBox.close();
    await _refreshTokenBox.close();
    await _tokenLinkBox.close();
  }
}

extension on TokenService {
  HiveAesCipher _generateCipher() {
    var context = path.Context(style: path.Style.platform);
    final file = File(
      context.join(
        directory,
        _keyPath,
      ),
    );
    if (file.existsSync()) {
      return _readFromFile(file);
    }
    return _writeFromFile(file);
  }

  HiveAesCipher _readFromFile(File file) {
    final decode = base64.decode(file.readAsStringSync());
    return HiveAesCipher(decode);
  }

  HiveAesCipher _writeFromFile(File file) {
    final key = Hive.generateSecureKey();
    file.writeAsStringSync(base64.encode(key));
    return HiveAesCipher(key);
  }
}
