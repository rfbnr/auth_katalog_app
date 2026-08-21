import 'package:auth_katalog_app/core/error/failure.dart';
import 'package:auth_katalog_app/features/auth/di/auth_providers.dart';
import 'package:auth_katalog_app/features/auth/domain/entities/user_entity.dart';
import 'package:auth_katalog_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_katalog_app/features/profile/presentation/controllers/profile_controller.dart';
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
  image: 'https://example.test/avatar.png',
);

class _SlowAuthRepository implements AuthRepository {
  int profileCalls = 0;

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    profileCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return const Right(_user);
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> logout() async => const Right(unit);

  @override
  Future<Either<Failure, bool>> restoreSession() async => const Right(true);
}

String _renderedBranch(AsyncValue<UserEntity> value) => value.when(
  data: (user) => 'data:${user.firstName}',
  error: (_, _) => 'error',
  loading: () => 'loading',
);

void main() {
  test('refresh shows the skeleton while in flight', () async {
    final repository = _SlowAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(profileControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(profileControllerProvider.future);

    final pending = container
        .read(profileControllerProvider.notifier)
        .refresh();
    final midFlight = container.read(profileControllerProvider);

    expect(
      _renderedBranch(midFlight),
      'loading',
      reason:
          'a pull-to-refresh is meant to show the same shimmer as the first '
          'load, so refresh must pass through AsyncLoading',
    );

    await pending;
    expect(repository.profileCalls, 2);
    expect(
      _renderedBranch(container.read(profileControllerProvider)),
      'data:Emily',
    );
  });

  test(
    'a failed refresh surfaces the failure with retry still available',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FailingAfterFirstCall()),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        profileControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(profileControllerProvider.future);

      await container.read(profileControllerProvider.notifier).refresh();

      final state = container.read(profileControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NoInternetFailure>());
    },
  );
}

class _FailingAfterFirstCall implements AuthRepository {
  bool _first = true;

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    if (_first) {
      _first = false;
      return const Right(_user);
    }
    return const Left(NoInternetFailure());
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> logout() async => const Right(unit);

  @override
  Future<Either<Failure, bool>> restoreSession() async => const Right(true);
}
