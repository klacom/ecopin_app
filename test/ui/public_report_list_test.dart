import 'dart:async';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/public_report_list.dart';
import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_datasource.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/providers/public_report_map_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ControlledFeed extends PublicReportMapDataSource {
  ControlledFeed(super.client);
  final requests = <(int, Completer<ReportMapPage>)>[];
  @override
  Future<ReportMapPage> getFeedPage({int offset = 0, int limit = 30}) {
    final completion = Completer<ReportMapPage>();
    requests.add((offset, completion));
    return completion.future;
  }
}

ReportModel report(String id) => ReportModel(
  id: id,
  title: 'Public concern $id',
  description: 'Public concern from a resident.',
  location: const LatLng(14.58, 121.08),
  locationPrecision: 'approximate',
  validationStatus: 'approved',
  status: 'in_progress',
  issueType: 'waste',
  createdAt: DateTime.utc(2026, 10, 21),
  updatedAt: DateTime.utc(2026, 10, 21),
);

void main() {
  late SupabaseClient client;
  setUp(() {
    client = SupabaseClient('https://synthetic.invalid', 'synthetic');
    addTearDown(client.dispose);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'public list retry, pagination, deduplication and refresh / $dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final feed = ControlledFeed(client);
        ReportModel? opened;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              publicReportMapDataSourceProvider.overrideWithValue(feed),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: PublicReportList(onOpen: (report) => opened = report),
              ),
            ),
          ),
        );
        feed.requests.last.$2.completeError(
          StateError('synthetic initial failure'),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Try again'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Try again'));
        await tester.pump();
        expect(feed.requests.last.$1, 0);
        feed.requests.last.$2.complete(
          ReportMapPage(reports: [report('a')], hasMore: true),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Public concern a'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Public concern a'));
        expect(opened?.id, 'a');
        await tester.scrollUntilVisible(find.text('Load more reports'), 250);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Load more reports'));
        await tester.pump();
        expect(feed.requests.last.$1, 1);
        feed.requests.last.$2.completeError(
          StateError('synthetic next page failure'),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Try again'), 250);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Try again'));
        await tester.pump();
        expect(feed.requests.last.$1, 1);
        feed.requests.last.$2.complete(
          ReportMapPage(reports: [report('a'), report('b')], hasMore: false),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Public concern b'), 250);
        expect(find.text('Public concern b'), findsOneWidget);
        expect(find.text('Load more reports'), findsNothing);
        final refresh = tester.state<RefreshIndicatorState>(
          find.byType(RefreshIndicator),
        );
        final refreshing = refresh.show();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(feed.requests.last.$1, 0);
        feed.requests.last.$2.complete(
          ReportMapPage(reports: [], hasMore: false),
        );
        await tester.pumpAndSettle();
        await refreshing;
        expect(find.text('No public reports available yet.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
