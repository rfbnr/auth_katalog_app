import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/di/auth_providers.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final profileControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, UserEntity>(
      ProfileController.new,
      retry: (_, _) => null,
    );

class ProfileController extends AsyncNotifier<UserEntity> {
  @override
  Future<UserEntity> build() => _fetch();

  Future<UserEntity> _fetch() async {
    final result = await ref.read(getCurrentUserUsecaseProvider)();
    return result.fold((failure) => throw failure, (user) {
      ref.read(authControllerProvider.notifier).authenticated();
      return user;
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading<UserEntity>();
    state = await AsyncValue.guard(_fetch);
  }

  void retry() => ref.invalidateSelf();
}
