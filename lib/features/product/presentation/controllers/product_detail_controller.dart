import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/product_providers.dart';
import '../../domain/entities/product_entity.dart';

final productDetailControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ProductDetailController, ProductEntity, int>(
      ProductDetailController.new,
      retry: (_, _) => null,
    );

class ProductDetailController extends AsyncNotifier<ProductEntity> {
  ProductDetailController(this.productId);

  final int productId;

  @override
  Future<ProductEntity> build() async {
    final result = await ref.watch(getProductDetailProvider)(productId);
    return result.fold((failure) => throw failure, (product) => product);
  }

  void retry() => ref.invalidateSelf();
}
