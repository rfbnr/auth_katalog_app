import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  });

  Future<Either<Failure, bool>> restoreSession();
  Future<Either<Failure, UserEntity>> getCurrentUser();
  Future<Either<Failure, Unit>> logout();
}
