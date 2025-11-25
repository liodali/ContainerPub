import 'dart:convert' show base64, utf8;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as path;

class TokenService {
  static const String _authTokenBoxName = 'auth_tokens';
  static const String _blacklistBoxName = 'blacklist_tokens';
  static const String _refreshTokenBoxName = 'refresh_tokens';
  static const String _tokenLinkBoxName = 'token_links';

  /// Stores userId -> List<String> of valid access token hashes
  late LazyBox<List<dynamic>> _authTokenBox;

  /// Stores token hash -> timestamp (blacklisted tokens)
  late LazyBox<String> _blacklistBox;

  /// Stores refresh token hash -> userId
  late LazyBox<String> _refreshTokenBox;

  /// Stores refresh token hash -> access token hash
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
    _authTokenBox = await Hive.openLazyBox<List<dynamic>>(
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

  /// Generate a SHA-256 hash of the token for storage
  String _hashToken(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Add a token to the user's whitelist
  Future<void> addAuthToken({
    required String token,
    required String userId,
  }) async {
    if (token.isEmpty || userId.isEmpty) {
      throw ArgumentError('Token and userId must not be empty');
    }
    final tokenHash = _hashToken(token);
    final existingTokens = await _authTokenBox.get(userId);
    final tokenList = existingTokens?.cast<String>().toList() ?? <String>[];

    if (!tokenList.contains(tokenHash)) {
      tokenList.add(tokenHash);
      await _authTokenBox.put(userId, tokenList);
    }
  }

  /// Check if a token is valid (exists in user's whitelist and not blacklisted)
  Future<bool> isTokenValid(String token, String userId) async {
    final tokenHash = _hashToken(token);

    // Check if blacklisted first
    if (_blacklistBox.containsKey(tokenHash)) {
      return false;
    }

    // Check if token exists in user's whitelist
    final existingTokens = await _authTokenBox.get(userId);
    if (existingTokens == null) {
      return false;
    }

    final tokenList = existingTokens.cast<String>().toList();
    return tokenList.contains(tokenHash);
  }

  /// Blacklist a token (invalidate it)
  Future<void> blacklistToken(String token, {String? userId}) async {
    final tokenHash = _hashToken(token);
    await _blacklistBox.put(tokenHash, DateTime.now().toIso8601String());

    // Remove from user's whitelist if userId is provided
    if (userId != null) {
      await removeAuthToken(token, userId: userId);
    }
  }

  /// Remove a token from user's whitelist
  Future<void> removeAuthToken(String token, {required String userId}) async {
    final tokenHash = _hashToken(token);
    final existingTokens = await _authTokenBox.get(userId);

    if (existingTokens != null) {
      final tokenList = existingTokens.cast<String>().toList();
      tokenList.remove(tokenHash);
      await _authTokenBox.put(userId, tokenList);
    }
  }

  /// Check if a token is blacklisted
  bool isTokenBlacklisted(String token) {
    final tokenHash = _hashToken(token);
    return _blacklistBox.containsKey(tokenHash);
  }

  /// Remove all tokens for a user (e.g., on logout from all devices)
  Future<void> removeAllUserTokens(String userId) async {
    await _authTokenBox.delete(userId);
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
    final refreshHash = _hashToken(refreshToken);
    final accessHash = _hashToken(accessToken);

    await _refreshTokenBox.put(refreshHash, userId);
    // Link refresh token hash to access token hash
    await _tokenLinkBox.put(refreshHash, accessHash);
  }

  /// Check if refresh token is valid
  bool isRefreshTokenValid(String refreshToken) {
    final refreshHash = _hashToken(refreshToken);
    return _refreshTokenBox.containsKey(refreshHash) &&
        !_blacklistBox.containsKey(refreshHash);
  }

  /// Get user ID from refresh token
  Future<String?> getUserIdFromRefreshToken(String refreshToken) async {
    if (!isRefreshTokenValid(refreshToken)) {
      return null;
    }
    final refreshHash = _hashToken(refreshToken);
    return await _refreshTokenBox.get(refreshHash);
  }

  /// Remove refresh token and its link
  Future<void> removeRefreshToken(String refreshToken) async {
    final refreshHash = _hashToken(refreshToken);
    await _refreshTokenBox.delete(refreshHash);
    await _tokenLinkBox.delete(refreshHash);
  }

  /// Get the current access token hash linked to a refresh token
  Future<String?> getLinkedAccessTokenHash(String refreshToken) async {
    final refreshHash = _hashToken(refreshToken);
    return await _tokenLinkBox.get(refreshHash);
  }

  /// Update the access token linked to a refresh token
  /// This blacklists the old access token and links the new one
  Future<void> updateLinkedAccessToken({
    required String refreshToken,
    required String newAccessToken,
    required String userId,
  }) async {
    final refreshHash = _hashToken(refreshToken);
    final newAccessHash = _hashToken(newAccessToken);

    // Get the old access token hash
    final oldAccessHash = await _tokenLinkBox.get(refreshHash);

    // Blacklist the old access token hash if it exists
    if (oldAccessHash != null && oldAccessHash.isNotEmpty) {
      await _blacklistBox.put(oldAccessHash, DateTime.now().toIso8601String());
      // Remove from user's whitelist
      final existingTokens = await _authTokenBox.get(userId);
      if (existingTokens != null) {
        final tokenList = existingTokens.cast<String>().toList();
        tokenList.remove(oldAccessHash);
        await _authTokenBox.put(userId, tokenList);
      }
    }

    // Link the new access token hash to the refresh token
    await _tokenLinkBox.put(refreshHash, newAccessHash);
  }

  /// Blacklist refresh token
  Future<void> blacklistRefreshToken(String refreshToken) async {
    final refreshHash = _hashToken(refreshToken);
    await _blacklistBox.put(refreshHash, DateTime.now().toIso8601String());
    await removeRefreshToken(refreshToken);
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
    print("Generating new key...");
    file.createSync(recursive: true);
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
