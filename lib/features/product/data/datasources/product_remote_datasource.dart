import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/product_list_response_model.dart';
import '../models/product_response_model.dart';

part 'product_remote_datasource.g.dart';

@RestApi()
abstract class ProductRemoteDatasource {
  factory ProductRemoteDatasource(Dio dio, {String? baseUrl}) =
      _ProductRemoteDatasource;

  @GET('/products')
  Future<ProductListResponseModel> getProducts({
    @Query('limit') required int limit,
    @Query('skip') required int skip,
  });

  @GET('/products/search')
  Future<ProductListResponseModel> searchProducts({
    @Query('q') required String query,
    @Query('limit') required int limit,
    @Query('skip') required int skip,
  });

  @GET('/products/{id}')
  Future<ProductResponseModel> getProduct(@Path('id') int id);
}
