import 'dart:io';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/report_details_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'create_report_flow_test.dart' show SyntheticTiles;
import 'fixtures/local_video_controller.dart';

void main() {
  setUp(() => dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true'));
  for (final dark in [false, true]) {
    testWidgets(
      'citizen submitted video play control starts and pauses playback / $dark',
      (tester) async {
        final controller = SyntheticVideoController(
          File('synthetic-submitted.mp4'),
        );
        Uri? loadedSource;
        final report = ReportModel(
          id: 'synthetic-report',
          title: 'Street concern',
          location: const LatLng(14.58, 121.08),
          status: 'unresolved',
          validationStatus: 'approved',
          createdAt: DateTime.utc(2026, 10, 21),
          updatedAt: DateTime.utc(2026, 10, 21),
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: Scaffold(
                body: ReportDetailsBody(
                  report: report,
                  evidence: const [
                    {
                      'url':
                          'https://res.cloudinary.com/synthetic/video/upload/report.mp4',
                      'resource_type': 'video',
                    },
                  ],
                  isLoadingEvidence: false,
                  isLoadingCleanupTask: false,
                  tileProvider: SyntheticTiles(),
                  videoControllerFactory: (source) {
                    loadedSource = source;
                    return controller;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(loadedSource?.path, '/synthetic/video/upload/report.mp4');
        expect(controller.value.isPlaying, isFalse);
        final play = find.byIcon(Icons.play_circle_outline);
        await tester.ensureVisible(play);
        await tester.pumpAndSettle();
        await tester.tap(play, warnIfMissed: false);
        await tester.pump();
        expect(controller.value.isPlaying, isTrue);
        await tester.tap(find.byTooltip('Pause report video'));
        await tester.pump();
        expect(controller.value.isPlaying, isFalse);
        await tester.pumpWidget(const SizedBox());
        expect(controller.released, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
