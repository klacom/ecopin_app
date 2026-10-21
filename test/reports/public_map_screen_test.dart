import 'package:ecopin_app/shared/maps/presentation/widgets/report_map_status.dart';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as image;
import 'package:dio/dio.dart' as dio;
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_map_preview.dart';
import 'package:ecopin_app/shared/maps/presentation/screens/maps_screen.dart';
import 'package:ecopin_app/shared/reports/data/datasources/public_report_map_datasource.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/providers/public_report_map_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SyntheticConsentApi extends ApiClient {
  bool fail = false;
  int reads = 0;
  @override
  Future<dio.Response> getProfile() async {
    reads++;
    if (fail) throw StateError('Synthetic privacy read failure');
    return dio.Response(
      requestOptions: dio.RequestOptions(path: '/synthetic-profile'),
      data: {
        'profile': {'data_consent': true},
      },
      statusCode: 200,
    );
  }
}

class _ControlledReports extends PublicReportMapDataSource {
  final requests = <(ReportViewport, Completer<ReportMapPage>)>[];
  _ControlledReports(super.client);
  final feedRequests = <Completer<ReportMapPage>>[];
  @override
  Future<ReportMapPage> getFeedPage({int offset = 0, int limit = 30}) {
    final request = Completer<ReportMapPage>();
    feedRequests.add(request);
    return request.future;
  }

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
  setUpAll(() async {
    await (FontLoader('Outfit')
          ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Outfit-Medium.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Outfit-SemiBold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
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
      'rotation_sensor/method',
      'rotation_sensor/orientation',
      'flutter.baseflow.com/geolocator_updates',
      'flutter.baseflow.com/geolocator_service_updates',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (_) async => null,
      );
    }
  });

  ReportMapPage page(
    int count, {
    String title = 'Synthetic report',
    bool approximate = false,
  }) => ReportMapPage(
    reports: List.generate(
      count,
      (index) => ReportModel.fromJson({
        'id': 'synthetic-$index',
        'title': title,
        'location_precision': approximate ? 'approximate' : 'exact',
        'latitude': 14.58,
        'longitude': 121.08,
        'validation_status': 'approved',
        'created_at': '2026-10-11T00:00:00Z',
        'updated_at': '2026-10-11T00:00:00Z',
      }),
    ),
    hasMore: false,
  );

  Future<_ControlledReports> mount(
    WidgetTester tester, {
    GoRouter? router,
    bool dark = false,
    double scale = 1,
    _SyntheticConsentApi? consent,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(
            consent ?? _SyntheticConsentApi(),
          ),
          publicReportMapDataSourceProvider.overrideWithValue(reports),
        ],
        child: router == null
            ? MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: RepaintBoundary(
                    key: const Key('map-capture'),
                    child: child!,
                  ),
                ),
                home: MapScreen(tileProvider: _SyntheticTiles()),
              )
            : MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(reports.requests, hasLength(1));
    return reports;
  }

  testWidgets('report status sits beside Map/List on a phone toolbar', (
    tester,
  ) async {
      tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reports = await mount(tester);
    reports.requests.first.$2.complete(page(7));
    await tester.pumpAndSettle();
    final controls = tester.getRect(find.byType(SegmentedButton<bool>));
    final status = tester.getRect(find.byType(ReportMapStatus));
    expect(status.left, greaterThanOrEqualTo(controls.right));
    expect(
      status.bottom,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(FlutterMap)).dy),
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).bottomNavigationBar,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'citizen list browses public reports independently and preserves the map',
    (tester) async {
      final reports = await mount(tester);
      reports.requests.first.$2.complete(page(0));
      await tester.pumpAndSettle();
      final map = tester.state(find.byType(FlutterMap));
      expect(reports.feedRequests, isEmpty);
      await tester.tap(find.text('List'));
      await tester.pump();
      expect(reports.feedRequests, hasLength(1));
      reports.feedRequests.single.complete(
        page(1, title: 'Public concern from another resident'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Public concern from another resident'), findsOneWidget);
      expect(find.text('Search this area'), findsNothing);
      await tester.tap(find.text('Public concern from another resident'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportMapPreview), findsOneWidget);
      await tester.tap(find.byTooltip('Close report preview'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(FlutterMap)), same(map));
      expect(reports.requests, hasLength(1));
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();
      expect(reports.feedRequests, hasLength(1));
      expect(find.text('Public concern from another resident'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'empty heatmap survives repeated zooms and refreshing an empty area',
    (tester) async {
      final reports = await mount(tester);
      reports.requests.first.$2.complete(page(0));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Show report heatmap'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final controller = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!;
      for (final zoom in [16.0, 13.0, 17.0, 14.0]) {
        controller.move(controller.camera.center, zoom);
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull);
      }
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.text('Search this area'), findsNothing);
      expect(tester.takeException(), isNull);
      for (final request in reports.requests) {
        if (!request.$2.isCompleted) request.$2.complete(page(0));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(FlutterMap), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

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
    'panning fetches after 150ms and old results cannot overwrite the current map',
    (tester) async {
      final reports = await mount(tester);
      reports.requests.first.$2.complete(page(0));
      await tester.pumpAndSettle();
      final mapState = tester.state(find.byType(FlutterMap));
      final controller = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!;
      controller.move(const LatLng(14.65, 121.15), 15);
      await tester.pump(const Duration(milliseconds: 149));
      expect(reports.requests, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(reports.requests, hasLength(2));
      final oldRequest = reports.requests.last;
      controller.move(const LatLng(14.7, 121.2), 15);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(reports.requests, hasLength(3));
      reports.requests.last.$2.complete(page(3));
      await tester.pumpAndSettle();
      expect(find.text('3 public reports in this area'), findsOneWidget);
      oldRequest.$2.complete(page(1));
      await tester.pumpAndSettle();
      expect(find.text('3 public reports in this area'), findsOneWidget);
      expect(find.text('Search this area'), findsNothing);
      expect(tester.state(find.byType(FlutterMap)), same(mapState));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('returning to a cached area needs no new request', (
    tester,
  ) async {
    final reports = await mount(tester);
    reports.requests.first.$2.complete(page(0));
    await tester.pumpAndSettle();
    final controller = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!;
    final originalCenter = controller.camera.center;
    controller.move(originalCenter, 16);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(reports.requests, hasLength(1));
    controller.move(const LatLng(14.7, 121.2), 15);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    reports.requests.last.$2.complete(page(2));
    await tester.pumpAndSettle();
    controller.move(originalCenter, 15);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(reports.requests, hasLength(2));
    expect(find.text('0 public reports in this area'), findsOneWidget);
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();
    expect(reports.requests, hasLength(3));
    reports.requests.last.$2.complete(page(1));
    await tester.pumpAndSettle();
    expect(find.text('1 public report in this area'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'preview selection remains stable through a refresh and uses only public data',
    (tester) async {
      await mount(tester);
      reports.requests.first.$2.complete(
        page(1, title: 'Original report', approximate: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Original report, Unresolved'));
      await tester.pumpAndSettle();
      expect(reports.requests, hasLength(1));
      expect(
        find.text('Approximate location shown on the public map.'),
        findsOneWidget,
      );
      expect(
        tester.widget<ReportMarker>(find.byType(ReportMarker)).selected,
        isTrue,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MapScreen)),
      );
      container.invalidate(publicReportMapProvider(reports.requests.first.$1));
      await tester.pump();
      expect(reports.requests, hasLength(2));
      expect(find.byType(ReportMarker), findsOneWidget);
      reports.requests.last.$2.complete(
        page(1, title: 'Updated report', approximate: true),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ReportMapPreview>(find.byType(ReportMapPreview))
            .report
            .title,
        'Original report',
      );
      expect(
        tester.widget<ReportMarker>(find.byType(ReportMarker)).title,
        'Updated report',
      );
      await tester.tap(find.byTooltip('Close report preview'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ReportMarker>(find.byType(ReportMarker)).selected,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'view report closes the sheet before navigating with the live map context',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/maps',
        routes: [
          GoRoute(
            path: '/maps',
            builder: (_, _) => MapScreen(tileProvider: _SyntheticTiles()),
          ),
          GoRoute(
            path: '/reports/:id',
            builder: (_, state) => Scaffold(
              body: Text('Report destination ${state.pathParameters['id']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await mount(tester, router: router);
      reports.requests.first.$2.complete(page(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Synthetic report, Unresolved'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View report'));
      await tester.pumpAndSettle();
      expect(find.text('Report destination synthetic-0'), findsOneWidget);
      expect(find.byType(ReportMapPreview), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'theme changes update map tiles without replacing the mounted map',
    (tester) async {
      await mount(tester);
      reports.requests.first.$2.complete(page(0));
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(FlutterMap));
      expect(
        tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
        contains('light_all'),
      );
      await mount(tester, dark: true);
      expect(
        tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
        contains('dark_all'),
      );
      expect(tester.state(find.byType(FlutterMap)), same(state));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('failed privacy read is recoverable without inventing consent', (
    tester,
  ) async {
    final consent = _SyntheticConsentApi()..fail = true;
    await mount(tester, consent: consent);
    reports.requests.first.$2.complete(page(0));
    await tester.pumpAndSettle();
    expect(
      find.text('Privacy preferences could not load. Please try again.'),
      findsOneWidget,
    );
    consent.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(consent.reads, 2);
    expect(find.text('Data Privacy Consent'), findsNothing);
    expect(find.byType(FlutterMap), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  for (final size in [
    const Size(320, 480),
    const Size(320, 700),
    const Size(700, 360),
    const Size(768, 900),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'map chrome ${size.width}x${size.height} / ${dark ? 'dark' : 'light'} / 2x',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await mount(tester, dark: dark, scale: 2);
          reports.requests.first.$2.complete(page(1));
          await tester.pumpAndSettle();
          expect(
            tester.getBottomRight(find.byType(ReportMapStatus)).dy,
            lessThanOrEqualTo(
              tester.getTopLeft(find.byType(FlutterMap)).dy + 1,
            ),
          );
          final info = tester.getRect(find.byTooltip('Map legend and credits'));
          expect(info.top, greaterThanOrEqualTo(0));
          expect(info.bottom, lessThanOrEqualTo(size.height));
          expect(find.text('© OpenStreetMap contributors'), findsNothing);
          expect(tester.takeException(), isNull);
          final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
          if (output != null) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('map-capture')),
            );
            await tester.runAsync(() async {
              final warm = await boundary.toImage();
              warm.dispose();
            });
            await tester.pump();
            await tester.runAsync(() async {
              final capture = await boundary.toImage();
              final bytes = await capture.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$output/map-${size.width.toInt()}-${dark ? 'dark' : 'light'}-2x.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              capture.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
