import 'dart:io';
import 'dart:ui' as ui;
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/status_badge.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/validation_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/login_screen.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/register_screen.dart';
import 'package:ecopin_app/shared/auth/presentation/screens/landing_screen.dart';
import 'auth_layout_test.dart' show SyntheticAccountApi;

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true');
    final fonts = FontLoader('Outfit')
      ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Outfit-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Outfit-SemiBold.ttf'));
    await fonts.load();
    final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final dark in [false, true]) {
    for (final entry in <String, Widget>{'intro': const LandingScreen(), 'login': const LoginScreen(), 'registration': const RegisterScreen()}.entries) {
      testWidgets('${entry.key} preview ${dark ? "dark" : "light"}', (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const preview = Key('account-preview');
        await tester.pumpWidget(ProviderScope(overrides: [apiClientProvider.overrideWithValue(SyntheticAccountApi())], child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: RepaintBoundary(key: preview, child: entry.value),
        )));
        await tester.pumpAndSettle();
        if (entry.key == 'intro') {
          await tester.runAsync(() => precacheImage(AssetImage(dark ? 'assets/logos/Full Logo Dark.png' : 'assets/logos/Full Logo Light.png'), tester.element(find.byType(LandingScreen))));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
        if (output != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(preview));
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            await File('$output/mobile-${entry.key}-${dark ? "dark" : "light"}.png').writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('shared controls preview ${dark ? "dark" : "light"} at $scale text scale', (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        const preview = Key('foundation-preview');
        await tester.pumpWidget(MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(key: preview, child: Scaffold(
              body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
                Text('Shared controls', style: (dark ? AppTheme.dark : AppTheme.light).textTheme.titleLarge),
                const SizedBox(height: 16),
                const Wrap(spacing: 8, runSpacing: 8, children: [StatusBadge(status: 'in_progress'), ValidationBadge(status: 'manual_review')]),
                const SizedBox(height: 24),
                AppTextField(controller: controller, labelText: 'Email', inputType: 'email'),
                const SizedBox(height: 24),
                AppButton(text: 'Prepare assigned reports for offline work', icon: Icons.download, onPressed: () {}),
                const SizedBox(height: 16),
                AppButton(text: 'Back to reports', variant: ButtonVariant.secondary, onPressed: () {}),
                const SizedBox(height: 16),
                AppButton(text: 'View report details', variant: ButtonVariant.link, onPressed: () {}),
              ])),
            )),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
        if (output != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(preview));
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            await File('$output/mobile-controls-${dark ? "dark" : "light"}-$scale.png').writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
}
