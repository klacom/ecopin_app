import 'package:ecopin_app/core/errors/presentations/unauthorized_screen.dart';
import 'package:ecopin_app/features/auth/presentation/screens/login_screen.dart';
import 'package:ecopin_app/features/auth/presentation/screens/register_screen.dart';
import 'package:ecopin_app/features/main_screen.dart';
import 'package:ecopin_app/features/maps/presentation/screens/maps_screen.dart';
import 'package:ecopin_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ecopin_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:ecopin_app/features/reports/presentation/screens/create_report_screen.dart';
import 'package:ecopin_app/features/reports/presentation/screens/reports_screen.dart';
import 'package:ecopin_app/features/splash/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/auth/providers/auth_notifier.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/features/reports/presentation/screens/report_details_screen.dart';

import 'package:latlong2/latlong.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = authNotifier.state;
      final loggedIn = auth.isAuthenticated;
      final isLoading = auth.isLoading;
      final path = state.matchedLocation;

      if (isLoading) return null;

      if (path == '/splash') {
        return null;
      }

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
        path: '/splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: PublicAppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: PublicAppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: PublicAppRoutes.unauthorized,
        builder: (_, _) => const UnauthorizedScreen(),
      ),
      // Shell Route to maintain a consistent UI shell. Allows navigating on different routes while maintaining access to Bottom Nav Bar.
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: ProtectedAppRoutes.maps,
            builder: (_, _) => const MapScreen(),
          ),
          GoRoute(
            path: ProtectedAppRoutes.reports,
            builder: (_, _) => const ReportsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ReportDetailsScreen(reportId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: ProtectedAppRoutes.notifications,
            builder: (_, _) => const NotificationsScreen(),
          ),
          GoRoute(
            path: ProtectedAppRoutes.profile,
            builder: (_, _) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: ProtectedAppRoutes.createReport,
        builder: (_, state) {
          final location = state.extra as LatLng?;
          return CreateReportScreen(initialLocation: location);
        },
      ),
    ],
  );
});
