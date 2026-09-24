import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecopin_app/core/constants/api_constants.dart';
import 'package:logging/logging.dart';

import 'package:ecopin_app/core/database/app_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

final apiClientProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return ApiClient(db);
});
final Logger log = Logger("API Service: ");

class ApiClient {
  static String get baseUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://47.129.254.120';

  final dio.Dio _dio = dio.Dio(
    dio.BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final AppDatabase? _db;

  ApiClient([this._db]) {
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          final connectivityResult = await Connectivity().checkConnectivity();
          if (connectivityResult.contains(ConnectivityResult.none)) {
            return handler.reject(
              dio.DioException(
                requestOptions: options,
                type: dio.DioExceptionType.connectionError,
                error: 'No internet connection',
              ),
            );
          }

          final session = Supabase.instance.client.auth.currentSession;
          final token = session?.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Try to refresh the session
            try {
              await Supabase.instance.client.auth.refreshSession();
              final newSession = Supabase.instance.client.auth.currentSession;
              final newToken = newSession?.accessToken;

              if (newToken != null) {
                // Retry the original request with new token
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              }
            } catch (refreshError) {
              // Refresh failed, let the error propagate
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Auth methods

  Future<dio.Response> register(
    String email,
    String password,
    String confirmPassword,
  ) async {
    log.info('Registering user: $email');
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );
      log.info(
        'Register response status: ${response.statusCode}, data: ${response.data}',
      );
      return response;
    } on dio.DioException catch (e) {
      log.severe(
        'Register DioException: ${e.message}, status: ${e.response?.statusCode}, response: ${e.response?.data}',
      );
      rethrow;
    } catch (e) {
      log.severe('Register Exception: $e');
      rethrow;
    }
  }

  Future<dio.Response> resendVerification(String email) async {
    return _dio.post(ApiConstants.resendVerification, data: {'email': email});
  }

  Future<dio.Response> getPasswordRequirements() async {
    return _dio.get(ApiConstants.passwordRequirements);
  }

  Future<dio.Response> login(String email, String password) async {
    return _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
  }

  Future<dio.Response> getMe() async {
    return _dio.get(ApiConstants.me);
  }

  Future<dio.Response> logout() async {
    return _dio.post(ApiConstants.logout);
  }

  // Report methods

  Future<dio.Response> createReport({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    List<String>? imagePaths,
    String? videoPath,
    bool onPrivateProperty = false,
    String scaleLevel = 'medium',
    String obstructionLevel = 'none',
  }) async {
    // Require at least one media type
    if ((imagePaths == null || imagePaths.isEmpty) && videoPath == null) {
      throw ArgumentError('Must provide either an image or a video.');
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (_db == null) throw Exception("Database not initialized for offline mode");
      
      final idempotencyKey = const Uuid().v4();
      final imageList = imagePaths?.join(',') ?? '';
      
      await _db.into(_db.offlineReports).insert(
        OfflineReportsCompanion.insert(
          idempotencyKey: idempotencyKey,
          title: title,
          description: description,
          latitude: latitude,
          longitude: longitude,
          onPrivateProperty: drift.Value(onPrivateProperty),
          scaleLevel: drift.Value(scaleLevel),
          obstructionLevel: drift.Value(obstructionLevel),
          imagePaths: drift.Value(imageList),
          videoPath: drift.Value(videoPath),
        ),
      );
      
      // If we have media, insert into the new OfflineMedia table
      if (imageList.isNotEmpty || videoPath != null) {
        await _db.into(_db.offlineMedia).insert(
          OfflineMediaCompanion.insert(
            idempotencyKey: idempotencyKey,
            imagePaths: drift.Value(imageList.isEmpty ? null : imageList),
            videoPath: drift.Value(videoPath),
          )
        );
      }
      
      return dio.Response(
        requestOptions: dio.RequestOptions(),
        statusCode: 201,
        data: {'message': 'You are offline. Your report has been saved locally and will be synced when you reconnect.', 'report': {}},
      );
    }

    final formData = dio.FormData();
    formData.fields.add(MapEntry('title', title));
    formData.fields.add(MapEntry('description', description));
    formData.fields.add(MapEntry('latitude', latitude.toString()));
    formData.fields.add(MapEntry('longitude', longitude.toString()));
    formData.fields.add(
      MapEntry('on_private_property', onPrivateProperty.toString()),
    );
    formData.fields.add(MapEntry('scale_level', scaleLevel));
    formData.fields.add(MapEntry('obstruction_level', obstructionLevel));

    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (final imagePath in imagePaths) {
        formData.files.add(
          MapEntry('image', await dio.MultipartFile.fromFile(imagePath)),
        );
      }
    }

    if (videoPath != null) {
      formData.files.add(
        MapEntry('video', await dio.MultipartFile.fromFile(videoPath)),
      );
    }

    return _dio.post(ApiConstants.createReport, data: formData);
  }

