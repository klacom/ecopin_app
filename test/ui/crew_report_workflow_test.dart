import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_reports_filter_bar.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

void main() {
  test(
    'crew list excludes rejected, cluster-only and foreign-task reports',
    () async {
      final reports = [
        for (final id in [
          'good',
          'rejected',
          'invalid',
          'cluster-only',
          'foreign',
        ])
          ReportModel.fromJson({
            'id': id,
            'cluster_id': 'cluster',
            'status': id == 'rejected' ? 'rejected' : 'unresolved',
            'validation_status': id == 'invalid' ? 'rejected' : 'validated',
            'cleanup_task_id': id == 'foreign' ? 'other' : 'task',
          }),
      ];
      final task = CleanupTask.fromJson({
        'id': 'task',
        'cluster_id': 'cluster',
        'report_ids': ['good', 'rejected', 'invalid', 'foreign'],
      });
      final container = ProviderContainer(
        overrides: [
          fieldCrewReportsProvider.overrideWith((ref) async => reports),
          allCleanupTasksProvider.overrideWith((ref) async => [task]),
        ],
      );
      addTearDown(container.dispose);
      final result = await container.read(assignedReportsProvider.future);
      expect(result.reports.map((r) => r.id), ['good']);
      expect(result.reportTaskMap, {'good': 'task'});
    },
  );
  for (final dark in [false, true]) {
    testWidgets('report filter supports enlarged text / $dark', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selected = 'All Status';
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              padding: const EdgeInsets.only(bottom: 24),
              viewPadding: const EdgeInsets.only(bottom: 24),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: FcReportsFilterBar(
              searchQuery: '',
              selectedStatus: 'All Status',
              selectedType: 'All Types',
              selectedValidation: 'All Validation',
              availableTypes: ['Waste'],
              onSearchChanged: (_) {},
              onStatusChanged: (value) => selected = value,
              onTypeChanged: (_) {},
              onValidationChanged: (_) {},
              onReset: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Filter reports'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Acknowledged'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text('Acknowledged'));
      await tester.tap(find.text('Acknowledged'));
      await tester.pumpAndSettle();
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Acknowledged'),
      );
      expect(chip.selected, isTrue);
      expect(chip.checkmarkColor, Colors.white);
      expect(find.text('Rejected'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Apply Filters'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      expect(selected, 'acknowledged');
      expect(tester.takeException(), isNull);
    });
  }
}
