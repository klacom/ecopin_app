import 'dart:io';
import 'dart:ui' as ui;
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/search_overlay.dart';
import 'package:ecopin_app/shared/maps/presentation/controllers/location_voice_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'location_search_controller_test.dart';
import 'location_search_overlay_test.dart' show RecordingSearchMap;

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
      for (final mode in ['recent', 'results', 'voice-denied']) {
        testWidgets('place search $mode / ${scale}x / ${dark ? 'dark' : 'light'}', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final places = SyntheticPlaces(),
              recent = SyntheticRecents()
                ..rows.add(
                  place(
                    'Pasig City Hall, Caruncho Avenue, San Nicolas, Pasig City',
                  ),
                );
          final voice = SyntheticVoice()
            ..availability = mode == 'voice-denied'
                ? VoiceAvailability.permissionDenied
                : VoiceAvailability.ready;
          const key = Key('place-search-preview');
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(bottom: 24),
                ),
                child: RepaintBoundary(
                  key: key,
                  child: SearchOverlay(
                    mapController: RecordingSearchMap(),
                    searchService: places,
                    recentSearches: recent,
                    voiceBackend: voice,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (mode == 'results') {
            await tester.enterText(find.byType(TextField), 'Rosario');
            await tester.pump(const Duration(milliseconds: 300));
            places.pending.single.complete([
              place(
                'Rosario Barangay Hall, Ortigas Avenue Extension, Pasig City',
              ),
              place('Rosario Elementary School, Pasig City'),
            ]);
            await tester.pumpAndSettle();
          } else if (mode == 'voice-denied') {
            await tester.tap(find.text('Use voice search'));
            await tester.pumpAndSettle();
            await tester.ensureVisible(
              find.text(
                'Microphone or speech access is denied. Type a place or check device permissions.',
              ),
            );
            await tester.pumpAndSettle();
          }
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
                '$output/mobile-place-search-$mode-${dark ? 'dark' : 'light'}-${scale}x.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          if (mode == 'recent' && scale == 2) {
            tester.view.viewInsets = const FakeViewPadding(bottom: 280);
            addTearDown(tester.view.resetViewInsets);
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('Use voice search'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
