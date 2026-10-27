import 'dart:async';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_report_table.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/response_deadline_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ReportModel report(
  String id,
  String deadline, {
  String status = 'unresolved',
}) => ReportModel.fromJson({
  'id': id,
  'title': id,
  'status': status,
  'validation_status': 'approved',
  'sla_started_at': '2026-10-27T00:00:00Z',
  'deadline_at': deadline,
});

void main() {
  final now = DateTime.parse('2026-10-27T20:00:00Z');
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets('deadline wraps at 320px and 2x text in ${theme.brightness}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            responseDeadlineClockProvider.overrideWith(
              (ref) => Stream.value(now),
            ),
          ],
          child: MaterialApp(
            theme: theme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ResponseDeadlineIndicator(
                      report: report('risk', '2026-10-28T00:00:00Z'),
                      details: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Response deadline approaching · 4h left'),
        findsOneWidget,
      );
      expect(find.textContaining('Target response:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'crew filters show only approaching or overdue reports and refresh with time',
    (tester) async {
      final clock = StreamController<DateTime>();
      addTearDown(clock.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            responseDeadlineClockProvider.overrideWith((ref) => clock.stream),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  FcReportTable(
                    taskId: 'task',
                    reports: [
                      report('Approaching report', '2026-10-28T00:00:00Z'),
                      report('Overdue report', '2026-10-27T19:00:00Z'),
                      report(
                        'Resolved report',
                        '2026-10-27T19:00:00Z',
                        status: 'resolved',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      clock.add(now);
      await tester.pumpAndSettle();
      await tester.tap(find.text('At risk (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Approaching report'), findsOneWidget);
      expect(find.text('Overdue report'), findsNothing);
      clock.add(DateTime.parse('2026-10-28T00:00:00Z'));
      await tester.pumpAndSettle();
      expect(find.text('No reports in this view.'), findsOneWidget);
      await tester.tap(find.text('Overdue (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Approaching report'), findsOneWidget);
      expect(find.text('Overdue report'), findsOneWidget);
      expect(find.text('Resolved report'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
