import 'package:drift/native.dart';
import 'package:dio/dio.dart' as dio;
import 'dart:io';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'online submission sends review intent with both evidence and original photo',
    () async {
      dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
      messenger.setMockMethodCallHandler(channel, (call) async => ['wifi']);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final directory = await Directory.systemTemp.createTemp(
        'ecopin-review-transport-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final photo = await File(
        '${directory.path}/waste.jpg',
      ).writeAsBytes([1, 2, 3]);
      final api = ApiClient();
      dio.FormData? sent;
      api.dioClient.interceptors.add(
        dio.InterceptorsWrapper(
          onRequest: (options, handler) {
            sent = options.data as dio.FormData;
            handler.resolve(
              dio.Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'report': {'id': 'report'},
                },
              ),
            );
          },
        ),
      );
      await api.createReport(
        title: 'Waste',
        description: '',
        latitude: 14.5,
        longitude: 121,
        imagePaths: [photo.path],
        cleanImagePaths: [photo.path],
        requestManualReview: true,
        manualReviewReason: 'Waste bags obstruct the sidewalk.',
      );
      expect(Map.fromEntries(sent!.fields)['request_manual_review'], 'true');
      expect(
        Map.fromEntries(sent!.fields)['manual_review_reason'],
        'Waste bags obstruct the sidewalk.',
      );
      expect(sent!.files.map((file) => file.key), ['image', 'clean_image']);
    },
  );
  test(
    'offline manual review stays on screen instead of losing the review request in the queue',
    () async {
      dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
      messenger.setMockMethodCallHandler(channel, (call) async => ['none']);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await expectLater(
        ApiClient(db).createReport(
          title: 'Waste',
          description: '',
          latitude: 14.575,
          longitude: 121.08,
          imagePaths: ['photo.png'],
          requestManualReview: true,
        ),
        throwsA(
          isA<dio.DioException>().having(
            (e) => e.response?.data['message'],
            'message',
            contains('Your report and photos are still here'),
          ),
        ),
      );
      expect(await db.select(db.offlineReports).get(), isEmpty);
      expect(await db.select(db.offlineMedia).get(), isEmpty);
    },
  );
  test(
    'offline receipt identifies actual local persistence without server acknowledgement',
    () async {
      dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
      messenger.setMockMethodCallHandler(channel, (call) async => ['none']);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final result = await ApiClient(db).createReport(
        title: 'Waste beside a street',
        description: 'A local concern.',
        latitude: 14.575,
        longitude: 121.08,
        imagePaths: ['synthetic-evidence.png'],
      );
      expect(result.data['saved_locally'], isTrue);
      expect(result.data['report'], isEmpty);
      final reports = await db.select(db.offlineReports).get();
      expect(reports, hasLength(1));
      expect(reports.single.title, 'Waste beside a street');
      expect(await db.select(db.offlineMedia).get(), hasLength(1));
    },
  );
}
