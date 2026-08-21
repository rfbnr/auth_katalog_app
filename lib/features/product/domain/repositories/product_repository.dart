import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/product_entity.dart';

abstract interface class ProductRepository {
  Future<Either<Failure, ProductPageEntity>> getProducts({
    required int limit,
    required int skip,
    String query = '',
  });

  Future<Either<Failure, ProductEntity>> getProduct(int id);
}
