import 'package:auth_katalog_app/core/error/failure.dart';
import 'package:auth_katalog_app/features/product/di/product_providers.dart';
import 'package:auth_katalog_app/features/product/domain/entities/product_entity.dart';
import 'package:auth_katalog_app/features/product/domain/repositories/product_repository.dart';
import 'package:auth_katalog_app/features/product/presentation/controllers/catalog_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProductEntity _product(int id, [String title = 'Product']) => ProductEntity(
  id: id,
  title: '$title $id',
  description: 'Description',
  price: (1000 * id).toDouble(),
  rating: 4.5,
  thumbnail: 'https://example.com/$id.png',
  images: const [],
);

class _FakeProductRepository implements ProductRepository {
  final calls = <({int limit, int skip, String query})>[];
  late Future<Either<Failure, ProductPageEntity>> Function({
    required int limit,
    required int skip,
    required String query,
  })
  onGetProducts;

  @override
  Future<Either<Failure, ProductEntity>> getProduct(int id) async =>
      Right(_product(id));

  @override
  Future<Either<Failure, ProductPageEntity>> getProducts({
    required int limit,
    required int skip,
    String query = '',
  }) {
    calls.add((limit: limit, skip: skip, query: query));
    return onGetProducts(limit: limit, skip: skip, query: query);
  }
}

ProviderContainer _container(_FakeProductRepository repository) =>
    ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
        catalogSearchDebounceProvider.overrideWithValue(Duration.zero),
      ],
    );

void main() {
  test('loads next page with current item count as skip', () async {
    final repository = _FakeProductRepository();
    repository.onGetProducts =
        ({required limit, required skip, required query}) async {
          if (skip == 0) {
            return Right(
              ProductPageEntity(
                products: [_product(1), _product(2)],
                total: 3,
                skip: 0,
                limit: limit,
              ),
            );
          }
          return Right(
            ProductPageEntity(
              products: [_product(3)],
              total: 3,
              skip: skip,
              limit: limit,
            ),
          );
        };
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(catalogControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    final initial = await container.read(catalogControllerProvider.future);
    expect(initial.products.length, 2);
    await container.read(catalogControllerProvider.notifier).loadMore();

    expect(container.read(catalogControllerProvider).value?.products.length, 3);
    expect(repository.calls.last.skip, 2);
  });

  test('debounce executes only the latest search query', () async {
    final repository = _FakeProductRepository();
    repository.onGetProducts =
        ({required limit, required skip, required query}) async => Right(
          ProductPageEntity(
            products: [_product(1, query.isEmpty ? 'Initial' : query)],
            total: 1,
            skip: skip,
            limit: limit,
          ),
        );
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(catalogControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(catalogControllerProvider.future);

    final notifier = container.read(catalogControllerProvider.notifier);
    notifier
      ..search('pho')
      ..search('phone');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repository.calls.map((call) => call.query), ['', 'phone']);
    expect(container.read(catalogControllerProvider).value?.query, 'phone');
  });

  test(
    'scrolling after a pagination failure does not re-fire the request',
    () async {
      final repository = _FakeProductRepository();
      repository.onGetProducts =
          ({required limit, required skip, required query}) async {
            if (skip == 0) {
              return Right(
                ProductPageEntity(
                  products: [_product(1), _product(2)],
                  total: 10,
                  skip: 0,
                  limit: limit,
                ),
              );
            }
            return const Left(NoInternetFailure());
          };
      final container = _container(repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        catalogControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(catalogControllerProvider.future);

      final notifier = container.read(catalogControllerProvider.notifier);
      await notifier.loadMore();
      expect(repository.calls.length, 2);
      expect(
        container.read(catalogControllerProvider).value?.isPaginationFailure,
        isTrue,
      );

      await notifier.loadMore();
      await notifier.loadMore();
      expect(repository.calls.length, 2);

      await notifier.retry();
      expect(repository.calls.length, 3);
      expect(repository.calls.last.skip, 2);
    },
  );

  test('retry resumes pagination without discarding loaded products', () async {
    final repository = _FakeProductRepository();
    var failNextPage = true;
    repository.onGetProducts =
        ({required limit, required skip, required query}) async {
          if (skip == 0) {
            return Right(
              ProductPageEntity(
                products: [_product(1), _product(2)],
                total: 3,
                skip: 0,
                limit: limit,
              ),
            );
          }
          if (failNextPage) {
            failNextPage = false;
            return const Left(NoInternetFailure());
          }
          return Right(
            ProductPageEntity(
              products: [_product(3)],
              total: 3,
              skip: skip,
              limit: limit,
            ),
          );
        };
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(catalogControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(catalogControllerProvider.future);

    final notifier = container.read(catalogControllerProvider.notifier);
    await notifier.loadMore();
    await notifier.retry();

    final state = container.read(catalogControllerProvider).value!;
    expect(state.products.map((product) => product.id), [1, 2, 3]);
    expect(state.isPaginationFailure, isFalse);
    expect(state.failure, isNull);
  });

  test('refresh failure preserves existing products', () async {
    final repository = _FakeProductRepository();
    var firstCall = true;
    repository.onGetProducts =
        ({required limit, required skip, required query}) async {
          if (firstCall) {
            firstCall = false;
            return Right(
              ProductPageEntity(
                products: [_product(1)],
                total: 1,
                skip: 0,
                limit: limit,
              ),
            );
          }
          return const Left(NoInternetFailure());
        };
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(catalogControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(catalogControllerProvider.future);

    await container.read(catalogControllerProvider.notifier).refresh();

    final state = container.read(catalogControllerProvider).value!;
    expect(state.products.single.id, 1);
    expect(state.failure, isA<NoInternetFailure>());
    expect(state.isRefreshing, isFalse);
  });
}
