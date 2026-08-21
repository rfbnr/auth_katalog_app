import 'dart:async';

import 'package:auth_katalog_app/core/error/failure.dart';
import 'package:auth_katalog_app/features/auth/di/auth_providers.dart';
import 'package:auth_katalog_app/features/auth/domain/entities/user_entity.dart';
import 'package:auth_katalog_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_katalog_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:auth_katalog_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = UserEntity(
  id: 1,
  username: 'emilys',
  email: 'emily@example.com',
  firstName: 'Emily',
  lastName: 'Johnson',
  gender: 'female',
  image: 'https://example.com/avatar.png',
);

class _FakeAuthRepository implements AuthRepository {
  final loginResult = Completer<Either<Failure, UserEntity>>();

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async =>
      const Right(_user);

  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  }) => loginResult.future;

  @override
  Future<Either<Failure, Unit>> logout() async => const Right(unit);

  @override
  Future<Either<Failure, bool>> restoreSession() async => const Right(false);
}

void main() {
  test('login loading and failure stay outside session state', () async {
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        sessionStartupDelayProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    await container.read(loginControllerProvider.future);
    final subscription = container.listen(loginControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    final submission = container
        .read(loginControllerProvider.notifier)
        .submit(username: 'emilys', password: 'wrong');

    expect(container.read(loginControllerProvider).isLoading, isTrue);
    expect(container.read(authControllerProvider), const AsyncData(false));

    repository.loginResult.complete(
      const Left(UnauthorizedFailure('Kredensial salah.')),
    );
    await submission;

    expect(container.read(loginControllerProvider).hasError, isTrue);
    expect(container.read(authControllerProvider), const AsyncData(false));
  });

  test('successful login changes session to authenticated', () async {
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        sessionStartupDelayProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    await container.read(loginControllerProvider.future);
    final subscription = container.listen(loginControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    final submission = container
        .read(loginControllerProvider.notifier)
        .submit(username: 'emilys', password: 'emilyspass');
    repository.loginResult.complete(const Right(_user));
    await submission;

    expect(
      container.read(loginControllerProvider),
      const AsyncData<void>(null),
    );
    expect(container.read(authControllerProvider).value, isTrue);
  });
}
