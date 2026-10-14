import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/screens/reports_screen.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

ReportModel fixture(String id, String title, {String status = 'unresolved', String validation = 'approved', DateTime? rejectedAt}) => ReportModel(
  id: id, title: title, description: 'A local environmental concern.', location: const LatLng(14.575, 121.08), validationStatus: validation,
  status: status, rejectedAt: rejectedAt, rejectionReason: validation == 'rejected' ? 'Please include a clearer photograph.' : null,
  createdAt: DateTime.now(), updatedAt: DateTime.now(),
);

void main() {
  testWidgets('search and lifecycle filters preserve rejected-report visibility rules', (tester) async {
    final reports = [fixture('one', 'Waste at the market'), fixture('two', 'Flooding at school', status: 'resolved'),
      fixture('old', 'Old rejected concern', validation: 'rejected', rejectedAt: DateTime.now().subtract(const Duration(hours: 25)))];
    await tester.pumpWidget(ProviderScope(overrides: [myReportsProvider.overrideWith((ref) async => reports)], child: MaterialApp(theme: AppTheme.light, home: const ReportsScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Old rejected concern'), findsNothing);
    final search = find.byWidgetPredicate((widget) => widget is TextField && widget.decoration?.labelText == 'Search my reports');
    expect(search, findsOneWidget);
    await tester.enterText(search, 'market');
    await tester.pump();
    expect(find.text('Waste at the market'), findsOneWidget);
    expect(find.text('Flooding at school'), findsNothing);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Resolved'));
    await tester.pump();
    expect(find.text('Waste at the market'), findsNothing);
    expect(find.text('Flooding at school'), findsOneWidget);
  });
  testWidgets('long titles and review badges wrap at 320px and 2x text', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reports = [fixture('long', 'A very long report title about waste beside a residential street in Pasig', validation: 'pending_ai_validation')];
    await tester.pumpWidget(ProviderScope(overrides: [myReportsProvider.overrideWith((ref) async => reports)], child: MaterialApp(theme: AppTheme.dark,
      home: MediaQuery(data: const MediaQueryData(textScaler: TextScaler.linear(2)), child: const ReportsScreen()))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Awaiting automated review'), findsOneWidget);
  });
}
