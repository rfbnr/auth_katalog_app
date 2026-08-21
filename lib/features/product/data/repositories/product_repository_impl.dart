import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_response_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remoteDatasource);

  final ProductRemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, ProductPageEntity>> getProducts({
    required int limit,
    required int skip,
    String query = '',
  }) async {
    try {
      final response = query.trim().isEmpty
          ? await _remoteDatasource.getProducts(limit: limit, skip: skip)
          : await _remoteDatasource.searchProducts(
              query: query.trim(),
              limit: limit,
              skip: skip,
            );
      return Right(
        ProductPageEntity(
          products: response.products.map(_toEntity).toList(growable: false),
          total: response.total,
          skip: response.skip,
          limit: response.limit,
        ),
      );
    } on Object catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProduct(int id) async {
    try {
      return Right(_toEntity(await _remoteDatasource.getProduct(id)));
    } on Object catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}

ProductEntity _toEntity(ProductResponseModel model) => ProductEntity(
  id: model.id,
  title: model.title,
  description: model.description,
  price: model.price,
  rating: model.rating,
  thumbnail: model.thumbnail,
  images: model.images,
);
