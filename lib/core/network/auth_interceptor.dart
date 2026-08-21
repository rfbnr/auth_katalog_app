import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_pair.dart';
import '../storage/token_storage.dart';
import 'request_metadata.dart';
import 'session_events.dart';
import 'token_refresh_client.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    required TokenRefreshClient tokenRefreshClient,
    required SessionEvents sessionEvents,
  }) : this._(dio, tokenStorage, tokenRefreshClient, sessionEvents);

  AuthInterceptor._(
    this._dio,
    this._tokenStorage,
    this._tokenRefreshClient,
    this._sessionEvents,
  );

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final TokenRefreshClient _tokenRefreshClient;
  final SessionEvents _sessionEvents;
  Future<TokenPair>? _refreshInFlight;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_requiresAuthentication(options)) {
      handler.next(options);
      return;
    }

    try {
      final tokens = await _tokenStorage.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
      handler.next(options);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        _requiresAuthentication(request) &&
        request.extra[RequestMetadata.authenticationRetried] != true;

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    try {
      final tokens = await _refreshSingleFlight();
      request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      request.extra[RequestMetadata.authenticationRetried] = true;

      final response = await _dio.fetch<Object?>(request);
      handler.resolve(response);
    } on Object {
      handler.next(err);
    }
  }

  Future<TokenPair> _refreshSingleFlight() async {
    final active = _refreshInFlight;
    if (active != null) return active;

    final refresh = _performRefresh();
    _refreshInFlight = refresh;

    try {
      return await refresh;
    } finally {
      if (identical(_refreshInFlight, refresh)) _refreshInFlight = null;
    }
  }

  Future<TokenPair> _performRefresh() async {
    try {
      final current = await _tokenStorage.read();
      if (current == null) throw StateError('Refresh token is unavailable');
      final tokens = await _tokenRefreshClient.refresh(current.refreshToken);
      await _tokenStorage.write(tokens);
      return tokens;
    } on Object {
      try {
        await _tokenStorage.clear();
      } finally {
        _sessionEvents.notifyExpired();
      }
      rethrow;
    }
  }

  bool _requiresAuthentication(RequestOptions options) =>
      options.extra[RequestMetadata.requiresAuthentication] == true &&
      options.extra[RequestMetadata.skipAuthentication] != true;
}
