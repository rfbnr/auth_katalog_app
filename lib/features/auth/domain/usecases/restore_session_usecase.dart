import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

class RestoreSessionUsecase {
  const RestoreSessionUsecase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, bool>> call() => _repository.restoreSession();
}
