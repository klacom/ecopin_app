import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/report_details_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'create_report_flow_test.dart' show SyntheticTiles;

void main() {
  setUp(() => dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true'));
  for (final officer in [false, true]) {
    testWidgets('shared details expose working tools only for officer=$officer', (tester) async {
      final report = ReportModel(id: 'staff-report', title: 'Waste beside a street', location: const LatLng(14.575, 121.08), validationStatus: 'approved', status: 'unresolved', createdAt: DateTime.utc(2026, 10, 12), updatedAt: DateTime.utc(2026, 10, 12));
      final router = GoRouter(initialLocation: '/details', routes: [
        GoRoute(path: '/details', builder: (context, state) => Scaffold(body: ReportDetailsBody(report: report, evidence: const [], isLoadingEvidence: false, isLoadingCleanupTask: false, isOfficerUser: officer, tileProvider: SyntheticTiles()))),
        GoRoute(path: '/officer/reports/:id', builder: (context, state) => const Scaffold(body: Text('Authorized report tools'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(child: MaterialApp.router(theme: AppTheme.light, routerConfig: router)));
      await tester.pumpAndSettle();
      expect(find.text('Mark as Resolved'), findsNothing);
      expect(find.text('Mark as In Progress'), findsNothing);
      if (officer) {
        await tester.ensureVisible(find.text('Open officer report tools'));
        await tester.tap(find.text('Open officer report tools'));
        await tester.pumpAndSettle();
        expect(find.text('Authorized report tools'), findsOneWidget);
      } else {
        expect(find.text('Open officer report tools'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
