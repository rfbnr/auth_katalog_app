import 'dart:async';

import 'package:auth_katalog_app/core/error/failure.dart';
import 'package:auth_katalog_app/features/product/di/product_providers.dart';
import 'package:auth_katalog_app/features/product/domain/entities/product_entity.dart';
import 'package:auth_katalog_app/features/product/domain/repositories/product_repository.dart';
import 'package:auth_katalog_app/features/product/presentation/pages/product_detail_page.dart';
import 'package:auth_katalog_app/features/product/presentation/widgets/product_detail_shimmer.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this.onGetProduct);

  Future<Either<Failure, ProductEntity>> Function() onGetProduct;
  int detailCalls = 0;

  @override
  Future<Either<Failure, ProductEntity>> getProduct(int id) {
    detailCalls++;
    return onGetProduct();
  }

  @override
  Future<Either<Failure, ProductPageEntity>> getProducts({
    required int limit,
    required int skip,
    String query = '',
  }) => throw UnimplementedError();
}

const _product = ProductEntity(
  id: 1,
  title: 'Telepon Uji',
  description: 'Deskripsi produk',
  price: 1250000,
  rating: 4.5,
  thumbnail: 'https://example.test/product.png',
  images: [],
);

Widget _subject(_FakeProductRepository repository) => ProviderScope(
  overrides: [productRepositoryProvider.overrideWithValue(repository)],
  child: const MaterialApp(home: ProductDetailPage(productId: 1)),
);

void main() {
  testWidgets('shows loading only inside detail page', (tester) async {
    final pending = Completer<Either<Failure, ProductEntity>>();
    final repository = _FakeProductRepository(() => pending.future);

    await tester.pumpWidget(_subject(repository));

    expect(find.text('Detail Produk'), findsOneWidget);
    expect(find.byType(ProductDetailShimmer), findsOneWidget);
  });

  testWidgets('shows detail error and retry', (tester) async {
    final repository = _FakeProductRepository(
      () async => const Left(NotFoundFailure()),
    );

    await tester.pumpWidget(_subject(repository));
    await tester.pumpAndSettle();
    expect(find.text('Data tidak ditemukan.'), findsOneWidget);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(repository.detailCalls, 2);
  });

  testWidgets('shows product money path and content', (tester) async {
    final repository = _FakeProductRepository(
      () async => const Right(_product),
    );

    await tester.pumpWidget(_subject(repository));
    await tester.pump();

    expect(find.text('Telepon Uji'), findsOneWidget);
    expect(find.text('Rp1.250.000'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('Deskripsi produk'), findsOneWidget);
  });
}
