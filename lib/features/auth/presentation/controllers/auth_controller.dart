import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_providers.dart';
import '../../di/auth_providers.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, bool>(
  AuthController.new,
  retry: (_, _) => null,
);

final sessionStartupDelayProvider = Provider<Duration>(
  (_) => const Duration(seconds: 1),
);

class AuthController extends AsyncNotifier<bool> {
  StreamSubscription<void>? _sessionSubscription;

  @override
  Future<bool> build() async {
    _sessionSubscription?.cancel();
    _sessionSubscription = ref.watch(sessionEventsProvider).expired.listen((_) {
      state = const AsyncData(false);
    });

    ref.onDispose(() => _sessionSubscription?.cancel());

    final restore = ref.watch(restoreSessionUsecaseProvider)();
    await Future.wait([
      restore,
      Future<void>.delayed(ref.watch(sessionStartupDelayProvider)),
    ]);
    final result = await restore;
    return result.fold((failure) => throw failure, (hasSession) => hasSession);
  }

  Future<Failure?> logout() async {
    final result = await ref.read(logoutUsecaseProvider)();
    return result.fold((failure) => failure, (_) {
      state = const AsyncData(false);
      return null;
    });
  }

  void retryRestore() => ref.invalidateSelf();

  void authenticated() => state = const AsyncData(true);
}
