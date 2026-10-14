import 'dart:io';
import 'dart:ui' as ui;
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/notifications/data/notification_repository.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/notifications/presentation/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'notifications_test.dart' show SyntheticNotifications, notificationRows;

void main() {
  setUpAll(() async {
    await (FontLoader('Outfit')
          ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Outfit-Medium.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Outfit-SemiBold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final dark in [false, true]) {
    for (final empty in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'notifications ${empty ? 'empty short' : 'updates'} / ${scale}x / ${dark ? 'dark' : 'light'}',
          (tester) async {
            tester.view.physicalSize = Size(320, empty ? 450 : 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            const key = Key('notification-preview');
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  notificationRepositoryProvider.overrideWithValue(
                    SyntheticNotifications(),
                  ),
                  notificationsProvider.overrideWith(
                    (ref) => Stream.value(empty ? [] : notificationRows),
                  ),
                  unreadNotificationsCountProvider.overrideWith(
                    (ref) => Stream.value(empty ? 0 : 2),
                  ),
                ],
                child: MaterialApp(
                  theme: dark ? AppTheme.dark : AppTheme.light,
                  home: MediaQuery(
                    data: MediaQueryData(
                      textScaler: TextScaler.linear(scale),
                      padding: const EdgeInsets.only(bottom: 24),
                    ),
                    child: RepaintBoundary(
                      key: key,
                      child: const NotificationsScreen(),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (empty) {
              await tester.ensureVisible(find.text('No notifications yet'));
            }
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
            if (output != null) {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(key),
              );
              await tester.runAsync(() async {
                final warm = await boundary.toImage();
                warm.dispose();
              });
              await tester.pump();
              await tester.runAsync(() async {
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  '$output/mobile-notifications-${dark ? 'dark' : 'light'}-${empty ? 'empty-short' : 'updates'}-${scale}x.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            if (!empty) {
              await tester.scrollUntilVisible(find.text('Open report'), 180);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }
  }
}
