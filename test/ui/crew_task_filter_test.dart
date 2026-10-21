import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_filter_bar.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('task filters fit short screen and enlarged text / $dark', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var appliedStatus = 'All';
      var appliedAssigned = false;
      await tester.pumpWidget(MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            padding: const EdgeInsets.only(bottom: 24),
            viewPadding: const EdgeInsets.only(bottom: 24),
          ),
          child: child!,
        ),
        home: Scaffold(body: FcTaskFilterBar(
          searchQuery: '', onSearchChanged: (_) {}, statusFilter: 'All',
          onStatusChanged: (value) => appliedStatus = value,
          assignedToMeOnly: false,
          onAssignmentChanged: (value) => appliedAssigned = value,
          onReset: () {},
        )),
      ));
      await tester.tap(find.byTooltip('Filter cleanup tasks'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final all = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All'));
      expect(all.checkmarkColor, Colors.white);
      await tester.ensureVisible(find.text('In Progress'));
      await tester.tap(find.text('In Progress'));
      await tester.pumpAndSettle();
      final selected = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'In Progress'));
      expect(selected.selected, isTrue);
      expect(selected.checkmarkColor, Colors.white);
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(find.text('Apply Filters')).dy, lessThan(544));
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      expect(appliedStatus, 'In Progress');
      expect(appliedAssigned, isTrue);
      expect(find.text('Filters'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
