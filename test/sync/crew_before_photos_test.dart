import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_photo_sync_manager.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

class PhotoApi extends Fake implements ApiClient {
  PhotoApi(this.client);
  final Dio client;
  @override
  Dio get dioClient => client;
}

void main() {
  test(
    'deleting the last unsent photo removes its stale upload queue item',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final local = FcLocalRepository(db);
      final photos = FcLocalPhotoRepository(db);
      await db.insertFcLocalPhoto(
        FcLocalPhotosCompanion.insert(
          localPhotoId: 'photo',
          entityId: 'r',
          entityType: 'report',
          photoType: 'before',
          localPath: 'unused',
        ),
      );
      await local.enqueueOutboxItem(
        operationType: FcOutboxOperationType.uploadBeforePhoto,
        entityId: 'r',
        entityType: 'report',
        payload: {'local_photo_id': 'photo'},
      );
      await photos.deletePhoto('photo');
      expect(await local.getPendingOutboxItems(), isEmpty);
    },
  );
  test(
    'each Before photo syncs with its own ID and URL, survives cache roundtrip',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final local = FcLocalRepository(db);
      final photos = FcLocalPhotoRepository(db);
      final temp = await Directory.systemTemp.createTemp(
        'ecopin_before_photos_',
      );
      addTearDown(() async {
        await for (final file in temp.list()) {
          await file.delete();
        }
        await temp.delete();
      });
      await local.saveReports([
        ReportModel.fromJson({'id': 'report', 'fc_version': 0}),
      ]);
      final completion = await local.enqueueOutboxItem(
        operationType: FcOutboxOperationType.updateReportStatus,
        entityId: 'report',
        entityType: 'report',
        payload: {'status': 'resolved'},
        baseVersion: '0',
      );
      final staleCompletion = await local.enqueueOutboxItem(
        operationType: FcOutboxOperationType.updateReportStatus,
        entityId: 'other-report',
        entityType: 'report',
        payload: {'status': 'resolved'},
        baseVersion: '0',
      );
      for (var i = 0; i < 2; i++) {
        final file = await File(
          '${temp.path}/p$i.jpg',
        ).writeAsBytes([i, 1, 2, 3]);
        await db.insertFcLocalPhoto(
          FcLocalPhotosCompanion.insert(
            localPhotoId: 'p$i',
            entityId: 'report',
            entityType: 'report',
            photoType: 'before',
            localPath: file.path,
          ),
        );
      }
      final ids = <String>[];
      final versions = <String>[];
      final remote = <Map<String, dynamic>>[];
      final events = <String>[];
      final client = Dio();
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            events.add(options.method);
            if (options.method == 'DELETE') {
              expect((options.data as Map)['photo_id'], 'p0');
              remote.removeWhere((p) => p['id'] == 'p0');
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'report': {
                      'id': 'report',
                      'fc_version': 3,
                      'before_photos': List.of(remote),
                    },
                  },
                ),
              );
              return;
            }
            final fields = Map.fromEntries((options.data as FormData).fields);
            final id = fields['photo_id']!;
            ids.add(id);
            versions.add(fields['base_version']!);
            remote.add({'id': id, 'url': 'https://example.test/$id.jpg'});
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'photo_id': id,
                  'url': 'https://example.test/$id.jpg',
                  'report': {
                    'id': 'report',
                    'fc_version': ids.length,
                    'before_photos': List.of(remote),
                  },
                },
              ),
            );
          },
        ),
      );
      final result = await FcPhotoSyncManager(
        PhotoApi(client),
        photos,
        local,
      ).sync();
      expect(result.uploadSucceeded, 2);
      expect(ids, ['p0', 'p1']);
      expect(versions, ['0', '1']);
      final rows = await photos.getPhotosForEntity('report', 'report');
      expect(rows.map((p) => p.remoteId), ['p0', 'p1']);
      expect(rows.map((p) => p.remoteUrl), [
        'https://example.test/p0.jpg',
        'https://example.test/p1.jpg',
      ]);
      expect(
        (await local.getCachedReportById('report'))!.beforePhotos.length,
        2,
      );
      final queued = {
        for (final row in await local.getPendingOutboxItems())
          row.operationId: row,
      };
      expect(queued[completion]!.baseVersion, '2');
      expect(queued[staleCompletion]!.baseVersion, '0');
      await local.advanceReportCompletionVersion('other-report', 1, 2);
      expect(
        (await local.getPendingOutboxItems())
            .firstWhere((row) => row.operationId == staleCompletion)
            .baseVersion,
        '0',
        reason: 'A genuinely stale completion must keep its conflict',
      );
      await photos.deletePhoto('p0');
      final replacement = await File(
        '${temp.path}/p2.jpg',
      ).writeAsBytes([3, 4, 5]);
      await db.insertFcLocalPhoto(
        FcLocalPhotosCompanion.insert(
          localPhotoId: 'p2',
          entityId: 'report',
          entityType: 'report',
          photoType: 'before',
          localPath: replacement.path,
        ),
      );
      events.clear();
      final replaced = await FcPhotoSyncManager(
        PhotoApi(client),
        photos,
        local,
      ).sync();
      expect(replaced.deleteSucceeded, 1);
      expect(replaced.uploadSucceeded, 1);
      expect(events, ['DELETE', 'POST']);
      expect(
        (await photos.getPhotosForEntity(
          'report',
          'report',
        )).map((p) => p.remoteId),
        ['p1', 'p2'],
      );
    },
  );

  for (final slot in ['before', 'after']) {
    test(
      'local $slot photo limit rejects sixth without overwriting first five',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final photos = FcLocalPhotoRepository(db);
        final source = await File(
          '${Directory.systemTemp.path}/ecopin-sixth-$slot-${DateTime.now().microsecondsSinceEpoch}.jpg',
        ).writeAsBytes([1, 2, 3]);
        addTearDown(source.delete);
        for (var i = 0; i < 5; i++) {
          await db.insertFcLocalPhoto(
            FcLocalPhotosCompanion.insert(
              localPhotoId: 'p$i',
              entityId: 'report',
              entityType: 'report',
              photoType: slot,
              localPath: 'unused-$i',
            ),
          );
        }
        await expectLater(
          photos.addPhoto(
            entityId: 'report',
            entityType: 'report',
            photoType: slot,
            sourceFile: source,
          ),
          throwsA(isA<FcPhotoSlotOccupiedException>()),
        );
        expect((await photos.getPhotosForEntity('report', 'report')).length, 5);
        expect(
          (await photos.getActivePhoto(
            'report',
            'report',
            slot,
          ))!.localPhotoId,
          'p0',
        );
      },
    );
  }

  test(
    'five After photos sync with their own IDs and URLs and survive cache roundtrip',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final local = FcLocalRepository(db);
      final photos = FcLocalPhotoRepository(db);
      final temp = await Directory.systemTemp.createTemp(
        'ecopin_after_photos_',
      );
      addTearDown(() async {
        await for (final file in temp.list()) {
          await file.delete();
        }
        await temp.delete();
      });
      await local.saveReports([
        ReportModel.fromJson({'id': 'report', 'fc_version': 0}),
      ]);
      for (var i = 0; i < 5; i++) {
        final file = await File(
          '${temp.path}/after$i.jpg',
        ).writeAsBytes([i, 9, 8, 7]);
        await db.insertFcLocalPhoto(
          FcLocalPhotosCompanion.insert(
            localPhotoId: 'after-$i',
            entityId: 'report',
            entityType: 'report',
            photoType: 'after',
            localPath: file.path,
          ),
        );
      }
      final remote = <Map<String, dynamic>>[];
      final client = Dio();
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final fields = Map.fromEntries((options.data as FormData).fields);
            final id = fields['photo_id']!;
            remote.add({'id': id, 'url': 'https://example.test/$id.jpg'});
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'photo_id': id,
                  'url': 'https://example.test/$id.jpg',
                  'report': {
                    'id': 'report',
                    'fc_version': remote.length,
                    'after_photos': List.of(remote),
                    'after_photo_url': remote.first['url'],
                  },
                },
              ),
            );
          },
        ),
      );
      final result = await FcPhotoSyncManager(
        PhotoApi(client),
        photos,
        local,
      ).sync();
      expect(result.uploadSucceeded, 5);
      final cached = await local.getCachedReportById('report');
      expect(cached!.afterPhotos.length, 5);
      expect(cached.afterPhotoUrl, 'https://example.test/after-0.jpg');
    },
  );
}
