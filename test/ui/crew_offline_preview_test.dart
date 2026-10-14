import 'dart:io';
import 'dart:ui' as ui;
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_prepare_offline_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_sync_center_screen.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      for (final mode in [
        'sync-partial',
        'prepare-partial',
        'prepare-restored',
      ]) {
        testWidgets(
          'crew offline $mode / ${dark ? 'dark' : 'light'} / ${scale}x',
          (tester) async {
            final container = await mountCrew(
              tester,
              mode == 'sync-partial'
                  ? const FieldCrewSyncCenterScreen()
                  : const FieldCrewPrepareOfflineScreen(),
              package: SyntheticCrewPackage(
                crewPackage(receiptOnly: mode == 'prepare-restored'),
              ),
              dark: dark,
              scale: scale,
              size: const Size(320, 900),
            );
            if (mode == 'sync-partial') {
              container
                  .read(fcSyncStateProvider.notifier)
                  .setResult(crewRun, crewPhotos);
              await tester.pumpAndSettle();
            }
            expect(tester.takeException(), isNull);
            Future<void> capture(String position) async {
              final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
              if (output == null) return;
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('crew-offline-preview')),
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
                  '$output/crew-$mode-${dark ? 'dark' : 'light'}-${scale}x-$position.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }

            await capture('top');
          if (mode == 'sync-partial') {
            await tester.ensureVisible(find.text('Photos uploaded'));
            await tester.pumpAndSettle();
            await capture('results');
            await tester.ensureVisible(find.text('Response updates'));
            await tester.pumpAndSettle();
            await capture('responses');
          }
            await tester.ensureVisible(
              find.text(
                mode == 'sync-partial'
                    ? 'Refresh queue and connection'
                    : 'Enable Offline Only',
              ),
            );
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
