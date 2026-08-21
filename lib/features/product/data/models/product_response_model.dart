import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_response_model.freezed.dart';
part 'product_response_model.g.dart';

@freezed
abstract class ProductResponseModel with _$ProductResponseModel {
  const factory ProductResponseModel({
    required int id,
    required String title,
    required String description,
    required double price,
    required double rating,
    required String thumbnail,
    @Default(<String>[]) List<String> images,
  }) = _ProductResponseModel;

  factory ProductResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ProductResponseModelFromJson(json);
}
