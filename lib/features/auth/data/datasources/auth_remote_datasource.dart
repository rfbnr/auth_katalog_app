import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/request_metadata.dart';
import '../models/request/login_request_model.dart';
import '../models/response/auth_response_model.dart';
import '../models/response/user_response_model.dart';

part 'auth_remote_datasource.g.dart';

@RestApi()
abstract class AuthRemoteDatasource {
  factory AuthRemoteDatasource(Dio dio, {String? baseUrl}) =
      _AuthRemoteDatasource;

  @POST('/auth/login')
  Future<AuthResponseModel> login(@Body() LoginRequestModel request);

  @GET('/auth/me')
  @Extra(<String, Object>{RequestMetadata.requiresAuthentication: true})
  Future<UserResponseModel> getCurrentUser();
}
