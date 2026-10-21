import 'dart:async';
import 'dart:ui' as ui;
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_map_info.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/my_marker_cluster_layer.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_map_preview.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/map_privacy_consent_dialog.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_map_status.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

ReportModel previewReport({
  String title = 'Waste beside a narrow street with a very long report title',
}) => ReportModel(
  id: 'public-report',
  title: title,
  description:
      'A resident reported waste beside the street. The public pin shows an approximate area.',
  location: const LatLng(14.58, 121.08),
  locationPrecision: 'approximate',
  issueType: 'illegal_dumping',
  status: 'in_progress',
  validationStatus: 'approved',
  createdAt: DateTime.utc(2026, 10, 14),
  updatedAt: DateTime.utc(2026, 10, 14),
);

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'legend shows an illustrative cluster at 320dp and 2x / $dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(body: ReportMapInfo(openSource: (_) {})),
          ),
        );
        expect(tester.widget<Text>(find.text('© OpenStreetMap contributors')).textAlign, TextAlign.center);
        final sample = find.byType(ReportClusterBadge);
        expect(sample, findsOneWidget);
        expect(tester.widget<ReportClusterBadge>(sample).onActivate, isNull);
        expect(find.textContaining('Report cluster'), findsOneWidget);
        expect(
          find.textContaining('number shows how many reports'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('CARTO basemap credits'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'public preview keeps the full title and approximate-location context at 320px/2x',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final report = previewReport();
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (sheetContext) => MediaQuery(
                      data: MediaQuery.of(
                        sheetContext,
                      ).copyWith(textScaler: const TextScaler.linear(2)),
                      child: ReportMapPreview(report: report),
                    ),
                  );
                },
                child: const Text('Preview'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text(report.title)).maxLines, isNull);
      await tester.ensureVisible(
        find.text('Approximate location shown on the public map.'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('View report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View report'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    },
  );
  testWidgets(
    'marker names the report/status and has a coordinate-pin footprint and native action',
    (tester) async {
      var opens = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: ReportMarker(
                status: 'waiting_for_feedback',
                title: 'Street concern',
                selected: true,
                onTap: () => opens++,
              ),
            ),
          ),
        ),
      );
      final action = find.byTooltip('Street concern, Waiting for Feedback');
      expect(tester.getSize(action), const Size(56, 64));
      await tester.tap(action);
      expect(opens, 1);
      expect(
        tester.widget<ReportMarker>(find.byType(ReportMarker)).selected,
        isTrue,
      );
    },
  );
  for (final coincident in [true, false]) {
    testWidgets(
      'keyboard cluster activation preserves SDK ${coincident ? 'spiderfying' : 'zoom'} behavior',
      (tester) async {
        final controller = MapController();
        final semantics = tester.ensureSemantics();
        addTearDown(controller.dispose);
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: coincident),
                child: child!,
              ),
              home: Scaffold(
                body: FlutterMap(
                  mapController: controller,
                  options: const MapOptions(
                    initialCenter: LatLng(14.58, 121.08),
                    initialZoom: 13,
                    minZoom: 3,
                    maxZoom: 18,
                  ),
                  children: [
                    MyMarkerClusterLayer(
                      markers: List.generate(
                        2,
                        (index) => Marker(
                          point: LatLng(
                            14.58 + (coincident ? 0 : index * .001),
                            121.08,
                          ),
                          width: ReportPinFrame.width,
                          height: ReportPinFrame.height,
                          alignment: Alignment.topCenter,
                          child: ReportMarker(
                            status: 'unresolved',
                            title: 'Report $index',
                            onTap: () {},
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final badge = find.byType(ReportClusterBadge).first;
          expect(
            tester.widget<ReportClusterBadge>(badge).onActivate,
            isNotNull,
          );
          expect(
            tester
                .getSemantics(find.bySemanticsLabel('View 2 nearby reports'))
                .getSemanticsData()
                .hasAction(ui.SemanticsAction.tap),
            isTrue,
          );
          expect(tester.getSize(badge), const Size(56, 64));
          final focusable = find.descendant(
            of: badge,
            matching: find.byType(FocusableActionDetector),
          );
          tester
              .widget<FocusableActionDetector>(focusable)
              .focusNode!
              .requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          if (coincident) {
            expect(controller.camera.zoom, 13);
            expect(find.byType(ReportMarker), findsNWidgets(2));
          } else {
            expect(controller.camera.zoom, greaterThan(13));
          }
        } finally {
          semantics.dispose();
        }
      },
    );
  }
  testWidgets(
    'failed consent save stays open and blocks repeat requests while saving',
    (tester) async {
      final response = Completer<void>();
      final choices = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: MapPrivacyConsentDialog(
              onSave: (value) {
                choices.add(value);
                return response.future;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Agree'));
      await tester.pump();
      expect(choices, [true]);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Agree'))
            .onPressed,
        isNull,
      );
      response.completeError(StateError('Synthetic preference failure'));
      await tester.pumpAndSettle();
      expect(
        find.text('We could not save your preference. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Data Privacy Consent'), findsOneWidget);
    },
  );
  testWidgets(
    'map failure/retry wraps at narrow width and retains a stale-data notice',
    (tester) async {
      var retries = 0;
      final feed = StreamController<ReportMapPage>();
      addTearDown(feed.close);
      final provider = StreamProvider<ReportMapPage>((ref) => feed.stream);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 224,
                  child: MediaQuery(
                    data: const MediaQueryData(
                      textScaler: TextScaler.linear(2),
                    ),
                    child: Consumer(
                      builder: (context, ref, _) => ReportMapStatus(
                        value: ref.watch(provider),
                        onRetry: () => retries++,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      feed.add(ReportMapPage(reports: [previewReport()], hasMore: false));
      await tester.pump();
      feed.addError(StateError('Synthetic refresh failure'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Showing the last loaded reports.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
