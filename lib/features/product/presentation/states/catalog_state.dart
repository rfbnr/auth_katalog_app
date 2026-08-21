import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/product_entity.dart';

part 'catalog_state.freezed.dart';

@freezed
abstract class CatalogState with _$CatalogState {
  const CatalogState._();

  const factory CatalogState({
    @Default(<ProductEntity>[]) List<ProductEntity> products,
    @Default('') String query,
    @Default(0) int total,
    @Default(false) bool isRefreshing,
    @Default(false) bool isLoadingMore,
    @Default(false) bool isPaginationFailure,
    Failure? failure,
  }) = _CatalogState;

  bool get hasMore => products.length < total;
}
