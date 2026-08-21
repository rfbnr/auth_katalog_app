import 'package:auth_katalog_app/app/router/app_router.dart';
import 'package:auth_katalog_app/core/error/failure.dart';
import 'package:auth_katalog_app/features/auth/di/auth_providers.dart';
import 'package:auth_katalog_app/features/auth/domain/entities/user_entity.dart';
import 'package:auth_katalog_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_katalog_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:auth_katalog_app/features/auth/presentation/pages/login_page.dart';
import 'package:auth_katalog_app/features/product/di/product_providers.dart';
import 'package:auth_katalog_app/features/product/domain/entities/product_entity.dart';
import 'package:auth_katalog_app/features/product/domain/repositories/product_repository.dart';
import 'package:auth_katalog_app/core/widgets/app_shimmer.dart';
import 'package:auth_katalog_app/features/profile/presentation/pages/profile_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _fullUser = UserEntity(
  id: 1,
  username: 'emilys',
  email: 'emily@example.com',
  firstName: 'Emily',
  lastName: 'Johnson',
  gender: 'female',
  image: 'https://example.test/avatar.png',
  age: 28,
  phone: '+81 965-431-3024',
  birthDate: '1996-05-30',
  university: 'University of Wisconsin',
  role: 'admin',
);

const _partialUser = UserEntity(
  id: 1,
  username: 'emilys',
  email: 'emily@example.com',
  firstName: 'Emily',
  lastName: 'Johnson',
  gender: 'female',
  image: 'https://example.test/avatar.png',
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.user = _fullUser, this.delay = Duration.zero});

  final UserEntity user;

  final Duration delay;

  int logoutCalls = 0;
  int profileCalls = 0;

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    profileCalls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return Right(user);
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> logout() async {
    logoutCalls++;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, bool>> restoreSession() async => const Right(true);
}

class _FakeProductRepository implements ProductRepository {
  @override
  Future<Either<Failure, ProductEntity>> getProduct(int id) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, ProductPageEntity>> getProducts({
    required int limit,
    required int skip,
    String query = '',
  }) async => Right(
    ProductPageEntity(products: const [], total: 0, skip: skip, limit: limit),
  );
}

Widget _app(_FakeAuthRepository authRepository) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(authRepository),
    productRepositoryProvider.overrideWithValue(_FakeProductRepository()),
    sessionStartupDelayProvider.overrideWithValue(Duration.zero),
  ],
  child: Consumer(
    builder: (context, ref, _) =>
        MaterialApp.router(routerConfig: ref.watch(appRouterProvider)),
  ),
);

final _confirmLogout = find.descendant(
  of: find.byType(AlertDialog),
  matching: find.widgetWithText(FilledButton, 'Keluar'),
);

Future<void> _openProfile(
  WidgetTester tester,
  _FakeAuthRepository authRepository,
) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(authRepository));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Halo, Emily Johnson!'));
  await tester.pumpAndSettle();
  expect(find.byType(ProfilePage), findsOneWidget);
}

void main() {
  testWidgets('shows the full profile grouped into sections', (tester) async {
    await _openProfile(tester, _FakeAuthRepository());

    expect(find.text('Emily Johnson'), findsOneWidget);
    expect(find.text('@emilys'), findsOneWidget);
    expect(find.text('admin'), findsOneWidget);

    expect(find.text('emily@example.com'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('30 Mei 1996'), findsOneWidget);
    expect(find.text('+81 965-431-3024'), findsOneWidget);
    expect(find.text('University of Wisconsin'), findsOneWidget);
  });

  testWidgets('drops sections whose values are all absent', (tester) async {
    await _openProfile(tester, _FakeAuthRepository(user: _partialUser));

    expect(find.text('emily@example.com'), findsOneWidget);
    expect(find.text('AKUN'), findsOneWidget);

    expect(find.text('PENDIDIKAN'), findsNothing);
    expect(find.text('Universitas'), findsNothing);
    expect(find.text('Umur'), findsNothing);
    expect(find.text('Telepon'), findsNothing);

    expect(find.text('PRIBADI'), findsOneWidget);
    expect(find.text('female'), findsOneWidget);
  });

  testWidgets('pull to refresh shows the skeleton, then the fresh profile', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository(
      delay: const Duration(milliseconds: 500),
    );
    await _openProfile(tester, authRepository);
    expect(authRepository.profileCalls, 1);
    expect(find.byType(AppShimmer), findsNothing);

    await tester.drag(find.text('Emily Johnson'), const Offset(0, 900));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(authRepository.profileCalls, 2);
    expect(find.byType(AppShimmer), findsOneWidget);
    expect(find.text('Emily Johnson'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(AppShimmer), findsNothing);
    expect(find.text('emily@example.com'), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'unmounting the RefreshIndicator mid-refresh must not throw',
    );
  });

  testWidgets('logout requires confirmation before clearing session', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    await _openProfile(tester, authRepository);

    await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari akun?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(authRepository.logoutCalls, 0);
  });

  testWidgets('confirming logout returns to Login from the pushed page', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    await _openProfile(tester, authRepository);

    await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(_confirmLogout);
    await tester.pumpAndSettle();

    expect(authRepository.logoutCalls, 1);
    expect(
      find.byType(LoginPage),
      findsOneWidget,
      reason:
          'the redirect must unwind the pushed Profile route, not leave it '
          'on top of the stack',
    );
    expect(find.byType(ProfilePage), findsNothing);
  });
}
