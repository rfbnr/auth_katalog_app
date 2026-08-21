import 'package:auth_katalog_app/app/router/app_router.dart';
import 'package:auth_katalog_app/core/error/failure.dart';
import 'package:auth_katalog_app/features/auth/di/auth_providers.dart';
import 'package:auth_katalog_app/features/auth/domain/entities/user_entity.dart';
import 'package:auth_katalog_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_katalog_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:auth_katalog_app/features/product/di/product_providers.dart';
import 'package:auth_katalog_app/features/product/domain/entities/product_entity.dart';
import 'package:auth_katalog_app/features/product/domain/repositories/product_repository.dart';
import 'package:auth_katalog_app/features/home/presentation/pages/home_page.dart';
import 'package:auth_katalog_app/features/profile/presentation/pages/profile_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async => const Right(
    UserEntity(
      id: 1,
      username: 'tester',
      email: 'tester@example.com',
      firstName: 'Test',
      lastName: 'User',
      gender: 'female',
      image: 'https://example.test/avatar.png',
    ),
  );

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

Widget _app() => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    productRepositoryProvider.overrideWithValue(_FakeProductRepository()),
    sessionStartupDelayProvider.overrideWithValue(Duration.zero),
  ],
  child: Consumer(
    builder: (context, ref, _) =>
        MaterialApp.router(routerConfig: ref.watch(appRouterProvider)),
  ),
);

void main() {
  testWidgets('tapping the profile header opens the profile page', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    await tester.tap(find.text('Halo, Test User!'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
  });

  testWidgets('home no longer offers its own logout shortcut', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      find.byTooltip('Keluar'),
      findsNothing,
      reason: 'logout lives on the profile page now, so there is one way out',
    );
    expect(find.byIcon(Icons.logout), findsNothing);
  });
}
