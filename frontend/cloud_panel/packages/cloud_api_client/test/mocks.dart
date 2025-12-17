import 'package:cloud_api_client/src/token_service.dart';

class FakeTokenService implements TokenService {
  String? _accessToken;
  String? _refreshToken;

  FakeTokenService({String? accessToken, String? refreshToken})
      : _accessToken = accessToken,
        _refreshToken = refreshToken;

  @override
  Future<void> init() async {}

  @override
  Future<String?> get token async => _accessToken;

  @override
  Future<String?> get refreshToken async => _refreshToken;

  @override
  Future<void> loginSuccess(String token, String refreshToken) async {
    _accessToken = token;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
