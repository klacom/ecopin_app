import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_main_screen.dart';
import 'package:ecopin_app/features/citizen/presentation/screens/citizen_main_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_main_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_main_screen.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Outfit')
          ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Outfit-SemiBold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  final roles = <String, (Widget Function(Widget), List<String>, List<String>)>{
    'citizen': (
      (child) => CitizenMainScreen(child: child),
      [
        ProtectedAppRoutes.maps,
        ProtectedAppRoutes.reports,
        ProtectedAppRoutes.notifications,
        ProtectedAppRoutes.profile,
      ],
      ['Map', 'Reports', 'Alerts', 'Profile'],
    ),
    'crew': (
      (child) => FieldCrewMainScreen(child: child),
      [
        FieldCrewAppRoutes.dashboard,
        FieldCrewAppRoutes.map,
        FieldCrewAppRoutes.tasks,
        FieldCrewAppRoutes.reports,
        FieldCrewAppRoutes.profile,
      ],
      ['Home', 'Route', 'Tasks', 'Reports', 'Account'],
    ),
    'officer': (
      (child) => OfficerMainScreen(child: child),
      [
        OfficerAppRoutes.dashboard,
        OfficerAppRoutes.clusters,
        OfficerAppRoutes.cleanupTasks,
        OfficerAppRoutes.reports,
      ],
      ['Home', 'Clusters', 'Tasks', 'Reports'],
    ),
    'admin': (
      (child) => AdminMainScreen(child: child),
      [
        AdminAppRoutes.dashboard,
        AdminAppRoutes.users,
        AdminAppRoutes.settings,
        AdminAppRoutes.auditLogs,
        AdminAppRoutes.profile,
      ],
      ['Home', 'Users', 'Settings', 'Logs', 'Account'],
    ),
  };
  for (final role in roles.entries) {
    for (final dark in [false, true]) {
      testWidgets(
        '${role.key} destinations and insets at 320px / 2x / ${dark ? "dark" : "light"}',
        (tester) async {
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final extraRoutes = role.key == 'officer'
              ? [
                  OfficerAppRoutes.maps,
                  OfficerAppRoutes.spatialScan,
                  OfficerAppRoutes.analytics,
                  OfficerAppRoutes.optimization,
                  OfficerAppRoutes.responseLogs,
                  OfficerAppRoutes.profile,
                ]
              : role.key == 'crew'
              ? ['/field-crew/tasks/task-1', '/field-crew/reports/report-1']
              : <String>[];
          final router = GoRouter(
            initialLocation: role.value.$2.first,
            routes: [
              ShellRoute(
                builder: (context, state, child) => role.value.$1(child),
                routes: [
                  for (final path in [...role.value.$2, ...extraRoutes])
                    GoRoute(
                      path: path,
                      builder: (context, state) => Scaffold(
                        body: SafeArea(
                          child: Center(child: Text('Route: $path')),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
          addTearDown(router.dispose);
          const preview = Key('navigation-preview');
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                profileProvider.overrideWith(
                  (ref) => Stream.value({'full_name': 'Synthetic account'}),
                ),
                unreadNotificationsCountProvider.overrideWith(
                  (ref) => Stream.value(123),
                ),
              ],
              child: MaterialApp.router(
                routerConfig: router,
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => RepaintBoundary(
                  key: preview,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(2),
                      padding: const EdgeInsets.only(bottom: 32),
                    ),
                    child: child!,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final navigation = role.key == 'citizen'
              ? find.byKey(const Key('citizen-navigation'))
              : find.byType(NavigationBar);
          if (role.key == 'citizen') {
            final action = tester.getRect(
              find.byTooltip('Report an environmental concern'),
            );
            expect(action.width, 56);
            expect(action.center.dx, 160);
            expect(
              action.top,
              greaterThanOrEqualTo(tester.getTopLeft(navigation).dy),
            );
            expect(action.bottom, lessThanOrEqualTo(768));
          }
          expect(tester.getBottomRight(navigation).dy, 800);
          final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
          if (output != null) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(preview),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$output/mobile-navigation-${role.key}-${dark ? "dark" : "light"}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          for (var index = 0; index < role.value.$2.length; index++) {
            await tester.tap(find.text(role.value.$3[index]));
            await tester.pumpAndSettle();
            expect(
              router.routeInformationProvider.value.uri.path,
              role.value.$2[index],
            );
            if (role.key == 'citizen') {
              expect(
                tester.getSemantics(
                  find.bySemanticsLabel(role.value.$3[index]),
                ),
                matchesSemantics(
                  isButton: true,
                  isSelected: true,
                  hasSelectedState: true,
                  hasEnabledState: true,
                  isEnabled: true,
                  isFocusable: true,
                  hasTapAction: true,
                  hasFocusAction: true,
                  label: role.value.$3[index],
                  hint: index == 2 ? '123 unread notifications' : null,
                ),
              );
            } else {
              expect(
                tester.widget<NavigationBar>(navigation).selectedIndex,
                index,
              );
            }
            expect(tester.takeException(), isNull);
          }
          if (role.key == 'officer') {
            for (final label in ['Dispatch planning', 'Account']) {
              await tester.tap(find.text('More'));
              await tester.pumpAndSettle();
              await tester.ensureVisible(find.text(label));
              await tester.tap(find.text(label));
              await tester.pumpAndSettle();
              expect(
                router.routeInformationProvider.value.uri.path,
                label == 'Account'
                    ? OfficerAppRoutes.profile
                    : OfficerAppRoutes.optimization,
              );
              expect(
                tester
                    .widget<NavigationBar>(find.byType(NavigationBar))
                    .selectedIndex,
                4,
              );
              expect(tester.takeException(), isNull);
            }
          }
          if (role.key == 'crew') {
            for (final path in extraRoutes) {
              router.go(path);
              await tester.pumpAndSettle();
              expect(find.byType(NavigationBar), findsNothing);
            }
          }
        },
      );
    }
  }
}
