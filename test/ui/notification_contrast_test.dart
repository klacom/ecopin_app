import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/notifications/data/notification_repository.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/notifications/presentation/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'notifications_test.dart' show SyntheticNotifications, notificationRows;

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'unread text has readable contrast in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        final theme = dark ? AppTheme.dark : AppTheme.light;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              notificationRepositoryProvider.overrideWithValue(
                SyntheticNotifications(),
              ),
              notificationsProvider.overrideWith(
                (ref) => Stream.value([notificationRows.first]),
              ),
              unreadNotificationsCountProvider.overrideWith(
                (ref) => Stream.value(1),
              ),
            ],
            child: MaterialApp(theme: theme, home: const NotificationsScreen()),
          ),
        );
        await tester.pumpAndSettle();
        final label = find.descendant(
          of: find.byType(Card).first,
          matching: find.text('Unread'),
        );
        final foreground = tester
            .renderObject<RenderParagraph>(label)
            .text
            .style!
            .color!;
        final card = tester.widget<Card>(find.byType(Card).first);
        final background = Color.alphaBlend(
          card.color!,
          theme.scaffoldBackgroundColor,
        );
        final first = foreground.computeLuminance(),
            second = background.computeLuminance();
        final contrast =
            (first > second ? first + .05 : second + .05) /
            (first > second ? second + .05 : first + .05);
        expect(
          contrast,
          greaterThanOrEqualTo(4.5),
          reason: 'Unread is ordinary text, not a decorative indicator',
        );
        final selected = find.widgetWithText(ChoiceChip, 'All');
        final selectedLabel = tester
            .renderObject<RenderParagraph>(
              find.descendant(of: selected, matching: find.text('All')),
            )
            .text
            .style!
            .color!;
        final chip = tester.widget<RawChip>(
          find.descendant(of: selected, matching: find.byType(RawChip)),
        );
        final selectedBackground =
            chip.color?.resolve({WidgetState.selected}) ??
            chip.selectedColor ??
            theme.chipTheme.selectedColor ??
            chip.defaultProperties!.color!.resolve({WidgetState.selected})!;
        final selectedLuminance = selectedLabel.computeLuminance(),
            backgroundLuminance = selectedBackground.computeLuminance();
        final selectedContrast =
            (selectedLuminance > backgroundLuminance
                ? selectedLuminance + .05
                : backgroundLuminance + .05) /
            (selectedLuminance > backgroundLuminance
                ? backgroundLuminance + .05
                : selectedLuminance + .05);
        expect(
          selectedContrast,
          greaterThanOrEqualTo(4.5),
          reason: 'Selected filter text must remain readable',
        );
      },
    );
  }
}
