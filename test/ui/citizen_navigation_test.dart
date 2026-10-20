import 'dart:io';
import 'dart:ui' as ui;
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/citizen/presentation/screens/citizen_main_screen.dart';
import 'package:ecopin_app/features/citizen/presentation/widgets/citizen_navigation_bar.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/notifications/presentation/screens/notifications_screen.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/reports/presentation/screens/reports_screen.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'Outfit',
    )..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))).load();
    await (FontLoader('packages/icons_plus/Bootstrap')..addFont(
          rootBundle.load('packages/icons_plus/assets/fonts/Bootstrap.ttf'),
        ))
        .load();
  });

  for (final dark in [false, true]) {
    for (final reports in [true, false]) {
      testWidgets(
        'no rectangular strip above citizen ${reports ? "reports" : "alerts"} / ${dark ? "dark" : "light"}',
        (tester) async {
          tester.view.physicalSize = const Size(390, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final router = GoRouter(
            initialLocation: reports
                ? ProtectedAppRoutes.reports
                : ProtectedAppRoutes.notifications,
            routes: [
              ShellRoute(
                builder: (_, _, child) => CitizenMainScreen(child: child),
                routes: [
                  GoRoute(
                    path: ProtectedAppRoutes.reports,
                    builder: (_, _) => const ReportsScreen(),
                  ),
                  GoRoute(
                    path: ProtectedAppRoutes.notifications,
                    builder: (_, _) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          );
          addTearDown(router.dispose);
          final theme = dark ? AppTheme.dark : AppTheme.light;
          const preview = Key('citizen-page-preview');
          final previousShadows = debugDisableShadows;
          debugDisableShadows = false;
          addTearDown(() => debugDisableShadows = previousShadows);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                myReportsProvider.overrideWith((ref) async => []),
                notificationsProvider.overrideWith((ref) => Stream.value([])),
                unreadNotificationsCountProvider.overrideWith(
                  (ref) => Stream.value(0),
                ),
              ],
              child: MaterialApp.router(
                routerConfig: router,
                theme: theme,
                builder: (_, child) =>
                    RepaintBoundary(key: preview, child: child!),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          try {
            tester.renderObject(find.byKey(preview)).markNeedsPaint();
            await tester.pump();
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(preview),
            );
            final top = tester
                .getTopLeft(find.byKey(const Key('citizen-navigation')))
                .dy
                .round();
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              try {
                final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
                if (output != null) {
                  final png = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  await File(
                    '$output/citizen-${reports ? "reports" : "alerts"}-${dark ? "dark" : "light"}.png',
                  ).writeAsBytes(png!.buffer.asUint8List());
                }
                final rgba = (await image.toByteData(
                  format: ui.ImageByteFormat.rawRgba,
                ))!;
                final background = theme.scaffoldBackgroundColor.toARGB32();
                for (var y = top + 8; y < top + 22; y++) {
                  final offset = (y * image.width + 24) * 4;
                  expect(
                    rgba.getUint8(offset),
                    (background >> 16) & 255,
                    reason:
                        'The space beside the raised action must show the page without a rectangular shadow.',
                  );
                  expect(rgba.getUint8(offset + 1), (background >> 8) & 255);
                  expect(rgba.getUint8(offset + 2), background & 255);
                }
              } finally {
                image.dispose();
              }
            });
          } finally {
            debugDisableShadows = previousShadows;
          }
        },
      );
    }
  }

  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0, 768.0, 1024.0, 1440.0]) {
      testWidgets(
        'citizen action at $width / 2x / ${dark ? "dark" : "light"}',
        (tester) async {
          tester.view.physicalSize = Size(width, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var reports = 0;
          var selected = 0;
          Future<void> show({bool loading = false}) => tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(2),
                  padding: EdgeInsets.only(bottom: 32),
                ),
                child: Scaffold(
                  bottomNavigationBar: CitizenNavigationBar(
                    selectedIndex: selected,
                    onSelected: (value) => selected = value,
                    onReport: () => reports++,
                    isReporting: loading,
                    unreadCount: 123,
                    unreadLabel: '123 unread notifications',
                  ),
                ),
              ),
            ),
          );
          await show();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final report = find.byTooltip('Report an environmental concern');
          final bounds = tester.getRect(report);
          expect(bounds.center.dx, width / 2);
          expect(bounds.width, 56);
          expect(bounds.bottom, lessThanOrEqualTo(668));
          await tester.tap(report);
          expect(reports, 1);
          expect(selected, 0);
          await tester.tap(find.text('Alerts'));
          expect(selected, 2);

          // Native buttons remain reachable and activatable with a keyboard.
          for (var tab = 0; tab < 5; tab++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pump();
          }
          expect(reports, 2);

          await show(loading: true);
          await tester.pump();
          expect(find.byTooltip('Finding location…'), findsOneWidget);
          expect(
            tester
                .widget<FloatingActionButton>(find.byType(FloatingActionButton))
                .onPressed,
            isNull,
          );
          await tester.tap(find.byTooltip('Finding location…'));
          expect(reports, 2);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('citizen navigation light and dark visual preview', (
    tester,
  ) async {
    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = previousShadows);
    tester.view.physicalSize = const Size(828, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const preview = Key('citizen-preview');
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: preview,
          child: Row(
            children: [
              for (final dark in [false, true])
                Expanded(
                  child: Theme(
                    data: dark ? AppTheme.dark : AppTheme.light,
                    child: Builder(
                      builder: (context) => Material(
                        color: dark
                            ? const Color(0xFF121212)
                            : const Color(0xFFF5F7FA),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  dark ? 'Dark' : 'Light',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              for (var index = 0; index < 4; index++)
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: CitizenNavigationBar(
                                      selectedIndex: index,
                                      onSelected: (_) {},
                                      onReport: () {},
                                      isReporting: false,
                                      unreadCount: 3,
                                      unreadLabel: '3 unread notifications',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
    if (output != null) {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(preview),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$output/citizen-navigation.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    debugDisableShadows = previousShadows;
  });
}
