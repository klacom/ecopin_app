import 'dart:io';
import 'dart:ui' as ui;
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/required_password_change_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'required_password_change_test.dart' show RequiredChangeApi;

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true');
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
      testWidgets(
        'required change 320px / ${scale}x / ${dark ? 'dark' : 'light'}',
        (tester) async {
          tester.view.physicalSize = const Size(320, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          const key = Key('required-password-preview');
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                apiClientProvider.overrideWithValue(RequiredChangeApi()),
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
                    child: const RequiredPasswordChangeScreen(
                      accessToken: 'synthetic-pending',
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester
                .widget<TextField>(find.byType(TextField).first)
                .autofillHints,
            [AutofillHints.newPassword],
          );
          final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
          Future<void> capture(String position) async {
            if (output == null) return;
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
                '$output/mobile-required-password-${dark ? 'dark' : 'light'}-${scale}x-$position.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }

          await capture('top');
          await tester.ensureVisible(find.text('Update password'));
          await tester.pumpAndSettle();
          await capture('actions');
          expect(tester.takeException(), isNull);
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Back to sign in'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          addTearDown(tester.view.resetViewInsets);
        },
      );
    }
  }
}
