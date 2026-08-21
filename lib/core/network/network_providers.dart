import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../storage/storage_providers.dart';
import 'auth_interceptor.dart';
import 'safe_dio_logger.dart';
import 'session_events.dart';
import 'token_refresh_client.dart';

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

final refreshDioProvider = Provider<Dio>((_) {
  final dio = Dio(_baseOptions());
  dio.interceptors.add(const SafeDioLogger());
  return dio;
});

final tokenRefreshClientProvider = Provider<TokenRefreshClient>(
  (ref) => DioTokenRefreshClient(ref.watch(refreshDioProvider)),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokenStorage: ref.watch(tokenStorageProvider),
      tokenRefreshClient: ref.watch(tokenRefreshClientProvider),
      sessionEvents: ref.watch(sessionEventsProvider),
    ),
  );
  dio.interceptors.add(const SafeDioLogger());
  return dio;
});

BaseOptions _baseOptions() => BaseOptions(
  baseUrl: Env.apiBaseUrl,
  connectTimeout: const Duration(seconds: 35),
  receiveTimeout: const Duration(seconds: 35),
  sendTimeout: const Duration(seconds: 35),
  contentType: Headers.jsonContentType,
  responseType: ResponseType.json,
);
