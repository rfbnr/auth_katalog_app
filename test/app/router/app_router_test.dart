import 'package:auth_katalog_app/app/router/app_router.dart';
import 'package:auth_katalog_app/core/error/failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup loading and errors stay scoped to Splash', () {
    expect(
      authRedirect(const AsyncLoading(), AppRoutes.login),
      AppRoutes.splash,
    );
    expect(
      authRedirect(
        AsyncError(const NoInternetFailure(), StackTrace.empty),
        AppRoutes.splash,
      ),
      isNull,
    );
  });

  test('resolved session redirects only between auth boundaries', () {
    expect(
      authRedirect(const AsyncData(false), AppRoutes.splash),
      AppRoutes.login,
    );
    expect(authRedirect(const AsyncData(false), AppRoutes.login), isNull);
    expect(
      authRedirect(const AsyncData(true), AppRoutes.login),
      AppRoutes.home,
    );
    expect(authRedirect(const AsyncData(true), AppRoutes.home), isNull);
    expect(
      authRedirect(const AsyncData(true), AppRoutes.productDetail(1)),
      isNull,
    );
  });
}
