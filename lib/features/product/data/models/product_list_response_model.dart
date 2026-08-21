import 'package:freezed_annotation/freezed_annotation.dart';

import 'product_response_model.dart';

part 'product_list_response_model.freezed.dart';
part 'product_list_response_model.g.dart';

@freezed
abstract class ProductListResponseModel with _$ProductListResponseModel {
  const factory ProductListResponseModel({
    required List<ProductResponseModel> products,
    required int total,
    required int skip,
    required int limit,
  }) = _ProductListResponseModel;

  factory ProductListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ProductListResponseModelFromJson(json);
}
