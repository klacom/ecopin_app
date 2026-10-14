import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'native chip, button and dialog text use Outfit / ${dark ? 'dark' : 'light'}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: ListView(
                  children: [
                    ChoiceChip(
                      label: const Text('All concerns'),
                      selected: true,
                      onSelected: (_) {},
                    ),
                    TextButton(onPressed: () {}, child: const Text('Review')),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const AlertDialog(
                          title: Text('Confirm update'),
                          content: Text(
                            'Review the details before continuing.',
                          ),
                        ),
                      ),
                      child: const Text('Open confirmation'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in [
          'All concerns',
          'Review',
          'Cancel',
          'Open confirmation',
        ]) {
          expect(
            tester
                .renderObject<RenderParagraph>(find.text(label))
                .text
                .style!
                .fontFamily,
            'Outfit',
            reason: '$label must not fall back to a platform font',
          );
        }
        await tester.tap(find.text('Open confirmation'));
        await tester.pumpAndSettle();
        for (final label in [
          'Confirm update',
          'Review the details before continuing.',
        ]) {
          expect(
            tester
                .renderObject<RenderParagraph>(find.text(label))
                .text
                .style!
                .fontFamily,
            'Outfit',
          );
        }
      },
    );
  }
}
