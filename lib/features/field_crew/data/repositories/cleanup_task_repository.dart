import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:ecopin_app/core/constants/api_constants.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/services/cache_service.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CleanupTaskRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;
  final FcLocalRepository _local;
  final FcLocalPhotoRepository _localPhoto;
  final Logger log = Logger('CleanupTaskRepository');

  CleanupTaskRepository(
    this._apiClient,
    this._cacheService,
    this._local,
    this._localPhoto,
  );

  bool _isNetworkError(Object e) {
    if (e is dio.DioException) {
      return e.type == dio.DioExceptionType.connectionTimeout ||
          e.type == dio.DioExceptionType.sendTimeout ||
          e.type == dio.DioExceptionType.receiveTimeout ||
          e.type == dio.DioExceptionType.connectionError ||
          e.type == dio.DioExceptionType.unknown;
    }
    return e is SocketException;
  }

  // ── Fetch ────────────────────────────────────────────────────────────────

  Future<List<CleanupTask>> fetchAllTasks() async {
    try {
      final response =
          await _apiClient.dioClient.get(ApiConstants.cleanupTasks);
      final List<dynamic> data = response.data;
      final tasks = data.map((json) => CleanupTask.fromJson(json)).toList();
      await _cacheService.cacheTasks(tasks);
      await _local.saveTasks(tasks);
      await _local.recordSyncAt('fc_tasks');
      return tasks;
    } catch (e) {
      log.severe('Failed to fetch all tasks, loading from cache', e);
      final cached = await _local.getCachedTasks();
      if (cached.isNotEmpty) return cached;
      final legacy = await _cacheService.getCachedTasks();
      if (legacy.isNotEmpty) return legacy;
      rethrow;
    }
  }

  Future<List<CleanupTask>> fetchMyTasks() async {
    log.info('fetchMyTasks() called. Attempting network fetch...');
    try {
      final response = await _apiClient.dioClient
          .get('${ApiConstants.cleanupTasks}?assigned_to_me=true');
      final List<dynamic> data = response.data;
      final tasks = data.map((json) => CleanupTask.fromJson(json)).toList();
      await _cacheService.cacheTasks(tasks);
      await _local.saveTasks(tasks);
      log.info('Successfully fetched ${tasks.length} tasks from API (Online Mode). Cached locally.');
      return tasks;
    } catch (e) {
      log.severe('Failed to fetch my tasks, loading from cache', e);
      final cached = await _local.getCachedTasks();
      if (cached.isNotEmpty) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId != null) {
          final userTasks = cached.where((task) => task.assignedCrewIds.contains(currentUserId)).toList();
          log.info('Loaded ${userTasks.length} tasks for current user from Drift Local DB (Offline Mode).');
          return userTasks;
        }
        log.info('Loaded ${cached.length} tasks from Drift Local DB (Offline Mode - No User ID).');
        return cached;
      }
      final legacy = await _cacheService.getCachedTasks();
      if (legacy.isNotEmpty) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId != null) {
          return legacy.where((task) => task.assignedCrewIds.contains(currentUserId)).toList();
        }
        return legacy;
      }
      rethrow;
    }
  }

  Future<CleanupTask> fetchTaskById(String id) async {
    // Prefer local cache so locally-modified state is immediately visible.
    final cached = await _local.getCachedTaskById(id);
    if (cached != null) {
      _refreshTaskFromNetwork(id);
      return cached;
    }
    try {
      final response =
          await _apiClient.dioClient.get(ApiConstants.cleanupTaskById(id));
      final task = CleanupTask.fromJson(response.data);
      await _cacheService.cacheTasks([task]);
      await _local.saveTasks([task]);
      return task;
    } catch (e) {
      log.severe('Failed to fetch task $id, loading from cache', e);
      final legacy = await _cacheService.getCachedTaskById(id);
      if (legacy != null) return legacy;
      rethrow;
    }
  }

  Future<void> _refreshTaskFromNetwork(String id) async {
    try {
      final response =
          await _apiClient.dioClient.get(ApiConstants.cleanupTaskById(id));
      final task = CleanupTask.fromJson(response.data);
      // Only refresh if not locally modified.
      final dbRow = await _local.getCachedTaskDbRow(id);
      if (dbRow == null || dbRow.localSyncState == 0) {
        await _cacheService.cacheTasks([task]);
        await _local.saveTasks([task]);
      }
    } catch (_) {
      // Silent background refresh.
    }
  }

  // ── Local-first mutations ────────────────────────────────────────────────

  /// Marks a cleanup task as complete.
  ///
  /// The local state is updated immediately so the UI reflects the change
  /// even when offline. The backend call is attempted in the background.
  Future<void> markTaskComplete(String id) async {
    // Step 1 — local
    await _local.applyLocalTaskPatch(id, {'status': 'completed'});
    // Step 2 — queue (idempotent)
    await _local.enqueueOutboxItem(
      operationType: FcOutboxOperationType.markTaskComplete,
      entityId: id,
      entityType: 'task',
      payload: {'status': 'completed'},
    );
    // Step 3 — background push
    _tryPushMarkTaskComplete(id);
  }

  Future<void> _tryPushMarkTaskComplete(String id) async {
    try {
      await _apiClient.dioClient.post(ApiConstants.markCleanupTaskComplete(id));
      await _local.markFcTaskSynced(id);
      final item = await _local.findPendingOutboxItem(
          FcOutboxOperationType.markTaskComplete, id);
      if (item != null) await _local.deleteOutboxItem(item.operationId);
    } catch (e) {
      if (!_isNetworkError(e)) {
        log.warning('markTaskComplete backend error (non-network): $e');
      }
      // Outbox entry persists for Phase 3 retry.
    }
  }

  Future<void> uploadTaskPhoto(String id, File file, String photoType) async {
    final opType = photoType == 'before'
        ? FcOutboxOperationType.uploadBeforePhoto
        : FcOutboxOperationType.uploadAfterPhoto;

    // Step 1 — Copy file to permanent storage, dedup/slot check, insert DB row.
    final localPhotoId = await _localPhoto.addPhoto(
      entityId: id,
      entityType: 'task',
      photoType: photoType,
      sourceFile: file,
    );

    // Step 2 — Patch cached task JSON with the local path for immediate UI.
    final localPath = (await _localPhoto.getActivePhoto(
      id,
      'task',
      photoType,
    ))
        ?.localPath ?? file.path;

    await _local.applyLocalTaskPatch(id, {
      '${photoType}_photo_url': localPath,
    });

    // Step 3 — Queue outbox intent (idempotent).
    await _local.enqueueOutboxItem(
      operationType: opType,
      entityId: id,
      entityType: 'task',
      payload: {
        'photo_type': photoType,
        'local_photo_id': localPhotoId,
        'file_path': localPath,
      },
    );

    // Step 4 — Background push.
    _tryPushUploadTaskPhoto(id, file, photoType, opType, localPhotoId);
  }

  Future<void> _tryPushUploadTaskPhoto(
    String id,
    File file,
    String photoType,
    String opType,
    String localPhotoId,
  ) async {
    await _localPhoto.markInFlight(localPhotoId);
    try {
      final fileName = file.path.split('/').last;
      final formData = dio.FormData.fromMap({
        'photo_type': photoType,
        'file': await dio.MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await _apiClient.dioClient.post(
        ApiConstants.cleanupTaskUploadPhoto(id),
        data: formData,
      );

      final remoteId = _extractString(response.data, 'id');
      final remoteUrl = _extractString(response.data, 'url') ??
          _extractString(response.data, '${photoType}_photo_url');

      await _localPhoto.markSynced(
        localPhotoId,
        remoteId: remoteId,
        remoteUrl: remoteUrl,
      );

      if (remoteUrl != null) {
        await _local.applyLocalTaskPatch(id, {
          '${photoType}_photo_url': remoteUrl,
        });
      }

      await _local.markFcTaskSynced(id);
      final item = await _local.findPendingOutboxItem(opType, id);
      if (item != null) await _local.deleteOutboxItem(item.operationId);
    } catch (e) {
      await _localPhoto.markFailed(localPhotoId, e.toString());
      if (!_isNetworkError(e)) {
        log.warning('uploadTaskPhoto backend error (non-network): $e');
      }
    }
  }

  /// Deletes a before/after photo for a task.
  Future<void> deleteTaskPhoto(String id, String photoType) async {
    final photoRow = await _localPhoto.getActivePhoto(id, 'task', photoType);

    if (photoRow != null) {
      await _localPhoto.deletePhoto(photoRow.localPhotoId);
    }

    await _local.applyLocalTaskPatch(id, {
      '${photoType}_photo_url': null,
    });

    await _local.enqueueOutboxItem(
      operationType: FcOutboxOperationType.deletePhoto,
      entityId: id,
      entityType: 'task',
      payload: {
        'photo_type': photoType,
        if (photoRow != null) 'local_photo_id': photoRow.localPhotoId,
        if (photoRow?.remoteId != null) 'remote_id': photoRow!.remoteId,
      },
    );

    if (photoRow?.syncStatus == FcLocalPhotoSyncStatus.synced) {
      _tryPushDeleteTaskPhoto(id, photoType, photoRow!.localPhotoId);
    } else {
      final item = await _local.findPendingOutboxItem(
          FcOutboxOperationType.deletePhoto, id);
      if (item != null) await _local.deleteOutboxItem(item.operationId);
    }
  }

  Future<void> _tryPushDeleteTaskPhoto(
    String id,
    String photoType,
    String localPhotoId,
  ) async {
    try {
      await _apiClient.dioClient.delete(
        ApiConstants.cleanupTaskUploadPhoto(id),
        data: {'photo_type': photoType},
      );
      await _localPhoto.purgePhoto(localPhotoId);
      await _local.markFcTaskSynced(id);
      final item = await _local.findPendingOutboxItem(
          FcOutboxOperationType.deletePhoto, id);
      if (item != null) await _local.deleteOutboxItem(item.operationId);
    } catch (e) {
      if (!_isNetworkError(e)) {
        log.warning('deleteTaskPhoto backend error (non-network): $e');
      }
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────

  String? _extractString(dynamic data, String key) {
    if (data is Map<String, dynamic>) {
      final v = data[key];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }
}
