import 'package:auth_katalog_app/core/error/failure.dart';
import 'package:auth_katalog_app/features/product/data/datasources/product_remote_datasource.dart';
import 'package:auth_katalog_app/features/product/data/models/product_list_response_model.dart';
import 'package:auth_katalog_app/features/product/data/models/product_response_model.dart';
import 'package:auth_katalog_app/features/product/data/repositories/product_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductRemoteDatasource extends Mock
    implements ProductRemoteDatasource {}

const _productModel = ProductResponseModel(
  id: 1,
  title: 'Phone',
  description: 'A phone',
  price: 1250000,
  rating: 4.5,
  thumbnail: 'https://example.com/phone.png',
  images: ['https://example.com/phone.png'],
);

const _pageModel = ProductListResponseModel(
  products: [_productModel],
  total: 1,
  skip: 0,
  limit: 20,
);

void main() {
  test('empty query uses list endpoint and maps the page', () async {
    final remote = _MockProductRemoteDatasource();
    final repository = ProductRepositoryImpl(remote);
    when(
      () => remote.getProducts(limit: 20, skip: 0),
    ).thenAnswer((_) async => _pageModel);

    final result = await repository.getProducts(limit: 20, skip: 0);

    final page = result.getOrElse(() => throw StateError('missing page'));
    expect(page.products.single.title, 'Phone');
    expect(page.total, 1);
    verify(() => remote.getProducts(limit: 20, skip: 0)).called(1);
    verifyNever(
      () =>
          remote.searchProducts(query: any(named: 'query'), limit: 20, skip: 0),
    );
  });

  test('non-empty query uses search endpoint', () async {
    final remote = _MockProductRemoteDatasource();
    final repository = ProductRepositoryImpl(remote);
    when(
      () => remote.searchProducts(query: 'phone', limit: 20, skip: 0),
    ).thenAnswer((_) async => _pageModel);

    final result = await repository.getProducts(
      limit: 20,
      skip: 0,
      query: ' phone ',
    );

    expect(result.isRight(), isTrue);
    verify(
      () => remote.searchProducts(query: 'phone', limit: 20, skip: 0),
    ).called(1);
    verifyNever(() => remote.getProducts(limit: any(named: 'limit'), skip: 0));
  });

  test('detail connection error maps to NoInternetFailure', () async {
    final remote = _MockProductRemoteDatasource();
    final repository = ProductRepositoryImpl(remote);
    when(() => remote.getProduct(1)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/products/1'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await repository.getProduct(1);

    expect(
      result.swap().getOrElse(() => throw StateError('missing failure')),
      isA<NoInternetFailure>(),
    );
  });

  test('missing detail maps to NotFoundFailure', () async {
    final remote = _MockProductRemoteDatasource();
    final repository = ProductRepositoryImpl(remote);
    when(() => remote.getProduct(404)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/products/404'),
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/products/404'),
          statusCode: 404,
          data: const {'message': 'Product not found'},
        ),
      ),
    );

    final result = await repository.getProduct(404);

    expect(
      result.swap().getOrElse(() => throw StateError('missing failure')),
      isA<NotFoundFailure>(),
    );
  });
}
