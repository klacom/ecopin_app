import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/errors/presentations/unauthorized_screen.dart';
import 'package:ecopin_app/features/auth/presentation/screens/login_screen.dart';
import 'package:ecopin_app/features/auth/presentation/screens/register_screen.dart';
import 'package:ecopin_app/features/lgu/presentation/screens/lgu_cleanup_tasks_screen.dart';
import 'package:ecopin_app/features/lgu/presentation/screens/lgu_clusters_screen.dart';
import 'package:ecopin_app/features/lgu/presentation/screens/lgu_dashboard_screen.dart';
import 'package:ecopin_app/features/lgu/presentation/screens/lgu_main_screen.dart';
import 'package:ecopin_app/features/lgu/presentation/screens/lgu_map_screen.dart';
import 'package:ecopin_app/features/lgu/presentation/screens/lgu_profile_screen.dart';
import 'package:ecopin_app/features/lgu/presentation/screens/lgu_reports_screen.dart';
import 'package:ecopin_app/features/lgu/presentation/screens/lgu_response_logs_screen.dart';
import 'package:ecopin_app/features/lgu/presentation/screens/lgu_cluster_details_screen.dart';
import 'package:ecopin_app/features/lgu/presentation/screens/lgu_cleanup_task_details_screen.dart';
import 'package:ecopin_app/features/lgu/presentation/screens/lgu_create_custom_cleanup_task_screen.dart';
import 'package:ecopin_app/features/lgu/presentation/screens/lgu_report_details_screen.dart';
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

// Guides user to Public and Protected Routes

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: PublicAppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = authNotifier.state;
      final loggedIn = auth.isAuthenticated;
      final isLoading = auth.isLoading;
      final path = state.matchedLocation;
      final role = auth.role;

      print(
        'Redirect check - Path: $path, LoggedIn: $loggedIn, Role: $role, IsLoading: $isLoading',
      );

      if (isLoading) return null;

      if (path == PublicAppRoutes.splash) {
        // If logged in, redirect based on role
        if (loggedIn) {
          if (role == UserRole.lgu) {
            print('Redirecting from splash to LGU Dashboard');
            return LguAppRoutes.dashboard;
          } else if (role == UserRole.admin) {
            print('Redirecting from splash to Admin Dashboard');
            return AdminAppRoutes.dashboard;
          } else {
            print('Redirecting from splash to Maps (Citizen)');
            return ProtectedAppRoutes.maps;
          }
        }
        return null;
      }

      final isPublicRoute = PublicAppRoutes.publicRoutes.contains(path);
      final isLguRoute = path.startsWith('/lgu/');
      final isAdminRoute = path.startsWith('/admin/');

      print(
        'Route checks - IsPublicRoute: $isPublicRoute, IsLguRoute: $isLguRoute, IsAdminRoute: $isAdminRoute',
      );

      if (loggedIn && isPublicRoute) {
        // Route based on role
        print('Redirecting based on role: $role');
        if (role == UserRole.lgu) {
          print('Redirecting to LGU Dashboard');
          return LguAppRoutes.dashboard;
        } else if (role == UserRole.admin) {
          print('Redirecting to Admin Dashboard');
          return AdminAppRoutes.dashboard;
        } else {
          print('Redirecting to Maps (Citizen)');
          return ProtectedAppRoutes.maps;
        }
      }

      if (!loggedIn && !isPublicRoute) {
        return PublicAppRoutes.login;
      }

      // Role-based route protection
      if (loggedIn) {
        if (isLguRoute && role != UserRole.lgu && role != UserRole.admin) {
          return ProtectedAppRoutes.maps;
        }
        if (isAdminRoute && role != UserRole.admin) {
          return role == UserRole.lgu
              ? LguAppRoutes.dashboard
              : ProtectedAppRoutes.maps;
        }
        // Check if path is a protected route (including nested routes)
        final isProtectedRoute = ProtectedAppRoutes.protectedRoutes.any(
          (route) => path.startsWith(route),
        );
        if (!isLguRoute && !isAdminRoute && !isProtectedRoute) {
          return ProtectedAppRoutes.maps;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: PublicAppRoutes.splash,
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
      // LGU Shell Route
      ShellRoute(
        builder: (context, state, child) => LguMainScreen(child: child),
        routes: [
          GoRoute(
            path: LguAppRoutes.dashboard,
            builder: (_, _) => const LguDashboardScreen(),
          ),
          GoRoute(
            path: LguAppRoutes.maps,
            builder: (_, _) => const LguMapScreen(),
          ),
          GoRoute(
            path: LguAppRoutes.clusters,
            builder: (_, _) => const LguClustersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return LguClusterDetailsScreen(clusterId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: LguAppRoutes.cleanupTasks,
            builder: (_, _) => const LguCleanupTasksScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, _) => const LguCreateCustomCleanupTaskScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return LguCleanupTaskDetailsScreen(taskId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: LguAppRoutes.reports,
            builder: (_, _) => const LguReportsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return LguReportDetailsScreen(reportId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: LguAppRoutes.responseLogs,
            builder: (_, _) => const LguResponseLogsScreen(),
          ),
          GoRoute(
            path: LguAppRoutes.profile,
            builder: (_, _) => const LguProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
