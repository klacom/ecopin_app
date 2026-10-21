import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/profile/presentation/widgets/delete_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('exact deletion confirmation at 320px and large text / $dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const DeleteAccountDialog(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Delete account');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'i confirm');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'I confirm');
      await tester.pump();
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      final cancel = find.text('Keep my account');
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  }
}
