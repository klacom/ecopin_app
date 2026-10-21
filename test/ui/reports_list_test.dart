import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/screens/reports_screen.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

ReportModel fixture(
  String id,
  String title, {
  String status = 'unresolved',
  String validation = 'approved',
  DateTime? rejectedAt,
}) => ReportModel(
  id: id,
  title: title,
  description: 'A local environmental concern.',
  location: const LatLng(14.575, 121.08),
  validationStatus: validation,
  status: status,
  rejectedAt: rejectedAt,
  rejectionReason: validation == 'rejected'
      ? 'Please include a clearer photograph.'
      : null,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

void main() {
  testWidgets(
    'search and lifecycle filters preserve rejected-report visibility rules',
    (tester) async {
      final reports = [
        fixture('one', 'Waste at the market'),
        fixture('two', 'Flooding at school', status: 'resolved'),
        fixture(
          'old',
          'Old rejected concern',
          validation: 'rejected',
          rejectedAt: DateTime.now().subtract(const Duration(hours: 25)),
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [myReportsProvider.overrideWith((ref) async => reports)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Old rejected concern'), findsNothing);
      final search = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Search my reports',
      );
      expect(search, findsOneWidget);
      await tester.enterText(search, 'market');
      await tester.pump();
      expect(find.text('Waste at the market'), findsOneWidget);
      expect(find.text('Flooding at school'), findsNothing);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(find.text('My Reports'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      await tester.tap(find.byTooltip('Filter reports'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(RadioListTile<String>, 'Resolved'));
      await tester.ensureVisible(find.text('Apply filters'));
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      expect(find.text('Waste at the market'), findsNothing);
      expect(find.text('Flooding at school'), findsOneWidget);
    },
  );
  testWidgets('long titles and review badges wrap at 320px and 2x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reports = [
      fixture(
        'long',
        'A very long report title about waste beside a residential street in Pasig',
        validation: 'pending_ai_validation',
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [myReportsProvider.overrideWith((ref) async => reports)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const ReportsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Awaiting automated review'), findsOneWidget);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'status sheet applies, dismisses and resets at 320px / 2x / $dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              myReportsProvider.overrideWith(
                (ref) async => [
                  fixture('open', 'Open concern'),
                  fixture('done', 'Completed concern', status: 'resolved'),
                ],
              ),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const ReportsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<void> tapVisible(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byTooltip('Filter reports'));
        await tester.pumpAndSettle();
        await tapVisible(
          find.widgetWithText(RadioListTile<String>, 'Resolved'),
        );
        await tapVisible(find.byTooltip('Close filters'));
        expect(find.text('Open concern'), findsOneWidget);
        await tester.tap(find.byTooltip('Filter reports'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
              .groupValue,
          'All',
        );
        await tapVisible(
          find.widgetWithText(RadioListTile<String>, 'Resolved'),
        );
        await tapVisible(find.text('Apply filters'));
        expect(find.text('Open concern'), findsNothing);
        expect(find.text('Completed concern'), findsOneWidget);
        expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
        await tester.tap(find.byTooltip('Filter reports'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
              .groupValue,
          'resolved',
        );
        await tapVisible(find.text('Reset status'));
        await tapVisible(find.text('Apply filters'));
        expect(find.text('Open concern'), findsOneWidget);
        expect(
          tester.widget<Badge>(find.byType(Badge)).isLabelVisible,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
