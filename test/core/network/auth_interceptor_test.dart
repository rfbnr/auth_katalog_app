import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:auth_katalog_app/core/network/auth_interceptor.dart';
import 'package:auth_katalog_app/core/network/request_metadata.dart';
import 'package:auth_katalog_app/core/network/session_events.dart';
import 'package:auth_katalog_app/core/network/token_refresh_client.dart';
import 'package:auth_katalog_app/core/storage/token_pair.dart';
import 'package:auth_katalog_app/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenRefreshClient extends Mock implements TokenRefreshClient {}

class _MemoryTokenStorage implements TokenStorage {
  _MemoryTokenStorage(this.tokens);

  TokenPair? tokens;
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls++;
    tokens = null;
  }

  @override
  Future<TokenPair?> read() async => tokens;

  @override
  Future<void> write(TokenPair tokens) async => this.tokens = tokens;
}

class _ProtectedAdapter implements HttpClientAdapter {
  int successfulRequests = 0;
  final authorizations = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    authorizations.add(options.headers['Authorization']);
    final authorized = options.headers['Authorization'] == 'Bearer new-access';
    if (!authorized) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Token Expired!'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    successfulRequests++;
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final protectedOptions = Options(
    extra: <String, Object>{RequestMetadata.requiresAuthentication: true},
  );

  test(
    '3 concurrent 401 responses trigger one refresh and all retry',
    () async {
      final refreshClient = _MockTokenRefreshClient();
      final storage = _MemoryTokenStorage(
        const TokenPair(
          accessToken: 'expired-access',
          refreshToken: 'valid-refresh',
        ),
      );
      final events = SessionEvents();
      final adapter = _ProtectedAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;

      when(() => refreshClient.refresh(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return const TokenPair(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
        );
      });
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          tokenStorage: storage,
          tokenRefreshClient: refreshClient,
          sessionEvents: events,
        ),
      );

      final responses = await Future.wait([
        dio.get<Map<String, dynamic>>(
          '/protected/1',
          options: protectedOptions,
        ),
        dio.get<Map<String, dynamic>>(
          '/protected/2',
          options: protectedOptions,
        ),
        dio.get<Map<String, dynamic>>(
          '/protected/3',
          options: protectedOptions,
        ),
      ]);

      expect(
        responses.map((response) => response.statusCode),
        everyElement(200),
      );
      expect(adapter.successfulRequests, 3);
      verify(() => refreshClient.refresh(any())).called(1);
      expect(storage.tokens?.accessToken, 'new-access');
      expect(storage.tokens?.refreshToken, 'new-refresh');
      await events.dispose();
    },
  );

  test('concurrent failed refresh clears and emits expiration once', () async {
    final refreshClient = _MockTokenRefreshClient();
    final storage = _MemoryTokenStorage(
      const TokenPair(accessToken: 'expired', refreshToken: 'invalid'),
    );
    final events = SessionEvents();
    var expirationEvents = 0;
    final subscription = events.expired.listen((_) => expirationEvents++);
    final adapter = _ProtectedAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    when(() => refreshClient.refresh(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      throw StateError('invalid');
    });
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStorage: storage,
        tokenRefreshClient: refreshClient,
        sessionEvents: events,
      ),
    );

    final results = await Future.wait(
      List.generate(3, (index) async {
        try {
          await dio.get<Object?>(
            '/protected/$index',
            options: protectedOptions,
          );
          return null;
        } on Object catch (error) {
          return error;
        }
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(results, everyElement(isA<DioException>()));
    expect(storage.tokens, isNull);
    expect(storage.clearCalls, 1);
    expect(expirationEvents, 1);
    verify(() => refreshClient.refresh(any())).called(1);
    await subscription.cancel();
    await events.dispose();
  });

  test('public 401 does not attach bearer or trigger refresh', () async {
    final refreshClient = _MockTokenRefreshClient();
    final storage = _MemoryTokenStorage(
      const TokenPair(accessToken: 'expired', refreshToken: 'valid'),
    );
    final events = SessionEvents();
    final adapter = _ProtectedAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStorage: storage,
        tokenRefreshClient: refreshClient,
        sessionEvents: events,
      ),
    );

    await expectLater(
      dio.get<Object?>('/products'),
      throwsA(isA<DioException>()),
    );

    verifyNever(() => refreshClient.refresh(any()));
    expect(adapter.authorizations, [null]);
    expect(storage.tokens?.accessToken, 'expired');
    expect(storage.clearCalls, 0);
    await events.dispose();
  });
}
