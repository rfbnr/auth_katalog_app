import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_pair.dart';

abstract interface class TokenStorage {
  Future<TokenPair?> read();
  Future<void> write(TokenPair tokens);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  final FlutterSecureStorage _storage;

  @override
  Future<TokenPair?> read() async {
    final values = await Future.wait([
      _storage.read(key: _accessTokenKey),
      _storage.read(key: _refreshTokenKey),
    ]);
    final accessToken = values[0];
    final refreshToken = values[1];
    if (accessToken == null || refreshToken == null) return null;
    return TokenPair(accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  Future<void> write(TokenPair tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
