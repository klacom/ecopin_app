import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/shared/reports/presentation/screens/satisfaction_rating_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class SyntheticRatingApi extends ApiClient {
  final result = Completer<dio.Response>();
  var requests = 0;
  int? rating;
  @override
  Future<dio.Response> citizenCloseReport(String id, int value) { requests++; rating = value; return result.future; }
}
void main() {
  setUp(() => dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true'));
  testWidgets('successful feedback returns to the report instead of the root page', (tester) async {
    final api = SyntheticRatingApi();
    await tester.pumpWidget(ProviderScope(overrides: [apiClientProvider.overrideWithValue(api)], child: MaterialApp(scaffoldMessengerKey: messengerKey, theme: AppTheme.light,
      home: Builder(builder: (context) => Scaffold(body: TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SatisfactionRatingScreen(reportId: 'report-one'))), child: const Text('Report details')))))));
    await tester.tap(find.text('Report details'));
    await tester.pumpAndSettle();
    expect(find.textContaining('closes this report'), findsOneWidget);
    await tester.tap(find.text('😄 Very Satisfied'));
    await tester.ensureVisible(find.text('Submit feedback and close report'));
    await tester.tap(find.text('Submit feedback and close report'));
    await tester.pump();
    expect(api.requests, 1);
    expect(api.rating, 5);
    api.result.complete(dio.Response(requestOptions: dio.RequestOptions(path: '/synthetic-close'), statusCode: 200, data: {'status': 'closed'}));
    await tester.pumpAndSettle();
    expect(find.text('Report details'), findsOneWidget);
    expect(find.byType(SatisfactionRatingScreen), findsNothing);
  });
  testWidgets('five ratings and retained failure selection fit narrow large text', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = SyntheticRatingApi();
    await tester.pumpWidget(ProviderScope(overrides: [apiClientProvider.overrideWithValue(api)], child: MaterialApp(theme: AppTheme.dark,
      home: MediaQuery(data: const MediaQueryData(textScaler: TextScaler.linear(2)), child: const SatisfactionRatingScreen(reportId: 'report-one')))));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNWidgets(5));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('😄 Very Satisfied'));
    await tester.tap(find.text('😄 Very Satisfied'));
    await tester.ensureVisible(find.text('Submit feedback and close report'));
    await tester.tap(find.text('Submit feedback and close report'));
    await tester.pump();
    api.result.completeError(Exception('Synthetic request failed'));
    await tester.pumpAndSettle();
    expect(find.textContaining('selection is still here'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '😄 Very Satisfied')).selected, isTrue);
    expect(api.requests, 1);
    expect(tester.takeException(), isNull);
  });
}
