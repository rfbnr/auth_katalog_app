import 'package:auth_katalog_app/core/error/failure.dart';
import 'package:auth_katalog_app/core/storage/token_pair.dart';
import 'package:auth_katalog_app/core/storage/token_storage.dart';
import 'package:auth_katalog_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:auth_katalog_app/features/auth/data/models/request/login_request_model.dart';
import 'package:auth_katalog_app/features/auth/data/models/response/auth_response_model.dart';
import 'package:auth_katalog_app/features/auth/data/models/response/user_response_model.dart';
import 'package:auth_katalog_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthRemoteDatasource {}

class _MemoryTokenStorage implements TokenStorage {
  TokenPair? tokens;

  @override
  Future<void> clear() async => tokens = null;

  @override
  Future<TokenPair?> read() async => tokens;

  @override
  Future<void> write(TokenPair tokens) async => this.tokens = tokens;
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const LoginRequestModel(username: 'fallback', password: 'fallback'),
    );
  });

  test('login stores both tokens and returns domain user', () async {
    final api = _MockAuthApi();
    final storage = _MemoryTokenStorage();
    final repository = AuthRepositoryImpl(
      authRemoteDatasource: api,
      tokenStorage: storage,
    );
    when(() => api.login(any())).thenAnswer(
      (_) async => const AuthResponseModel(
        id: 1,
        username: 'emilys',
        email: 'emily@example.com',
        firstName: 'Emily',
        lastName: 'Johnson',
        gender: 'female',
        image: 'https://example.com/avatar.png',
        accessToken: 'access',
        refreshToken: 'refresh',
      ),
    );

    final result = await repository.login(
      username: ' emilys ',
      password: 'emilyspass',
    );

    expect(result.isRight(), isTrue);
    expect(
      result.getOrElse(() => throw StateError('missing')).username,
      'emilys',
    );
    expect(storage.tokens?.accessToken, 'access');
    expect(storage.tokens?.refreshToken, 'refresh');
    final captured = verify(() => api.login(captureAny())).captured.single;
    expect(captured, isA<LoginRequestModel>());
    expect((captured as LoginRequestModel).expiresInMins, 1);
    expect(captured.username, 'emilys');
  });

  test('login maps connection errors to NoInternetFailure', () async {
    final api = _MockAuthApi();
    final repository = AuthRepositoryImpl(
      authRemoteDatasource: api,
      tokenStorage: _MemoryTokenStorage(),
    );
    when(() => api.login(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await repository.login(username: 'user', password: 'pass');

    expect(
      result.swap().getOrElse(() => throw StateError('missing')),
      isA<NoInternetFailure>(),
    );
  });

  test(
    'restore session checks secure tokens without calling auth/me',
    () async {
      final api = _MockAuthApi();
      final storage = _MemoryTokenStorage()
        ..tokens = const TokenPair(
          accessToken: 'stored-access',
          refreshToken: 'stored-refresh',
        );
      final repository = AuthRepositoryImpl(
        authRemoteDatasource: api,
        tokenStorage: storage,
      );

      final result = await repository.restoreSession();

      expect(result.getOrElse(() => false), isTrue);
      verifyNever(api.getCurrentUser);
    },
  );

  test(
    'getCurrentUser carries the profile fields login cannot supply',
    () async {
      final api = _MockAuthApi();
      final repository = AuthRepositoryImpl(
        authRemoteDatasource: api,
        tokenStorage: _MemoryTokenStorage(),
      );
      when(api.getCurrentUser).thenAnswer(
        (_) async => const UserResponseModel(
          id: 1,
          username: 'emilys',
          email: 'emily@example.com',
          firstName: 'Emily',
          lastName: 'Johnson',
          gender: 'female',
          image: 'https://example.com/avatar.png',
          age: 28,
          phone: '+81 965-431-3024',
          birthDate: '1996-05-30',
          university: 'University of Wisconsin',
          role: 'admin',
        ),
      );

      final user = (await repository.getCurrentUser()).getOrElse(
        () => throw StateError('missing'),
      );

      expect(user.age, 28);
      expect(user.phone, '+81 965-431-3024');
      expect(user.birthDate, '1996-05-30');
      expect(user.university, 'University of Wisconsin');
      expect(user.role, 'admin');
    },
  );

  test('login yields a user without the auth/me-only fields', () async {
    final api = _MockAuthApi();
    final repository = AuthRepositoryImpl(
      authRemoteDatasource: api,
      tokenStorage: _MemoryTokenStorage(),
    );
    when(() => api.login(any())).thenAnswer(
      (_) async => const AuthResponseModel(
        id: 1,
        username: 'emilys',
        email: 'emily@example.com',
        firstName: 'Emily',
        lastName: 'Johnson',
        gender: 'female',
        image: 'https://example.com/avatar.png',
        accessToken: 'access',
        refreshToken: 'refresh',
      ),
    );

    final user = (await repository.login(
      username: 'emilys',
      password: 'emilyspass',
    )).getOrElse(() => throw StateError('missing'));

    expect(user.username, 'emilys');
    expect(
      [user.age, user.phone, user.birthDate, user.university, user.role],
      everyElement(isNull),
      reason: 'the login response has no such fields to map',
    );
  });
}
