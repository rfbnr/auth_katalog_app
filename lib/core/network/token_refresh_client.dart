import 'package:dio/dio.dart';

import '../storage/token_pair.dart';

abstract interface class TokenRefreshClient {
  Future<TokenPair> refresh(String refreshToken);
}

class DioTokenRefreshClient implements TokenRefreshClient {
  DioTokenRefreshClient(this._dio);

  final Dio _dio;

  @override
  Future<TokenPair> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: <String, Object>{'refreshToken': refreshToken, 'expiresInMins': 1},
    );
    final data = response.data;
    final accessToken = data?['accessToken'];
    final nextRefreshToken = data?['refreshToken'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        nextRefreshToken is! String ||
        nextRefreshToken.isEmpty) {
      throw const FormatException('Respons refresh token tidak valid.');
    }
    return TokenPair(accessToken: accessToken, refreshToken: nextRefreshToken);
  }
}
