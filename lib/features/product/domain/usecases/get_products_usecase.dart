import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductsUsecase {
  const GetProductsUsecase(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, ProductPageEntity>> call({
    required int limit,
    required int skip,
    String query = '',
  }) => _repository.getProducts(limit: limit, skip: skip, query: query);
}
