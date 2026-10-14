import 'dart:io';
import 'dart:ui' as ui;
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'crew_dashboard_ui_test.dart';
import 'crew_offline_ui_test.dart';

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
  for (final size in [const Size(700, 360), const Size(768, 900)]) {
    for (final dark in [false, true]) {
      testWidgets(
        'dashboard actions remain reachable at $size / ${dark ? 'dark' : 'light'} / 2x',
        (tester) async {
          await mountDashboard(
            tester,
            data: SyntheticDashboard(),
            size: size,
            scale: 2,
            dark: dark,
          );
          await tester.pumpAndSettle();
          for (final label in [
            'Open current task',
            'Open route map',
            'View all assignments',
          ]) {
            await tester.ensureVisible(find.text(label));
            await tester.pumpAndSettle();
            final bounds = tester.getRect(find.text(label));
            expect(bounds.top, greaterThanOrEqualTo(0));
            expect(bounds.bottom, lessThanOrEqualTo(size.height - 24));
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      for (final mode in ['active', 'empty', 'failed', 'offline']) {
        testWidgets(
          'crew dashboard $mode / ${dark ? 'dark' : 'light'} / ${scale}x',
          (tester) async {
            final data = SyntheticDashboard();
            if (mode == 'empty') {
              data.rows = [];
              data.route = null;
            }
            if (mode == 'failed') data.failTasks = true;
            await mountDashboard(
              tester,
              data: data,
              dark: dark,
              scale: scale,
              settings: mode == 'offline'
                  ? SyntheticCrewSettings(
                      const FcSyncSettings(mode: FcSyncMode.offlineOnly),
                    )
                  : null,
              network: mode == 'offline'
                  ? FcNetworkType.none
                  : FcNetworkType.wifi,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            Future<void> capture(String position) async {
              final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
              if (output == null) return;
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('crew-dashboard-preview')),
              );
              await tester.runAsync(() async {
                final warm = await boundary.toImage();
                warm.dispose();
              });
              await tester.pump();
              await tester.runAsync(() async {
                final image = await boundary.toImage();
                final pixels = await image.toByteData(
                  format: ui.ImageByteFormat.rawRgba,
                );
                expect(
                  pixels!.buffer.asUint32List().toSet().length,
                  greaterThan(10),
                );
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  '$output/dashboard-$mode-${dark ? 'dark' : 'light'}-${scale}x-$position.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }

            await capture('top');
            if (mode == 'active' || mode == 'offline') {
              await tester.ensureVisible(find.text('Open current task'));
              await tester.pumpAndSettle();
              await capture('task');
              await tester.ensureVisible(find.text('Route overview'));
              await tester.pumpAndSettle();
              await capture('route');
            }
            await tester.ensureVisible(find.text('Offline package has gaps'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await capture('actions');
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
