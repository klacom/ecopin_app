import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/data/models/report_prefill_data.dart';
import 'package:ecopin_app/shared/reports/presentation/screens/create_report_screen.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/report_details_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'create_report_flow_test.dart' show SyntheticAddress, SyntheticTiles;

void main() {
  setUp(() => dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true'));
  const location = LatLng(14.575, 121.08);
  for (final dark in [false, true]) {
    for (final create in [false, true]) {
      testWidgets(
        'report location tip matches coordinates / create=$create / dark=$dark',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final report = ReportModel(
            id: 'synthetic',
            title: 'Public concern',
            location: location,
            validationStatus: 'approved',
            status: 'unresolved',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          );
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                home: create
                    ? CreateReportScreen(
                        prefillData: const ReportPrefillData(
                          location: location,
                        ),
                        tileProvider: SyntheticTiles(),
                        locationSearchService: SyntheticAddress(),
                      )
                    : Scaffold(
                        body: ReportDetailsBody(
                          report: report,
                          evidence: const [],
                          isLoadingEvidence: false,
                          isLoadingCleanupTask: false,
                          tileProvider: SyntheticTiles(),
                        ),
                      ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final map = find.byType(FlutterMap);
          await tester.ensureVisible(map);
          await tester.pumpAndSettle();
          final marker = tester
              .widget<MarkerLayer>(find.byType(MarkerLayer))
              .markers
              .single;
          expect(marker.point, location);
          expect(marker.alignment, Alignment.topCenter);
          expect(tester.widget<FlutterMap>(map).options.initialZoom, 17);
          final tip =
              tester.getBottomLeft(find.byType(ReportPinFrame)) +
              const Offset(ReportPinFrame.width / 2, 0);
          expect((tip - tester.getCenter(map)).distance, lessThan(1));
          if (create) {
            final tapped = tester.getCenter(map) + const Offset(30, 20);
            await tester.tapAt(tapped);
            await tester.pump(const Duration(milliseconds: 350));
            await tester.pumpAndSettle();
            final movedTip =
                tester.getBottomLeft(find.byType(ReportPinFrame)) +
                const Offset(ReportPinFrame.width / 2, 0);
            expect((movedTip - tapped).distance, lessThan(1));
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
