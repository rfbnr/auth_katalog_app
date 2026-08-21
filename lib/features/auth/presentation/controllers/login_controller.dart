import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/auth_providers.dart';
import 'auth_controller.dart';

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(
      LoginController.new,
    );

class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(loginUsecaseProvider)(
      username: username,
      password: password,
    );
    result.fold((failure) => state = AsyncError(failure, StackTrace.current), (
      _,
    ) {
      state = const AsyncData(null);
      ref.read(authControllerProvider.notifier).authenticated();
    });
  }
}
