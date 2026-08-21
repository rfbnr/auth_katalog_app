import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/get_current_user_usecase.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/logout_usecase.dart';
import '../domain/usecases/restore_session_usecase.dart';

// Datasource
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>(
  (ref) => AuthRemoteDatasource(ref.watch(dioProvider)),
);

// Repository
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    authRemoteDatasource: ref.watch(authRemoteDatasourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

// Usecases
final loginUsecaseProvider = Provider<LoginUsecase>(
  (ref) => LoginUsecase(ref.watch(authRepositoryProvider)),
);

final restoreSessionUsecaseProvider = Provider<RestoreSessionUsecase>(
  (ref) => RestoreSessionUsecase(ref.watch(authRepositoryProvider)),
);

final logoutUsecaseProvider = Provider<LogoutUsecase>(
  (ref) => LogoutUsecase(ref.watch(authRepositoryProvider)),
);

final getCurrentUserUsecaseProvider = Provider<GetCurrentUserUsecase>(
  (ref) => GetCurrentUserUsecase(ref.watch(authRepositoryProvider)),
);
