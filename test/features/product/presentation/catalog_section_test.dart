import 'dart:async';

import 'package:auth_katalog_app/core/error/failure.dart';
import 'package:auth_katalog_app/features/product/di/product_providers.dart';
import 'package:auth_katalog_app/features/product/domain/entities/product_entity.dart';
import 'package:auth_katalog_app/features/product/domain/repositories/product_repository.dart';
import 'package:auth_katalog_app/features/product/presentation/controllers/catalog_controller.dart';
import 'package:auth_katalog_app/features/product/presentation/widgets/catalog_section.dart';
import 'package:auth_katalog_app/features/product/presentation/widgets/catalog_shimmer.dart';
import 'package:auth_katalog_app/features/product/presentation/widgets/product_card.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this.onGetProducts);

  Future<Either<Failure, ProductPageEntity>> Function() onGetProducts;
  int listCalls = 0;

  @override
  Future<Either<Failure, ProductEntity>> getProduct(int id) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, ProductPageEntity>> getProducts({
    required int limit,
    required int skip,
    String query = '',
  }) {
    listCalls++;
    return onGetProducts();
  }
}

const _emptyPage = ProductPageEntity(
  products: [],
  total: 0,
  skip: 0,
  limit: 10,
);

ProductEntity _product(int id) => ProductEntity(
  id: id,
  title: 'Product $id',
  description: 'Description',
  price: (1000 * id).toDouble(),
  rating: 4.5,
  thumbnail: 'https://example.com/$id.png',
  images: const [],
);

Widget _subject(
  _FakeProductRepository repository, {
  Future<void> Function()? onAdditionalRefresh,
}) => ProviderScope(
  overrides: [
    productRepositoryProvider.overrideWithValue(repository),
    catalogSearchDebounceProvider.overrideWithValue(Duration.zero),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: CatalogSection(
        onAdditionalRefresh: onAdditionalRefresh ?? () async {},
      ),
    ),
  ),
);

void main() {
  testWidgets('shows local shimmer while catalog is loading', (tester) async {
    final pending = Completer<Either<Failure, ProductPageEntity>>();
    final repository = _FakeProductRepository(() => pending.future);

    await tester.pumpWidget(_subject(repository));

    expect(find.byType(CatalogShimmer), findsOneWidget);
  });

  testWidgets('shows empty catalog state', (tester) async {
    final repository = _FakeProductRepository(
      () async => const Right(_emptyPage),
    );

    await tester.pumpWidget(_subject(repository));
    await tester.pumpAndSettle();

    expect(find.text('Produk tidak ditemukan.'), findsOneWidget);
  });

  testWidgets('shows failure and retry invokes a new request', (tester) async {
    final repository = _FakeProductRepository(
      () async => const Left(NoInternetFailure()),
    );

    await tester.pumpWidget(_subject(repository));
    await tester.pumpAndSettle();
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(repository.listCalls, 1);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(repository.listCalls, 2);
  });

  testWidgets('pagination failure keeps loaded products on screen', (
    tester,
  ) async {
    var call = 0;
    final repository = _FakeProductRepository(() async {
      call++;
      if (call == 1) {
        return Right(
          ProductPageEntity(
            products: [_product(1), _product(2)],
            total: 10,
            skip: 0,
            limit: 10,
          ),
        );
      }
      return const Left(NoInternetFailure());
    });
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
        catalogSearchDebounceProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: CatalogSection(onAdditionalRefresh: () async {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(ProductCard), findsNWidgets(2));

    await container.read(catalogControllerProvider.notifier).loadMore();
    await tester.pump();
    await tester.pump();

    expect(
      find.byType(ProductCard),
      findsNWidgets(2),
      reason: 'a failed page must not discard products already on screen',
    );
    expect(find.text(const NoInternetFailure().message), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });

  testWidgets('product tile height follows the accessibility text scale', (
    tester,
  ) async {
    Future<double> tileHeightAt(double scale) async {
      final repository = _FakeProductRepository(
        () async => Right(
          ProductPageEntity(
            products: [_product(1), _product(2)],
            total: 2,
            skip: 0,
            limit: 10,
          ),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(repository),
            catalogSearchDebounceProvider.overrideWithValue(Duration.zero),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: CatalogSection(onAdditionalRefresh: () async {}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return tester.getSize(find.byType(ProductCard).first).height;
    }

    final atNormalScale = await tileHeightAt(1);
    final atLargeScale = await tileHeightAt(2);

    expect(
      atLargeScale,
      greaterThan(atNormalScale),
      reason:
          'a fixed childAspectRatio keeps the tile the same height at any text '
          'scale, squeezing the image until the caption finally overflows',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull refresh reloads catalog and profile callback', (
    tester,
  ) async {
    var additionalRefreshCalls = 0;
    final repository = _FakeProductRepository(
      () async => const Right(_emptyPage),
    );

    await tester.pumpWidget(
      _subject(
        repository,
        onAdditionalRefresh: () async => additionalRefreshCalls++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.text('Produk tidak ditemukan.'),
      const Offset(0, 350),
    );
    await tester.pumpAndSettle();

    expect(repository.listCalls, 2);
    expect(additionalRefreshCalls, 1);
  });
}
