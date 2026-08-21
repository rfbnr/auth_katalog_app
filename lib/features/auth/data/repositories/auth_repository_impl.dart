import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/storage/token_pair.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/request/login_request_model.dart';
import '../models/response/auth_response_model.dart';
import '../models/response/user_response_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDatasource authRemoteDatasource,
    required TokenStorage tokenStorage,
  }) : this._(authRemoteDatasource, tokenStorage);

  AuthRepositoryImpl._(this._authRemoteDatasource, this._tokenStorage);

  final AuthRemoteDatasource _authRemoteDatasource;
  final TokenStorage _tokenStorage;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _authRemoteDatasource.login(
        LoginRequestModel(username: username.trim(), password: password),
      );
      await _tokenStorage.write(
        TokenPair(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        ),
      );
      return Right(_fromAuthResponse(response));
    } on Object catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, bool>> restoreSession() async {
    try {
      final tokens = await _tokenStorage.read();
      return Right(tokens != null);
    } on Object catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      return Right(
        _fromUserModel(await _authRemoteDatasource.getCurrentUser()),
      );
    } on Object catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _tokenStorage.clear();
      return const Right(unit);
    } on Object catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}

UserEntity _fromAuthResponse(AuthResponseModel model) => UserEntity(
  id: model.id,
  username: model.username,
  email: model.email,
  firstName: model.firstName,
  lastName: model.lastName,
  gender: model.gender,
  image: model.image,
);

UserEntity _fromUserModel(UserResponseModel model) => UserEntity(
  id: model.id,
  username: model.username,
  email: model.email,
  firstName: model.firstName,
  lastName: model.lastName,
  gender: model.gender,
  image: model.image,
  age: model.age,
  phone: model.phone,
  birthDate: model.birthDate,
  university: model.university,
  role: model.role,
);
