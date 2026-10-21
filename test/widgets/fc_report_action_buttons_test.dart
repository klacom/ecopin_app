import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_report_action_buttons.dart';

void main() {
  ReportModel createDummyReport({
    String status = 'unresolved',
    String? issueType,
  }) {
    return ReportModel(
      id: 'rep-1',
      title: 'Illegal Dumping Test',
      status: status,
      issueType: issueType,
      location: const LatLng(14.5, 121.0),
      validationStatus: 'validated',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  testWidgets(
    'acknowledged stage on unresolved status does not repeat acknowledge',
    (tester) async {
      final report = ReportModel.fromJson({
        'id': 'report',
        'status': 'unresolved',
        'stage': 'acknowledged',
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FcReportActionButtons(
              report: report,
              isAssigned: true,
              hasBeforePhoto: false,
              hasAfterPhoto: false,
              onStatusChange: (_) async {},
              onViewOnMap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Mark as Acknowledged'), findsNothing);
      expect(find.textContaining('Upload a Before photo'), findsOneWidget);
    },
  );

  testWidgets(
    'WT-92: FcReportActionButtons disables button immediately upon tap to prevent duplicate clicks',
    (tester) async {
      final completer = Completer<void>();
      var callCount = 0;
      String? updatedStatus;

      final report = createDummyReport(status: 'unresolved');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FcReportActionButtons(
              report: report,
              isAssigned: true,
              hasBeforePhoto: true,
              hasAfterPhoto: true,
              onStatusChange: (status) async {
                callCount++;
                updatedStatus = status;
                await completer.future;
              },
              onViewOnMap: () {},
            ),
          ),
        ),
      );

      // Verify initial state: "Mark as Acknowledged" is enabled
      final buttonFinder = find.widgetWithText(
        ElevatedButton,
        'Mark as Acknowledged',
      );
      expect(buttonFinder, findsOneWidget);
      final initialButton = tester.widget<ElevatedButton>(buttonFinder);
      expect(initialButton.onPressed, isNotNull);

      // Tap once
      await tester.tap(buttonFinder);
      await tester.pump(); // rebuild with _isSubmitting = true

      // Verify immediate lock: button now shows CircularProgressIndicator and onPressed is null
      expect(callCount, equals(1));
      expect(updatedStatus, equals('acknowledged'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final submittingButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(submittingButton.onPressed, isNull);

      // Try tapping again while async action is in flight (simulate double click)
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      // Ensure no secondary call was triggered
      expect(callCount, equals(1));

      // Resolve async action
      completer.complete();
      await tester.pumpAndSettle();

      // After async completes, submitting spinner is gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'acknowledged report offers photo guidance without a manual Responded action',
    (tester) async {
      var statusCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FcReportActionButtons(
              report: createDummyReport(status: 'acknowledged'),
              isAssigned: true,
              hasBeforePhoto: false,
              hasAfterPhoto: false,
              onStatusChange: (_) async {
                statusCalls++;
              },
              onViewOnMap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Mark as Responded'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.textContaining('Upload a Before photo'), findsOneWidget);
      expect(find.text('View on Map'), findsOneWidget);
      expect(statusCalls, 0);
    },
  );

  testWidgets(
    'WT-92: FcReportActionButtons enforces photo requirements before resolving',
    (tester) async {
      final report = createDummyReport(status: 'responded');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FcReportActionButtons(
              report: report,
              isAssigned: true,
              hasBeforePhoto: false,
              hasAfterPhoto: false,
              onStatusChange: (_) async {},
              onViewOnMap: () {},
            ),
          ),
        ),
      );

      // Verify disabled state when photos are missing
      final buttonFinder = find.widgetWithText(
        ElevatedButton,
        'Cleanup Completed',
      );
      expect(buttonFinder, findsOneWidget);
      final btn = tester.widget<ElevatedButton>(buttonFinder);
      expect(btn.onPressed, isNull);
      expect(
        find.text('Requires both Before and After photos.'),
        findsOneWidget,
      );
    },
  );
}
