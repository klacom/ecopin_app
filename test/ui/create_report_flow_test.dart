import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/services/location_search_service.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/presentation/screens/create_report_screen.dart';
import 'package:ecopin_app/shared/reports/data/models/report_prefill_data.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'fixtures/local_video_controller.dart';

class SyntheticTiles extends TileProvider {
  static final bytes = image.encodePng(image.Image(width: 1, height: 1));
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(bytes);
}

class SyntheticAddress extends LocationSearchService {
  var requests = 0;
  @override
  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    requests++;
    return 'Rosario, Pasig City, Metro Manila';
  }
}

class SyntheticPicker extends ImagePicker {
  SyntheticPicker(this.path);
  final String path;
  Object? failure;
  String? videoPath;
  ImageSource? videoSource;
  Duration? videoMaximum;
  var requests = 0;
  Completer<List<XFile>>? pendingSelection;
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    requests++;
    if (failure != null) throw failure!;
    return pendingSelection == null ? [XFile(path)] : pendingSelection!.future;
  }

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    requests++;
    if (failure != null) throw failure!;
    return XFile(path);
  }

  @override
  Future<XFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async {
    requests++;
    videoSource = source;
    videoMaximum = maxDuration;
    if (failure != null) throw failure!;
    return videoPath == null ? null : XFile(videoPath!);
  }
}

class SyntheticReportApi extends ApiClient {
  int videoMaximum = 8;
  bool failVideoPolicy = false;
  @override
  Future<dio.Response> getReportVideoPolicy() async {
    if (failVideoPolicy) throw StateError('Settings unavailable');
    return dio.Response(
      requestOptions: dio.RequestOptions(path: '/api/reports/media-policy'),
      data: {'min_seconds': 5, 'max_seconds': videoMaximum},
    );
  }

  final result = Completer<dio.Response>();
  var requests = 0;
  Map<String, Object?>? submitted;
  @override
  Future<dio.Response> createReport({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    List<String>? imagePaths,
    List<String>? cleanImagePaths,
    String? videoPath,
    bool onPrivateProperty = false,
    String scaleLevel = 'medium',
    String obstructionLevel = 'none',
    double? photoLat,
    double? photoLng,
    double? photoAccuracy,
    DateTime? photoCapturedAt,
    String? photoSource,
    bool? isMocked,
  }) {
    requests++;
    submitted = {
      'title': title,
      'description': description,
      'images': imagePaths,
      'cleanImages': cleanImagePaths,
      'private': onPrivateProperty,
      'scale': scaleLevel,
      'obstruction': obstructionLevel,
    };
    return result.future;
  }

