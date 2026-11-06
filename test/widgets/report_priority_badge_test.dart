import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_priority_badge.dart';

void main() {
  test('priority does not infer urgency from severity or approval', () {
    expect(citizenPriorityLabel('urgent'), 'Urgent');
    expect(citizenPriorityLabel('non_urgent'), 'Non-urgent');
    expect(citizenPriorityLabel(' URGENT '), 'Urgent');
    for (final value in [null, '', 'high', 'approved']) {
      expect(citizenPriorityLabel(value), 'Not specified');
    }
  });
  for (final dark in [false, true]) {
    for (final value in ['urgent', 'non_urgent', null]) {
      testWidgets(
        'priority badge $value dark=$dark fits narrow enlarged text',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: Scaffold(
                  body: SizedBox(
                    width: 240,
                    child: ReportPriorityBadge(priority: value),
                  ),
                ),
              ),
            ),
          );
          expect(
            find.text('Citizen priority: ${citizenPriorityLabel(value)}'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
