import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';

const settingsFixture = <String, dynamic>{
  'id': 'existing',
  'password_min_length': 8,
  'password_require_uppercase': true,
  'password_require_lowercase': true,
  'password_require_numbers': true,
  'password_require_special_chars': true,
  'session_timeout_minutes': 60,
  'report_video_max_seconds': 8,
};

class SyntheticSettingsRepository extends AdminRepository {
  SyntheticSettingsRepository() : super(ApiClient());
  Completer<Map<String, dynamic>> result = Completer();
  Map<String, dynamic>? submitted;
  var saves = 0;
  @override
  Future<Map<String, dynamic>> getSettings() async => Map.of(settingsFixture);
  @override
  Future<Map<String, dynamic>> saveSettings(Map<String, dynamic> settings) {
    saves++;
    submitted = Map.of(settings);
    return result.future;
  }
}

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
  setUp(() => dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true'));
  for (final dark in [false, true]) {
    testWidgets(
      'settings validation, retained edits, explicit save and duplicate protection in ${dark ? "dark" : "light"}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = SyntheticSettingsRepository();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              adminRepositoryProvider.overrideWithValue(repository),
              unreadNotificationsCountProvider.overrideWith(
                (ref) => Stream.value(0),
              ),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: const RepaintBoundary(
                  key: Key('settings-preview'),
                  child: AdminSettingsScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Password rules'), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const Key('admin-video-maximum')),
        );
        await tester.enterText(
          find.byKey(const Key('admin-video-maximum')),
          '11',
        );
        await tester.ensureVisible(find.text('Save changes'));
        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();
        expect(repository.saves, 0);
        expect(find.text('Enter a whole number from 5 to 10.'), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const Key('admin-video-maximum')),
        );
        await tester.enterText(
          find.byKey(const Key('admin-video-maximum')),
          '8',
        );
        await tester.ensureVisible(find.text('Password rules'));
        await tester.pumpAndSettle();

        final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
        if (output != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('settings-preview')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$output/mobile-admin-settings-${dark ? "dark" : "light"}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.enterText(
          find.byKey(const Key('admin-password-minimum')),
          '4',
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save changes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();
        expect(repository.saves, 0);
        expect(find.text('Enter a whole number from 6 to 32.'), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const Key('admin-password-minimum')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('admin-password-minimum')),
          '12',
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('admin-session-timeout')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('admin-session-timeout')),
          '30',
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save changes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save changes'));
        await tester.pump();
        expect(repository.saves, 1);
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('admin-password-minimum')),
              )
              .enabled,
          isFalse,
        );
        expect(
          tester
              .widget<AppButton>(
                find.byWidgetPredicate(
                  (widget) =>
                      widget is AppButton && widget.text == 'Save changes',
                ),
              )
              .onPressed,
          isNull,
        );
        expect(repository.submitted?['id'], 'existing');
        expect(repository.submitted?['report_video_max_seconds'], 8);
        expect(repository.submitted?['password_min_length'], 12);
        repository.result.completeError(
          const FormatException('Synthetic save failure'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Unsaved changes'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('admin-password-minimum')),
              )
              .controller!
              .text,
          '12',
        );
        expect(
          find.textContaining('could not be loaded or saved'),
          findsOneWidget,
        );
        repository.result = Completer();
        await tester.ensureVisible(find.text('Save changes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save changes'));
        await tester.pump();
        expect(repository.saves, 2);
        repository.result.complete({'settings': repository.submitted});
        await tester.pumpAndSettle();
        expect(find.text('Changes saved'), findsOneWidget);
        expect(find.text('Unsaved changes'), findsNothing);
        await tester.ensureVisible(
          find.byKey(const Key('admin-password-minimum')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('admin-password-minimum')),
          '16',
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Revert changes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Revert changes'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('admin-password-minimum')),
              )
              .controller!
              .text,
          '12',
        );
        expect(find.text('Unsaved changes'), findsNothing);
        expect(repository.saves, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
