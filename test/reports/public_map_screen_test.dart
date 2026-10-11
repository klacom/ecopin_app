import 'dart:async';
import 'package:image/image.dart' as image;
import 'package:dio/dio.dart' as dio;
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/maps/presentation/screens/maps_screen.dart';
import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_datasource.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/providers/public_report_map_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SyntheticConsentApi extends ApiClient {
  @override
  Future<dio.Response> getProfile() async => dio.Response(
    requestOptions: dio.RequestOptions(path: '/synthetic-profile'),
    data: {
      'profile': {'data_consent': true},
    },
    statusCode: 200,
  );
}

class _ControlledReports extends PublicReportMapDataSource {
  final requests = <(ReportViewport, Completer<ReportMapPage>)>[];
  _ControlledReports(super.client);
  @override
  Future<ReportMapPage> getPage(ReportViewport viewport, {int limit = 200}) {
    final completion = Completer<ReportMapPage>();
    requests.add((viewport, completion));
    return completion.future;
  }
}

class _SyntheticTiles extends TileProvider {
  static final bytes = image.encodePng(image.Image(width: 1, height: 1));
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(bytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ControlledReports reports;
  setUp(() async {
    final client = SupabaseClient(
      'https://synthetic.invalid',
      'synthetic-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(
        (request) async => http.Response(
          '${' ' * 11000}[]',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    addTearDown(client.dispose);
    // Initialize the client's JSON isolate outside the widget fake clock.
    await client.from('synthetic_fixture').select();
    reports = _ControlledReports(client);
    dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (call) async => switch (call.method) {
        'checkPermission' || 'requestPermission' => 3,
        'isLocationServiceEnabled' => true,
        'getLocationAccuracy' => 0,
        'getCurrentPosition' => {
          'latitude': 14.58,
          'longitude': 121.08,
          'accuracy': 1.0,
          'is_mocked': true,
        },
        _ => null,
      },
    );
    for (final channel in [
      'flutter.baseflow.com/geolocator_updates',
      'flutter.baseflow.com/geolocator_service_updates',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (_) async => null,
      );
    }
  });

  ReportMapPage page(int count) => ReportMapPage(
    reports: List.generate(
      count,
      (index) => ReportModel.fromJson({
        'id': 'synthetic-$index',
        'title': 'Synthetic report',
        'latitude': 14.58,
        'longitude': 121.08,
        'validation_status': 'approved',
        'created_at': '2026-10-11T00:00:00Z',
        'updated_at': '2026-10-11T00:00:00Z',
      }),
    ),
    hasMore: false,
  );

  Future<_ControlledReports> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_SyntheticConsentApi()),
          publicReportMapDataSourceProvider.overrideWithValue(reports),
        ],
        child: MaterialApp(home: MapScreen(tileProvider: _SyntheticTiles())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(reports.requests, hasLength(1));
    return reports;
  }

  testWidgets('map stays mounted through loading, failure and retry', (
    tester,
  ) async {
    final reports = await mount(tester);
    expect(find.byType(FlutterMap), findsOneWidget);
    reports.requests.first.$2.completeError(StateError('synthetic denied'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Reports could not load.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(reports.requests, hasLength(2));
    reports.requests.last.$2.complete(page(0));
    await tester.pump();
    await tester.pump();
    expect(find.text('0 public reports in this area'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'navigation changes viewport and old results cannot overwrite the current map',
    (tester) async {
      final reports = await mount(tester);
      reports.requests.first.$2.complete(page(0));
      await tester.pump();
      await tester.pump();
      final mapState = tester.state(find.byType(FlutterMap));
      await tester.drag(find.byType(FlutterMap), const Offset(100, 0));
      await tester.pump(const Duration(seconds: 1));
      final oldRequest = reports.requests.last;
      expect(oldRequest.$1, isNot(reports.requests.first.$1));
      await tester.drag(find.byType(FlutterMap), const Offset(0, 100));
      await tester.pump(const Duration(seconds: 1));
      expect(reports.requests.last.$1, isNot(oldRequest.$1));
      reports.requests.last.$2.complete(page(3));
      await tester.pump();
      await tester.pump();
      expect(find.text('3 public reports in this area'), findsOneWidget);
      oldRequest.$2.complete(page(1));
      await tester.pump();
      await tester.pump();
      expect(find.text('3 public reports in this area'), findsOneWidget);
      expect(tester.state(find.byType(FlutterMap)), same(mapState));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