  @override
  Future<dio.Response> validateImage(String imagePath) async {
    return dio.Response(
      requestOptions: dio.RequestOptions(path: ''),
      statusCode: 200,
      data: {
        'is_valid': true,
        'confidence': 0.95,
        'predicted_category': 'waste',
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
    messenger.setMockMethodCallHandler(channel, (call) async => ['wifi']);
  });
  testWidgets(
    'report steps keep validation, media, review and values after rejection',
    (tester) async {
      final temporary = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('ecopin-report-ui-'),
      ))!;
      addTearDown(() => temporary.delete(recursive: true));
      final photo = File('${temporary.path}/evidence.png');
      await tester.runAsync(() => photo.writeAsBytes(SyntheticTiles.bytes));
      final api = SyntheticReportApi();
      final address = SyntheticAddress();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(api)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: CreateReportScreen(
              prefillData: const ReportPrefillData(
                location: LatLng(14.575, 121.08),
              ),
              tileProvider: SyntheticTiles(),
              locationSearchService: address,
              imagePicker: SyntheticPicker(photo.path),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rosario, Pasig City, Metro Manila'), findsOneWidget);
      expect(address.requests, 1);
      await tester.ensureVisible(find.text('Next: Details'));
      await tester.ensureVisible(find.text('Next: Details'));
      await tester.tap(find.text('Next: Details'));
      await tester.pumpAndSettle();
      final details = find.text('Next: Attach Media');
      expect(
        tester
            .widget<TextButton>(
              find.ancestor(of: details, matching: find.byType(TextButton)),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byType(TextField).at(0),
        'Waste near the sidewalk',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'A description that should survive failure.',
      );
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Gallery'));
      await tester.tap(find.text('Gallery'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove photo 1'), findsOneWidget);
      await tester.ensureVisible(find.text('Next: Review'));
      await tester.tap(find.text('Next: Review'));
      await tester.pumpAndSettle();
      expect(
        find.text('A description that should survive failure.'),
        findsOneWidget,
      );
      expect(address.requests, 1);
      await tester.ensureVisible(find.text('Submit Report'));
      await tester.tap(find.text('Submit Report'));
      await tester.pump();
      expect(api.requests, 1);
      final options = dio.RequestOptions(path: '/synthetic-reports');
      api.result.completeError(
        dio.DioException(
          requestOptions: options,
          type: dio.DioExceptionType.badResponse,
          response: dio.Response(
            requestOptions: options,
            statusCode: 400,
            data: {'message': 'The report could not be accepted. Try again.'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('The report could not be accepted. Try again.'),
        findsOneWidget,
      );
      expect(
        find.text('A description that should survive failure.'),
        findsOneWidget,
      );
      expect(api.submitted?['title'], 'Waste near the sidewalk');
      expect(api.submitted?['images'], [photo.path]);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'location and details fit 320px at large text in ${dark ? "dark" : "light"}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: CreateReportScreen(
                  prefillData: const ReportPrefillData(
                    location: LatLng(14.575, 121.08),
                  ),
                  tileProvider: SyntheticTiles(),
                  locationSearchService: SyntheticAddress(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Next: Details'));
        await tester.ensureVisible(find.text('Next: Details'));
        await tester.tap(find.text('Next: Details'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'without GPS a location must be explicitly chosen before continuing',
    (tester) async {
      final address = SyntheticAddress();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: CreateReportScreen(
              tileProvider: SyntheticTiles(),
              locationSearchService: address,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final next = find.widgetWithText(TextButton, 'Next: Details');
      expect(tester.widget<TextButton>(next).onPressed, isNull);
      expect(find.textContaining('not your detected location'), findsOneWidget);
      await tester.ensureVisible(find.text('Use this map center'));
      await tester.tap(find.text('Use this map center'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(next).onPressed, isNotNull);
      expect(address.requests, 0);
      await tester.ensureVisible(find.text('Find street address'));
      await tester.tap(find.text('Find street address'));
      await tester.pumpAndSettle();
      expect(address.requests, 1);
      expect(find.text('Rosario, Pasig City, Metro Manila'), findsOneWidget);
    },
  );

  testWidgets(
    'permission failure remains visible; retry keeps details and selected media',
    (tester) async {
      final temporary = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('ecopin-media-ui-'),
      ))!;
      addTearDown(() => temporary.delete(recursive: true));
      final photo = File('${temporary.path}/evidence.png');
      await tester.runAsync(() => photo.writeAsBytes(SyntheticTiles.bytes));
      final picker = SyntheticPicker(photo.path)
        ..failure = PlatformException(code: 'camera_access_denied');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(SyntheticReportApi()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: CreateReportScreen(
              prefillData: const ReportPrefillData(
                location: LatLng(14.575, 121.08),
                title: 'Keep this report',
              ),
              tileProvider: SyntheticTiles(),
              locationSearchService: SyntheticAddress(),
              imagePicker: picker,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next: Details'));
      await tester.tap(find.text('Next: Details'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next: Attach Media'));
      await tester.tap(find.text('Next: Attach Media'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Camera'));
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Media access is unavailable'),
        findsOneWidget,
      );
      expect(find.text('Open app settings'), findsOneWidget);
      picker.failure = null;
      await tester.ensureVisible(find.text('Gallery'));
      await tester.tap(find.text('Gallery'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(find.text('Open app settings'), findsNothing);
      expect(find.byTooltip('Remove photo 1'), findsOneWidget);
      await tester.ensureVisible(find.text('Next: Review'));
      await tester.tap(find.text('Next: Review'));
      await tester.pumpAndSettle();
      expect(find.text('Keep this report'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('media checking locks duplicate picks and forward navigation', (
    tester,
  ) async {
    final picker = SyntheticPicker('unused.png')
      ..pendingSelection = Completer<List<XFile>>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: CreateReportScreen(
            prefillData: const ReportPrefillData(
              location: LatLng(14.575, 121.08),
              title: 'Pending media',
            ),
            tileProvider: SyntheticTiles(),
            locationSearchService: SyntheticAddress(),
            imagePicker: picker,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next: Details'));
    await tester.tap(find.text('Next: Details'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next: Attach Media'));
    await tester.tap(find.text('Next: Attach Media'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gallery'));
    await tester.tap(find.text('Gallery'));
    await tester.pump();
    expect(find.text('Checking selected media…'), findsOneWidget);
    await tester.ensureVisible(find.text('Camera'));
    await tester.tap(find.text('Camera'));
    await tester.pump();
    expect(picker.requests, 1);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Next: Review'))
          .onPressed,
      isNull,
    );
    picker.pendingSelection!.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Checking selected media…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'duration limits use metadata fractions and accepted video opens playback tools',
    (tester) async {
      var duration = const Duration(milliseconds: 10900);
      final picker = SyntheticPicker('unused.png')
        ..videoPath = 'tiny-valid-video.mp4';
      final api = SyntheticReportApi();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(api)],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: CreateReportScreen(
              prefillData: const ReportPrefillData(
                location: LatLng(14.575, 121.08),
                title: 'Video report',
              ),
              tileProvider: SyntheticTiles(),
              locationSearchService: SyntheticAddress(),
              imagePicker: picker,
              videoControllerFactory: (file) =>
                  SyntheticVideoController(file, duration: duration),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next: Details'));
      await tester.tap(find.text('Next: Details'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next: Attach Media'));
      await tester.tap(find.text('Next: Attach Media'));
      await tester.pumpAndSettle();
      api.failVideoPolicy = true;
      await tester.ensureVisible(find.text('Record Video'));
      await tester.tap(find.text('Record Video'));
      await tester.pumpAndSettle();
      expect(picker.requests, 0);
      expect(
        find.text(
          'Video limits could not load. Retry or attach photos instead.',
        ),
        findsOneWidget,
      );
      api.failVideoPolicy = false;
      await tester.ensureVisible(find.text('Retry video limits'));
      await tester.tap(find.text('Retry video limits'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Record Video'));
      await tester.tap(find.text('Record Video'));
      await tester.pumpAndSettle();
      expect(find.textContaining('This video is 10.9 seconds'), findsOneWidget);
      expect(find.text('Preview selected video'), findsNothing);
      duration = const Duration(milliseconds: 4900);
      await tester.ensureVisible(find.text('Record Video'));
      await tester.tap(find.text('Record Video'));
      await tester.pumpAndSettle();
      expect(find.textContaining('This video is 4.9 seconds'), findsOneWidget);
      duration = const Duration(milliseconds: 8026);
      await tester.ensureVisible(find.text('Record Video'));
      await tester.tap(find.text('Record Video'));
      await tester.pumpAndSettle();
      expect(find.text('Duration: 00:08'), findsOneWidget);
      expect(picker.videoSource, ImageSource.camera);
      expect(picker.videoMaximum, const Duration(seconds: 8));
      expect(find.text('Select Video'), findsNothing);
      await tester.ensureVisible(find.text('Preview selected video'));
      await tester.tap(find.text('Preview selected video'));
      await tester.pumpAndSettle();
      expect(find.text('Preview video'), findsOneWidget);
      await tester.tap(find.text('Play video'));
      await tester.pumpAndSettle();
      expect(find.text('Pause video'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove selected video'), findsOneWidget);
      api.videoMaximum = 6;
      await tester.ensureVisible(find.text('Next: Review'));
      await tester.tap(find.text('Next: Review'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Submit Report'));
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();
      expect(api.requests, 0);
      expect(
        find.text(
          'The video limit changed. Record a video between 5 and 6 seconds.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'WT-90: backward and forward navigation preserves location, text fields, and attached media',
    (tester) async {
      final temporary = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('ecopin-nav-ui-'),
      ))!;
      addTearDown(() => temporary.delete(recursive: true));
      final photo = File('${temporary.path}/evidence.png');
      await tester.runAsync(() => photo.writeAsBytes(SyntheticTiles.bytes));
      final api = SyntheticReportApi();
      final address = SyntheticAddress();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(api)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: CreateReportScreen(
              prefillData: const ReportPrefillData(
                location: LatLng(14.575, 121.08),
              ),
              tileProvider: SyntheticTiles(),
              locationSearchService: address,
              imagePicker: SyntheticPicker(photo.path),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      expect(find.text('Rosario, Pasig City, Metro Manila'), findsOneWidget);
      await tester.ensureVisible(find.text('Next: Details'));
      await tester.tap(find.text('Next: Details'));
      await tester.pumpAndSettle();

      // Fill Step 2
      await tester.enterText(
        find.byType(TextField).at(0),
        'Illegal Dumping Site',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'Piles of construction debris left on the corner.',
      );
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3
      await tester.ensureVisible(find.text('Next: Attach Media'));
      await tester.tap(find.text('Next: Attach Media'));
      await tester.pumpAndSettle();

      // Pick photo in Step 3
      await tester.ensureVisible(find.text('Gallery'));
      await tester.tap(find.text('Gallery'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove photo 1'), findsOneWidget);

      // Step 3 -> Step 4 (Review)
      await tester.ensureVisible(find.text('Next: Review'));
      await tester.tap(find.text('Next: Review'));
      await tester.pumpAndSettle();

      expect(find.text('Illegal Dumping Site'), findsOneWidget);
      expect(
        find.text('Piles of construction debris left on the corner.'),
        findsOneWidget,
      );
      expect(find.text('On private property'), findsOneWidget);
      expect(find.text('1 Photo(s), 0 Video(s)'), findsOneWidget);

      // Navigate backwards: Step 4 -> Step 3 using bottom Back button
      final backFromReview = find.widgetWithText(TextButton, 'Back');
      await tester.ensureVisible(backFromReview);
      await tester.tap(backFromReview);
      await tester.pumpAndSettle();

      // Verify on Step 3, photo is preserved
      expect(find.text('Photos · Up to 5'), findsOneWidget);
      expect(find.byTooltip('Remove photo 1'), findsOneWidget);

      // Navigate backwards: Step 3 -> Step 2 using bottom Back button
      final backFromMedia = find.widgetWithText(TextButton, 'Back');
      await tester.ensureVisible(backFromMedia);
      await tester.tap(backFromMedia);
      await tester.pumpAndSettle();

      // Verify on Step 2, title, description, and private switch are preserved
      expect(find.text('Illegal Dumping Site'), findsOneWidget);
      expect(
        find.text('Piles of construction debris left on the corner.'),
        findsOneWidget,
      );
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);

      // Navigate backwards: Step 2 -> Step 1 using AppBar Back arrow
      final appBarBack = find.byTooltip('Previous step');
      expect(appBarBack, findsOneWidget);
      await tester.tap(appBarBack);
      await tester.pumpAndSettle();

      // Verify on Step 1, location pin and address are preserved
      expect(find.text('Rosario, Pasig City, Metro Manila'), findsOneWidget);

      // Navigate forward: Step 1 -> Step 2
      await tester.ensureVisible(find.text('Next: Details'));
      await tester.tap(find.text('Next: Details'));
      await tester.pumpAndSettle();

      // Verify details preserved
      expect(find.text('Illegal Dumping Site'), findsOneWidget);

      // Navigate forward: Step 2 -> Step 3
      await tester.ensureVisible(find.text('Next: Attach Media'));
      await tester.tap(find.text('Next: Attach Media'));
      await tester.pumpAndSettle();

      // Verify photo preserved
      expect(find.byTooltip('Remove photo 1'), findsOneWidget);

      // Navigate forward: Step 3 -> Step 4
      await tester.ensureVisible(find.text('Next: Review'));
      await tester.tap(find.text('Next: Review'));
      await tester.pumpAndSettle();

      // Verify Review shows all inputs intact
      expect(find.text('Illegal Dumping Site'), findsOneWidget);
      expect(find.text('1 Photo(s), 0 Video(s)'), findsOneWidget);
    },
  );

  testWidgets(
    'WT-90: review step Edit buttons jump directly to target step without resetting input',
    (tester) async {
      final temporary = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('ecopin-edit-ui-'),
      ))!;
      addTearDown(() => temporary.delete(recursive: true));
      final photo = File('${temporary.path}/evidence.png');
      await tester.runAsync(() => photo.writeAsBytes(SyntheticTiles.bytes));
      final api = SyntheticReportApi();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(api)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: CreateReportScreen(
              prefillData: const ReportPrefillData(
                location: LatLng(14.575, 121.08),
                title: 'Initial Hazard',
                description: 'Initial notes',
              ),
              tileProvider: SyntheticTiles(),
              locationSearchService: SyntheticAddress(),
              imagePicker: SyntheticPicker(photo.path),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Jump to step 2 (Details) -> step 3 (Media) -> step 4 (Review)
      await tester.ensureVisible(find.text('Next: Details'));
      await tester.tap(find.text('Next: Details'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Next: Attach Media'));
      await tester.tap(find.text('Next: Attach Media'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Gallery'));
      await tester.tap(find.text('Gallery'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Next: Review'));
      await tester.tap(find.text('Next: Review'));
      await tester.pumpAndSettle();

      // On Review: tap "Edit" details button
      final editDetails = find.byKey(const ValueKey('edit-details-button'));
      expect(editDetails, findsOneWidget);
      await tester.ensureVisible(editDetails);
      await tester.tap(editDetails);
      await tester.pumpAndSettle();

      // Verify jumped to Step 2
      expect(find.text('Step 2: Details'), findsOneWidget);
      expect(find.text('Initial Hazard'), findsOneWidget);

      // Edit description
      await tester.enterText(
        find.byType(TextField).at(1),
        'Updated notes after reviewing.',
      );
      await tester.pumpAndSettle();

      // Use Step 4 chip in nav header to jump straight back to review
      final reviewChip = find.text('4. Review');
      expect(reviewChip, findsOneWidget);
      await tester.tap(reviewChip);
      await tester.pumpAndSettle();

      // Verify on Review screen with updated details and preserved photo
      expect(find.text('Step 4: Review'), findsOneWidget);
      expect(find.text('Updated notes after reviewing.'), findsOneWidget);
      expect(find.text('1 Photo(s), 0 Video(s)'), findsOneWidget);
    },
  );

  testWidgets(
    'WT-90: system back gesture via PopScope steps back without losing report draft',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: CreateReportScreen(
              prefillData: const ReportPrefillData(
                location: LatLng(14.575, 121.08),
                title: 'Draft to keep',
                description: 'Important details',
              ),
              tileProvider: SyntheticTiles(),
              locationSearchService: SyntheticAddress(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Advance to Step 2
      await tester.ensureVisible(find.text('Next: Details'));
      await tester.tap(find.text('Next: Details'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2: Details'), findsOneWidget);
      expect(find.text('Draft to keep'), findsOneWidget);

      // Simulate system back navigation via tester.binding.handlePopRoute()
      final popHandled = await tester.binding.handlePopRoute();
      expect(popHandled, isTrue);
      await tester.pumpAndSettle();

      // Screen stepped back to Step 1 instead of exiting
      expect(find.text('Step 1: Location'), findsOneWidget);

      // Navigate forward again and ensure values remain intact
      await tester.ensureVisible(find.text('Next: Details'));
      await tester.tap(find.text('Next: Details'));
      await tester.pumpAndSettle();
      expect(find.text('Draft to keep'), findsOneWidget);
      expect(find.text('Important details'), findsOneWidget);
    },
  );
}
