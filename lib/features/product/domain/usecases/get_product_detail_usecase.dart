import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductDetailUsecase {
  const GetProductDetailUsecase(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, ProductEntity>> call(int id) =>
      _repository.getProduct(id);
}
