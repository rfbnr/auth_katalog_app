import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/datasources/product_remote_datasource.dart';
import '../data/repositories/product_repository_impl.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/usecases/get_product_detail_usecase.dart';
import '../domain/usecases/get_products_usecase.dart';

final productRemoteDatasourceProvider = Provider<ProductRemoteDatasource>(
  (ref) => ProductRemoteDatasource(ref.watch(dioProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(ref.watch(productRemoteDatasourceProvider)),
);

final getProductsProvider = Provider<GetProductsUsecase>(
  (ref) => GetProductsUsecase(ref.watch(productRepositoryProvider)),
);

final getProductDetailProvider = Provider<GetProductDetailUsecase>(
  (ref) => GetProductDetailUsecase(ref.watch(productRepositoryProvider)),
);
