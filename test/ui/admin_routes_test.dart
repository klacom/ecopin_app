import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/core/errors/presentations/unauthorized_screen.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_audit_logs_screen.dart';
import 'package:ecopin_app/routes/app_router.dart';
import 'package:ecopin_app/shared/auth/data/models/auth_state.dart';
import 'package:ecopin_app/shared/auth/providers/auth_notifier.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'admin_users_test.dart' show SyntheticUsersRepository;

class RouteTestAuth extends ChangeNotifier implements AuthNotifier {
  RouteTestAuth(this.current);
  AppAuthState current;
  @override
  AppAuthState get state => current;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RouteTestRepository extends SyntheticUsersRepository {
  @override
  Future<Map<String, dynamic>> getAuditLogs({
    int page = 1,
    String action = '',
    String userId = '',
    String startDate = '',
    String endDate = '',
  }) async => {
    'logs': <Map<String, dynamic>>[],
    'pagination': {'page': 1, 'total': 0, 'totalPages': 0},
  };
}

void main() {
  setUp(() => dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true'));
  testWidgets('real router connects approved admin pages and role home', (
    tester,
  ) async {
    final users = RouteTestRepository();
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          (ref) => RouteTestAuth(AppAuthState.authenticated(UserRole.admin)),
        ),
        adminRepositoryProvider.overrideWithValue(users),
        adminStatsProvider.overrideWith((ref) async => <String, dynamic>{}),
        profileProvider.overrideWith((ref) => Stream.value(users.own)),
        notificationsProvider.overrideWith((ref) => Stream.value([])),
        unreadNotificationsCountProvider.overrideWith((ref) => Stream.value(0)),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump();
    expect(router.routeInformationProvider.value.uri.path, '/admin/dashboard');
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    for (final route in <String, Type>{
      '/admin/users': AdminUsersScreen,
      '/admin/settings': AdminSettingsScreen,
      '/admin/audit-logs': AdminAuditLogsScreen,
    }.entries) {
      router.go(route.key);
      await tester.pumpAndSettle();
      expect(find.byType(route.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    router.go('/login');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/admin/dashboard');
    await tester.pumpWidget(const SizedBox());
  });
  for (final role in [
    UserRole.citizen,
    UserRole.officer,
    UserRole.fieldCrew,
    null,
  ]) {
    testWidgets('admin routes deny ${role?.name ?? 'signed-out'} access', (
      tester,
    ) async {
      // Resolve the role only after mounting splash so the initial home route
      // never starts unrelated map/dashboard providers in this isolated test.
      final auth = RouteTestAuth(AppAuthState.initial());
      final container = ProviderContainer(
        overrides: [authNotifierProvider.overrideWith((ref) => auth)],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      auth.current = role == null
          ? AppAuthState.unauthenticated()
          : AppAuthState.authenticated(role);
      router.go('/admin/users');
      await tester.pump();
      expect(router.routeInformationProvider.value.uri.path, '/unauthorized');
      await tester.pumpAndSettle();
      expect(find.byType(UnauthorizedScreen), findsOneWidget);
      expect(find.byType(AdminUsersScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
