import 'package:latlong2/latlong.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/errors/presentations/unauthorized_screen.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/landing_screen.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/login_screen.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/register_screen.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/email_verification_screen.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/forgot_password_screen.dart';
import 'package:ecopin_app/features/citizen/presentation/screens/citizen_main_screen.dart';
import 'package:ecopin_app/shared/maps/presentation/screens/maps_screen.dart';
import 'package:ecopin_app/shared/notifications/presentation/screens/notifications_screen.dart';
import 'package:ecopin_app/shared/profile/presentation/screens/profile_screen.dart';
import 'package:ecopin_app/shared/reports/presentation/screens/create_report_screen.dart';
import 'package:ecopin_app/shared/reports/presentation/screens/reports_screen.dart';
import 'package:ecopin_app/shared/splash/splash_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_main_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_dashboard_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_tasks_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_task_detail_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_report_detail_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_reports_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_map_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_sync_center_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_prepare_offline_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_performance_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/shared/auth/providers/auth_notifier.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/reports/presentation/screens/report_details_screen.dart';
import 'package:ecopin_app/shared/reports/data/models/report_prefill_data.dart';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

// Guides user to Public and Protected Routes

final Logger log = Logger("App Router");

/// Task-scoped (/tasks/:id/reports/:reportId) and standalone (/reports/:reportId) report routes share one screen.
Widget _crewReportDetail(String reportId, String? taskId) =>
    FieldCrewReportDetailScreen(reportId: reportId, taskId: taskId);

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authNotifierProvider);

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
      if (path == PublicAppRoutes.unauthorized) return null;

      if (path == PublicAppRoutes.splash) {
        // If logged in, redirect based on role
        if (loggedIn) {
          if (role == UserRole.admin || role == UserRole.officer) {
            log.info('Web-only role on mobile: showing sign-out screen');
            return PublicAppRoutes.unauthorized;
          } else if (role == UserRole.fieldCrew) {
            log.info('Redirecting from splash to Field Crew Dashboard');
            return FieldCrewAppRoutes.dashboard;
          } else if (role == UserRole.citizen) {
            log.info('Redirecting from splash to Maps (Citizen)');
            return ProtectedAppRoutes.maps;
          } else {
            log.info('Redirecting from splash to Login (Logout)');
            return PublicAppRoutes.landing;
          }
        } else {
          // Not logged in: go to login screen
          return PublicAppRoutes.landing;
        }
      }

      final isPublicRoute = PublicAppRoutes.publicRoutes.contains(path);
      final isFieldCrewRoute = path.startsWith('/field-crew/');
      final isProtectedRoute = ProtectedAppRoutes.protectedRoutes.any(
        (route) => path.startsWith(route),
      );

      log.info(
        'Route checks - IsPublicRoute: $isPublicRoute, IsProtectedRoute: $isProtectedRoute',
      );

      // Officer and admin sessions have no mobile workspace: keep them on the
      // sign-out screen instead of bouncing between /landing and the auth listener.
      if (loggedIn && (role == UserRole.officer || role == UserRole.admin)) {
        return PublicAppRoutes.unauthorized;
      }

      if (loggedIn && isPublicRoute && path != PublicAppRoutes.unauthorized) {
        // Route based on role
        log.info('Redirecting based on role: $role');
        if (role == UserRole.fieldCrew) {
          log.info('Redirecting to Field Crew Dashboard');
          return FieldCrewAppRoutes.dashboard;
        } else {
          log.info('Redirecting to Maps (Citizen)');
          return ProtectedAppRoutes.maps;
        }
      }

      if (!loggedIn && !isPublicRoute) {
        return PublicAppRoutes.landing;
      }

      // Role-based route protection
      if (loggedIn) {
        log.info('Role-based check - Role: $role');

        if (isFieldCrewRoute && role != UserRole.fieldCrew) {
          log.info(
            'Redirecting to citizen maps - unauthorized on Field Crew route',
          );
          return ProtectedAppRoutes.maps;
        }

        // Check if path is a protected route (including nested routes)
        if (!isFieldCrewRoute && !isProtectedRoute) {
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
        path: PublicAppRoutes.landing,
        builder: (_, _) => const LandingScreen(),
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
        path: PublicAppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: PublicAppRoutes.emailVerification,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: PublicAppRoutes.unauthorized,
        builder: (_, _) => const UnauthorizedScreen(),
      ),
      // Shell Route to maintain a consistent UI shell. Allows navigating on different routes while maintaining access to Bottom Nav Bar.
      ShellRoute(
        builder: (context, state, child) => CitizenMainScreen(child: child),
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
            builder: (_, _) =>
                const NotificationsScreen(role: UserRole.citizen),
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
          // extra is always a ReportPrefillData â€” from the FAB (location only)
          // or from a rejected-report resubmission (title + description + location).
          final prefill = state.extra as ReportPrefillData?;
          return CreateReportScreen(prefillData: prefill);
        },
      ),
      // Field Crew Shell Route
      ShellRoute(
        builder: (context, state, child) => FieldCrewMainScreen(child: child),
        routes: [
          GoRoute(
            path: FieldCrewAppRoutes.dashboard,
            builder: (_, _) => const FieldCrewDashboardScreen(),
          ),
          GoRoute(
            path: FieldCrewAppRoutes.map,
            builder: (_, state) {
              final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
              final lng = double.tryParse(state.uri.queryParameters['lng'] ?? '');
              return FieldCrewMapScreen(
                focus: lat == null || lng == null ? null : LatLng(lat, lng),
              );
            },
          ),
          GoRoute(
            path: FieldCrewAppRoutes.tasks,
            builder: (_, _) => const FieldCrewTasksScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return FieldCrewTaskDetailScreen(taskId: id);
                },
                routes: [
                  GoRoute(
                    path: 'reports/:reportId',
                    builder: (context, state) {
                      return _crewReportDetail(
                        state.pathParameters['reportId']!,
                        state.pathParameters['id'],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: FieldCrewAppRoutes.reports,
            builder: (_, _) => const FieldCrewReportsScreen(),
            routes: [
              GoRoute(
                path: ':reportId',
                builder: (context, state) {
                  return _crewReportDetail(
                    state.pathParameters['reportId']!,
                    state.extra as String?,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: FieldCrewAppRoutes.profile,
            builder: (_, _) => const ProfileScreen(),
          ),
          GoRoute(
            path: FieldCrewAppRoutes.performance,
            builder: (_, _) => const FieldCrewPerformanceScreen(),
          ),
          GoRoute(
            path: FieldCrewAppRoutes.notifications,
            builder: (_, _) =>
                const NotificationsScreen(role: UserRole.fieldCrew),
          ),
          GoRoute(
            path: FieldCrewAppRoutes.syncCenter,
            builder: (_, _) => const FieldCrewSyncCenterScreen(),
          ),
          GoRoute(
            path: FieldCrewAppRoutes.prepareOffline,
            builder: (_, _) => const FieldCrewPrepareOfflineScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      final role = ref.read(authNotifierProvider).state.role;
      String homePath = PublicAppRoutes.landing;
      if (role == UserRole.officer || role == UserRole.admin) {
        homePath = PublicAppRoutes.unauthorized;
      } else if (role == UserRole.fieldCrew) {
        homePath = FieldCrewAppRoutes.dashboard;
      } else if (role == UserRole.citizen) {
        homePath = ProtectedAppRoutes.maps;
      }

      return Scaffold(
        body: AppStateView(
          title: 'Page not found',
          message: 'No page exists at ${state.uri.path}.',
          icon: Icons.explore_off_outlined,
          actionLabel: 'Go to Home',
          onAction: () => context.go(homePath),
        ),
      );
    },
  );
});
