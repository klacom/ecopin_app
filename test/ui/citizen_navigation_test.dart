import 'dart:io';
import 'dart:ui' as ui;
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/citizen/presentation/widgets/citizen_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Outfit',
    )..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))).load();
    await (FontLoader('packages/icons_plus/Bootstrap')..addFont(
          rootBundle.load('packages/icons_plus/assets/fonts/Bootstrap.ttf'),
        ))
        .load();
  });

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
