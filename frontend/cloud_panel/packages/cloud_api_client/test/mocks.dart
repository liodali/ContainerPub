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
  String get token => _accessToken!;

  @override
  String? get refreshToken => _refreshToken;

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
