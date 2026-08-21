import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

abstract class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/';
  static const profile = '/profile';
  static const productDetailPattern = '/products/:id';

  static String productDetail(int id) => '/products/$id';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: AppRoutes.productDetailPattern,
        redirect: (_, state) =>
            int.tryParse(state.pathParameters['id'] ?? '') == null
            ? AppRoutes.home
            : null,
        builder: (_, state) {
          final productId = int.parse(state.pathParameters['id'] ?? '');

          return ProductDetailPage(productId: productId);
        },
      ),
    ],
    redirect: (_, state) =>
        authRedirect(ref.read(authControllerProvider), state.matchedLocation),
  );
  ref.listen(authControllerProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);

  return router;
});

String? authRedirect(AsyncValue<bool> session, String location) {
  if (session.isLoading || session.hasError) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  if (session.value != true) {
    return location == AppRoutes.login ? null : AppRoutes.login;
  }
  if (location == AppRoutes.splash || location == AppRoutes.login) {
    return AppRoutes.home;
  }
  return null;
}
