import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/connectivity_service.dart';
import 'package:ecopin_app/shared/common/presentation/widgets/offline_sync_banner.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/status_badge.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/validation_badge.dart';

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets(
      'disabled action label remains readable in ${theme.brightness}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: AppButton(text: 'Disabled action', onPressed: null),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final element = tester.element(find.text('Disabled action'));
        final foreground = DefaultTextStyle.of(element).style.color!;
        final material = element.findAncestorWidgetOfExactType<Material>()!;
        final background = Color.alphaBlend(
          material.color ?? Colors.transparent,
          theme.scaffoldBackgroundColor,
        );
        final text = Color.alphaBlend(foreground, background);
        final first = text.computeLuminance(),
            second = background.computeLuminance();
        final contrast = first > second
            ? (first + .05) / (second + .05)
            : (second + .05) / (first + .05);
        expect(contrast, greaterThanOrEqualTo(4.5));
      },
    );
    testWidgets(
      'offline and review copy wrap at 320px in ${theme.brightness}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityProvider.overrideWith(
                (ref) => Stream.value([ConnectivityResult.none]),
              ),
            ],
            child: MaterialApp(
              theme: theme,
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: const Scaffold(
                  body: Column(
                    children: [
                      OfflineSyncBanner(),
                      ValidationBadge(status: 'pending_ai_validation'),
                      StatusBadge(status: 'waiting_for_feedback'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Awaiting automated review'), findsOneWidget);
        expect(find.text('Waiting for Feedback'), findsOneWidget);
        expect(find.textContaining('automatically'), findsNothing);
      },
    );
  }
  testWidgets('primary button wraps long labels at large text sizes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: AppButton(
                  text: 'Prepare assigned reports for offline work',
                  icon: Icons.download,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(TextButton)).height, greaterThan(56));
  });

  testWidgets(
    'loading button prevents duplicate submission and names progress',
    (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: AppButton(
              text: 'Save report',
              isLoading: true,
              onPressed: () => presses++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextButton));
      expect(presses, 0);
      expect(find.bySemanticsLabel('Save report, in progress'), findsOneWidget);
    },
  );

  testWidgets('password visibility has a named state and email has autofill', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            labelText: 'Password',
            inputType: 'password',
          ),
        ),
      ),
    );
    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            labelText: 'Email',
            inputType: 'email',
          ),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.emailAddress);
    expect(field.autofillHints, contains(AutofillHints.email));
  });
}
