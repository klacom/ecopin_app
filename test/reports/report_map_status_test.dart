import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_map_status.dart';
import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Outfit',
    )..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))).load();
  });
  testWidgets('compact map count keeps area context in semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 110,
            child: ReportMapStatus(
              compact: true,
              value: AsyncData(ReportMapPage(reports: [], hasMore: false)),
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('0 reports'), findsOneWidget);
    expect(tester.getSize(find.byType(ReportMapStatus)).height, lessThan(30));
    expect(
      tester.widget<Text>(find.text('0 reports')).semanticsLabel,
      '0 public reports in this area',
    );
  });

  Widget status(AsyncValue<ReportMapPage> value, VoidCallback retry) =>
      MaterialApp(
        home: Scaffold(
          body: ReportMapStatus(value: value, onRetry: retry),
        ),
      );
  testWidgets('loading identifies the current map area', (tester) async {
    await tester.pumpWidget(status(const AsyncLoading(), () {}));
    expect(find.text('Loading reports in this area…'), findsOneWidget);
  });
  testWidgets('request failure stays visible and offers a retry', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      status(AsyncError(StateError('synthetic failure'), StackTrace.empty), () {
        retries++;
      }),
    );
    expect(find.text('Reports could not load.'), findsOneWidget);
    expect(find.textContaining('synthetic failure'), findsNothing);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });
  testWidgets('valid empty map is distinguished from request failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      status(AsyncData(ReportMapPage(reports: [], hasMore: false)), () {}),
    );
    expect(find.text('0 public reports in this area'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });
  testWidgets('truncation is visible rather than claiming a complete map', (
    tester,
  ) async {
    await tester.pumpWidget(
      status(AsyncData(ReportMapPage(reports: [], hasMore: true)), () {}),
    );
    expect(
      find.text(
        'Showing the newest 200 reports in this area. Zoom in to see more.',
      ),
      findsOneWidget,
    );
  });
}