  Future<dio.Response> syncReportMedia(
    String idempotencyKey,
    List<String>? imagePaths,
    String? videoPath,
  ) async {
    final formData = dio.FormData();
    
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (final path in imagePaths) {
        if (path.isNotEmpty) {
          formData.files.add(
            MapEntry('image', await dio.MultipartFile.fromFile(path)),
          );
        }
      }
    }
    
    if (videoPath != null && videoPath.isNotEmpty) {
      formData.files.add(
        MapEntry('video', await dio.MultipartFile.fromFile(videoPath)),
      );
    }

    return _dio.post(
      '/api/reports/sync/media/$idempotencyKey', 
      data: formData
    );
  }

  Future<dio.Response> getMyReports() async {
    return _dio.get(ApiConstants.getMyReports);
  }

  Future<dio.Response> getPublicReports() async {
    return _dio.get(ApiConstants.getPublicReports);
  }

  Future<dio.Response> getValidatedReports() async {
    return _dio.get('/api/reports/validated');
  }

  Future<dio.Response> getReportsByClusterId(String clusterId) async {
    return _dio.get('/api/reports/cluster/$clusterId');
  }

  Future<dio.Response> getReportById(String id) async {
    return _dio.get(ApiConstants.getReportById(id));
  }

  Future<dio.Response> getReportsByIds(List<String> reportIds) async {
    // Fetch reports directly from Supabase for now
    final response = await Supabase.instance.client
        .from('reports_view')
        .select()
        .inFilter('id', reportIds);
    return dio.Response(
      data: response,
      requestOptions: dio.RequestOptions(path: ''),
    );
  }

  // Evidences Methods

  Future<dio.Response> uploadEvidence({
    required String reportId,
    required File imageFile,
    required double latitude,
    required double longitude,
  }) async {
    final formData = dio.FormData.fromMap({
      'image': await dio.MultipartFile.fromFile(imageFile.path),
      'latitude': latitude,
      'longitude': longitude,
    });

    log.finer("EVIDENCE FORM DATA: ", formData);

    return _dio.post(ApiConstants.evidenceByReportId(reportId), data: formData);
  }

  Future<dio.Response> getReportEvidence(String reportId) async {
    return _dio.get(ApiConstants.evidenceByReportId(reportId));
  }

  // Profile methods

  Future<dio.Response> getProfile() async {
    return _dio.get(ApiConstants.profile);
  }

  Future<dio.Response> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (email != null) data['email'] = email;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    return _dio.put(ApiConstants.profile, data: data);
  }

  Future<dio.Response> uploadAvatar({required String filePath}) async {
    final formData = dio.FormData.fromMap({
      'avatar': await dio.MultipartFile.fromFile(filePath),
    });

    return _dio.post(ApiConstants.avatar, data: formData);
  }

  Future<Map<String, dynamic>> updateDataConsent(bool dataConsent) async {
    final response = await _dio.patch(
      ApiConstants.updateDataConsent,
      data: {'data_consent': dataConsent},
    );
    log.info("Data Consent Response: ", response.data);
    return response.data;
  }

  Future<dio.Response> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return _dio.put(
      ApiConstants.changePassword,
      data: {'current_password': oldPassword, 'new_password': newPassword},
    );
  }

  // Cleanup Task methods

  Future<dio.Response> getCleanupTasksByCluster(String clusterId) async {
    return _dio.get(ApiConstants.getCleanupTasksByCluster(clusterId));
  }

  Future<dio.Response> createCustomCleanupTask({
    required List<String> reportIds,
    required String title,
    String? description,
  }) async {
    return _dio.post(
      ApiConstants.createCustomCleanupTask,
      data: {
        'report_ids': reportIds,
        'title': title,
        'description': description,
      },
    );
  }

  Future<dio.Response> uploadCleanupPhoto({
    required String taskId,
    required String photoType,
    required File image,
  }) async {
    final formData = dio.FormData.fromMap({
      'photo_type': photoType,
      'image': await dio.MultipartFile.fromFile(image.path),
    });
    return _dio.post(
      ApiConstants.cleanupTaskUploadPhoto(taskId),
      data: formData,
    );
  }

  Future<dio.Response> deleteCleanupPhoto({
    required String taskId,
    required String photoType,
  }) async {
    return _dio.delete(
      ApiConstants.cleanupTaskUploadPhoto(taskId),
      data: {'photo_type': photoType},
    );
  }

  Future<dio.Response> markCleanupTaskComplete(String taskId) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (_db == null) throw Exception("Database not initialized for offline mode");
      
      await _db.into(_db.offlineTaskUpdates).insert(
        OfflineTaskUpdatesCompanion.insert(
          taskId: int.parse(taskId),
          payloadJson: '{"status":"completed"}',
          clientKnownUpdatedAt: DateTime.now(),
        ),
      );
      
      return dio.Response(
        requestOptions: dio.RequestOptions(),
        statusCode: 200,
        data: {'message': 'You are offline. Task update saved locally.', 'task': {}},
      );
    }

    return _dio.patch(ApiConstants.markCleanupTaskComplete(taskId));
  }

  // New report lifecycle methods
  Future<dio.Response> lguResolveReport(String reportId) async {
    return _dio.patch(ApiConstants.lguResolveReport(reportId));
  }

  Future<dio.Response> citizenCloseReport(
    String reportId,
    int satisfactionRating,
  ) async {
    return _dio.patch(
      ApiConstants.citizenCloseReport(reportId),
      data: {'satisfaction_rating': satisfactionRating},
    );
  }

  // LGU methods

  Future<dio.Response> getSystemStats() async {
    return _dio.get(ApiConstants.systemStats);
  }

  Future<dio.Response> getClusters() async {
    return _dio.get(ApiConstants.clusters);
  }

  Future<dio.Response> getClusterById(String clusterId) async {
    return _dio.get(ApiConstants.clusterById(clusterId));
  }

  Future<dio.Response> getCleanupsCompleted() async {
    return _dio.get(ApiConstants.statsCompletedCleanups);
  }

  // Sync methods

  Future<dio.Response> batchSyncReports(List<Map<String, dynamic>> payload) async {
    return _dio.post('/api/reports/sync/batch', data: {'reports': payload});
  }

  Future<dio.Response> batchSyncTaskUpdates(List<Map<String, dynamic>> payload) async {
    return _dio.post('/api/cleanup-tasks/sync/batch', data: {'updates': payload});
  }

  Future<dio.Response> getCleanupTasks() async {
    return _dio.get(ApiConstants.cleanupTasks);
  }

  Future<dio.Response> completeCleanupTask(String taskId, String outcome, String notes) async {
    return _dio.post(
      '${ApiConstants.cleanupTasks}/$taskId/complete',
      data: {
        'outcome': outcome,
        'notes': notes,
      },
    );
  }

  Future<dio.Response> getCleanupTaskById(String taskId) async {
    return _dio.get(ApiConstants.cleanupTaskById(taskId));
  }

  Future<dio.Response> getResponseLogs({Map<String, dynamic>? params}) async {
    return _dio.get(ApiConstants.responseLogs, queryParameters: params);
  }

  Future<dio.Response> updateReportStatus(
    String reportId,
    String status,
  ) async {
    return _dio.patch(
      ApiConstants.updateReportStatus(reportId),
      data: {'status': status},
    );
  }

  Future<dio.Response> updateReportValidation(
    String reportId,
    String validationStatus,
  ) async {
    return _dio.patch(
      ApiConstants.updateReportValidation(reportId),
      data: {'validation_status': validationStatus},
    );
  }

  Future<dio.Response> updateReportLifecycleStage(
    String reportId,
    String stage,
  ) async {
    return _dio.patch(
      ApiConstants.updateReportLifecycleStage(reportId),
      data: {'stage': stage},
    );
  }

  Future<dio.Response> acknowledgeComplaint(String reportId) async {
    return _dio.post(ApiConstants.acknowledgeComplaint(reportId));
  }

  Future<dio.Response> logAgencyResponse(String reportId, String action) async {
    return _dio.post(
      '/api/reports/$reportId/agency-response',
      data: {'action': action},
    );
  }

  Future<dio.Response> getAgencyResponses(String reportId) async {
    return _dio.get(ApiConstants.agencyResponses(reportId));
  }

  Future<dio.Response> getSatisfactionAnalytics() async {
    return _dio.get(ApiConstants.satisfactionAnalytics);
  }

  Future<dio.Response> uploadReportPhoto(
    String reportId,
    File photo,
    String photoType,
  ) async {
    final formData = dio.FormData.fromMap({
      'photo_type': photoType,
      'image': await dio.MultipartFile.fromFile(photo.path),
    });
    return _dio.post(ApiConstants.uploadReportPhoto(reportId), data: formData);
  }

  Future<dio.Response> deleteReportPhoto(
    String reportId,
    String photoType,
  ) async {
    return _dio.delete(
      ApiConstants.uploadReportPhoto(reportId),
      data: {'photo_type': photoType},
    );
  }

  Future<dio.Response> createReportFromRejected(String reportId) async {
    return _dio.post('/api/reports/$reportId/create-new');
  }
}
