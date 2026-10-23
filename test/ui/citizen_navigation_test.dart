import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
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
                profileProvider.overrideWith(
                  (ref) => Stream.value({'full_name': 'Synthetic Citizen'}),
                ),
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
          final scroll = find
              .byType(reports ? ListView : CustomScrollView)
              .first;
          expect(
            tester.getBottomRight(scroll).dy,
            800,
            reason:
                'Page content must paint behind the raised navbar, not stop at its bounding box.',
          );
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
                final shell = tester.widget<Scaffold>(
                  find
                      .descendant(
                        of: find.byType(CitizenMainScreen),
                        matching: find.byType(Scaffold),
                      )
                      .first,
                );
                final background =
                    (shell.backgroundColor ?? theme.scaffoldBackgroundColor)
                        .toARGB32();
                expect(
                  background,
                  isNot(theme.colorScheme.surface.toARGB32()),
                  reason:
                      'The navbar silhouette needs contrast against the citizen page canvas.',
                );
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
                for (final sample in [
                  (1, top + 25, background),
                  (24, top + 28, theme.colorScheme.surface.toARGB32()),
                ]) {
                  final offset = (sample.$2 * image.width + sample.$1) * 4;
                  expect(rgba.getUint8(offset), (sample.$3 >> 16) & 255);
                  expect(rgba.getUint8(offset + 1), (sample.$3 >> 8) & 255);
                  expect(rgba.getUint8(offset + 2), sample.$3 & 255);
                }
                final ringOffset =
                    ((top + 2) * image.width + image.width ~/ 2) * 4;
                expect(
                  rgba.getUint8(ringOffset),
                  greaterThan((background >> 16) & 255),
                  reason:
                      'The raised Report action keeps a visible surface ring.',
                );
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
    for (final reports in [true, false]) {
      testWidgets(
        'loaded citizen ${reports ? "reports" : "alerts"} scrolls beneath the navbar / $dark',
        (tester) async {
          tester.view.physicalSize = const Size(390, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final rows = List.generate(
            20,
            (i) => {
              'id': 'synthetic-$i',
              'title': 'Street concern $i',
              'body': 'Your report has been reviewed by the response team.',
              'description': 'Waste beside the street near the public market.',
              'latitude': 14.58,
              'longitude': 121.08,
              'status': 'unresolved',
              'validation_status': 'approved',
              'issue_type': 'waste',
              'is_read': i.isOdd,
              'created_at': '2026-10-23T00:00:00Z',
              'updated_at': '2026-10-23T00:00:00Z',
            },
          );
          final path = reports
              ? ProtectedAppRoutes.reports
              : ProtectedAppRoutes.notifications;
          final router = GoRouter(
            initialLocation: path,
            routes: [
              ShellRoute(
                builder: (_, _, child) => CitizenMainScreen(child: child),
                routes: [
                  GoRoute(
                    path: path,
                    builder: (_, _) => reports
                        ? const ReportsScreen()
                        : const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          );
          addTearDown(router.dispose);
          const key = Key('loaded-citizen-page');
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                profileProvider.overrideWith(
                  (ref) => Stream.value({'full_name': 'Synthetic Citizen'}),
                ),
                myReportsProvider.overrideWith(
                  (ref) async => rows.map(ReportModel.fromJson).toList(),
                ),
                notificationsProvider.overrideWith((ref) => Stream.value(rows)),
                unreadNotificationsCountProvider.overrideWith(
                  (ref) => Stream.value(10),
                ),
              ],
              child: MaterialApp.router(
                theme: dark ? AppTheme.dark : AppTheme.light,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(top: 24, bottom: 24),
                  ),
                  child: RepaintBoundary(key: key, child: child!),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final scroll = find
              .byType(reports ? ListView : CustomScrollView)
              .first;
          expect(tester.getBottomRight(scroll).dy, 800);
          await tester.scrollUntilVisible(
            find.text('Street concern 3'),
            180,
            scrollable: find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
          if (output != null) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(key),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final png = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$output/citizen-loaded-${reports ? "reports" : "alerts"}-${dark ? "dark" : "light"}.png',
              ).writeAsBytes(png!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.scrollUntilVisible(
            find.text('Street concern 19'),
            300,
            scrollable: find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first,
          );
          await tester.pumpAndSettle();
          final position = tester
              .state<ScrollableState>(
                find
                    .descendant(of: scroll, matching: find.byType(Scrollable))
                    .first,
              )
              .position;
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          final lastCard = find
              .ancestor(
                of: find.text('Street concern 19'),
                matching: find.byType(Card),
              )
              .first;
          expect(
            tester.getBottomRight(lastCard).dy,
            lessThanOrEqualTo(
              tester.getTopLeft(find.byKey(const Key('citizen-navigation'))).dy,
            ),
          );
          expect(
            tester.getBottomRight(find.text('Street concern 19')).dy,
            lessThan(
              tester.getTopLeft(find.byKey(const Key('citizen-navigation'))).dy,
            ),
          );
          expect(tester.takeException(), isNull);
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
