import 'package:ecopin_app/core/errors/presentations/unauthorized_screen.dart';
import 'package:ecopin_app/features/auth/presentation/screens/login_screen.dart';
import 'package:ecopin_app/features/auth/presentation/screens/register_screen.dart';
import 'package:ecopin_app/features/maps/presentation/screens/maps_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/auth/providers/auth_notifier.dart';
import 'package:ecopin_app/routes/app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = authNotifier.state;
      final loggedIn = auth.isAuthenticated;
      final isLoading = auth.isLoading;
      final path = state.matchedLocation;

      if (isLoading) return null;

      final isPublicRoute = PublicAppRoutes.publicRoutes.contains(path);

      if (loggedIn && isPublicRoute) {
        return ProtectedAppRoutes.maps;
      }

      if (!loggedIn && !isPublicRoute) {
        return PublicAppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: PublicAppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: ProtectedAppRoutes.maps,
        builder: (_, _) => const MapScreen(),
      ),
      GoRoute(
        path: PublicAppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: PublicAppRoutes.unauthorized,
        builder: (_, _) => const UnauthorizedScreen(),
      ),
    ],
  );
});
