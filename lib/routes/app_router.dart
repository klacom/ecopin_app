import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/errors/presentations/unauthorized_screen.dart';
import 'package:ecopin_app/features/auth/presentation/screens/login_screen.dart';
import 'package:ecopin_app/features/auth/presentation/screens/register_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_cleanup_tasks_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_clusters_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_dashboard_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_main_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_map_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_profile_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_reports_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_response_logs_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_cluster_details_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_cleanup_task_details_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_create_custom_cleanup_task_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_report_details_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_analytics_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_cluster_create_task.dart';
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
import 'package:logging/logging.dart';

// Guides user to Public and Protected Routes

final Logger log = Logger("App Router");

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

      log.info(
        'Redirect check - Path: $path, LoggedIn: $loggedIn, Role: $role, IsLoading: $isLoading',
      );

      if (isLoading) return null;

      if (path == PublicAppRoutes.splash) {
        // If logged in, redirect based on role
        if (loggedIn) {
          if (role == UserRole.officer || role == UserRole.fieldCrew) {
            log.info('Redirecting from splash to Officer Dashboard');
            return OfficerAppRoutes.dashboard;
          } else if (role == UserRole.admin) {
            log.info('Redirecting from splash to Admin Dashboard');
            return AdminAppRoutes.dashboard;
          } else if (role == UserRole.citizen) {
            log.info('Redirecting from splash to Maps (Citizen)');
            return ProtectedAppRoutes.maps;
          } else {
            log.info('Redirecting from splash to Login (Logout)');
            return PublicAppRoutes.login;
          }
        } else {
          // Not logged in: go to login screen
          return PublicAppRoutes.login;
        }
      }

      final isPublicRoute = PublicAppRoutes.publicRoutes.contains(path);
      final isOfficerRoute = path.startsWith('/officer/');
      final isAdminRoute = path.startsWith('/admin/');
      final isProtectedRoute = ProtectedAppRoutes.protectedRoutes.any(
        (route) => path.startsWith(route),
      );

      log.info(
        'Route checks - IsPublicRoute: $isPublicRoute, IsOfficerRoute: $isOfficerRoute, IsAdminRoute: $isAdminRoute, IsProtectedRoute: $isProtectedRoute',
      );

      if (loggedIn && isPublicRoute) {
        // Route based on role
        log.info('Redirecting based on role: $role');
        if (role == UserRole.officer || role == UserRole.fieldCrew) {
          log.info('Redirecting to Officer Dashboard');
          return OfficerAppRoutes.dashboard;
        } else if (role == UserRole.admin) {
          log.info('Redirecting to Admin Dashboard');
          return AdminAppRoutes.dashboard;
        } else {
          log.info('Redirecting to Maps (Citizen)');
          return ProtectedAppRoutes.maps;
        }
      }

      if (!loggedIn && !isPublicRoute) {
        return PublicAppRoutes.login;
      }

      // Role-based route protection
      if (loggedIn) {
        log.info('Role-based check - IsOfficerRoute: $isOfficerRoute, Role: $role');
        if (isOfficerRoute && role != UserRole.officer && role != UserRole.fieldCrew && role != UserRole.admin) {
          log.info('Redirecting to citizen maps - non-Officer/Admin on Officer route');
          return ProtectedAppRoutes.maps;
        }
        if (isAdminRoute && role != UserRole.admin) {
          log.info(
            'Redirecting to appropriate screen - non-Admin on Admin route',
          );
          return (role == UserRole.officer || role == UserRole.fieldCrew)
              ? OfficerAppRoutes.dashboard
              : ProtectedAppRoutes.maps;
        }
        // Check if path is a protected route (including nested routes)
        log.info(
          'Final check - IsOfficerRoute: $isOfficerRoute, IsAdminRoute: $isAdminRoute, IsProtectedRoute: $isProtectedRoute',
        );
        if (!isOfficerRoute && !isAdminRoute && !isProtectedRoute) {
          log.info('Redirecting to citizen maps - not in any route category');
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
      // Officer Shell Route
      ShellRoute(
        builder: (context, state, child) => OfficerMainScreen(child: child),
        routes: [
          GoRoute(
            path: OfficerAppRoutes.dashboard,
            builder: (_, _) => const OfficerDashboardScreen(),
          ),
          GoRoute(
            path: OfficerAppRoutes.maps,
            builder: (_, _) => const OfficerMapScreen(),
          ),
          GoRoute(
            path: OfficerAppRoutes.clusters,
            builder: (_, _) => const OfficerClustersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return OfficerClusterDetailsScreen(clusterId: id);
                },
                routes: [
                  GoRoute(
                    path: 'create-task',
                    builder: (context, state) {
                      return const OfficerClusterCreateTaskScreen();
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: OfficerAppRoutes.cleanupTasks,
            builder: (_, _) => const OfficerCleanupTasksScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, _) => const OfficerCreateCustomCleanupTaskScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return OfficerCleanupTaskDetailsScreen(taskId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: OfficerAppRoutes.reports,
            builder: (_, _) => const OfficerReportsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return OfficerReportDetailsScreen(reportId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: OfficerAppRoutes.responseLogs,
            builder: (_, _) => const OfficerResponseLogsScreen(),
          ),
          GoRoute(
            path: OfficerAppRoutes.analytics,
            builder: (_, _) => const OfficerAnalyticsScreen(),
          ),
          GoRoute(
            path: OfficerAppRoutes.profile,
            builder: (_, _) => const OfficerProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

