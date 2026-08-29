import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecopin_app/core/constants/api_constants.dart';
import 'package:logging/logging.dart';

final apiClientProvider = Provider((ref) => ApiClient());
final Logger log = Logger("API Service: ");

class ApiClient {
  static String get baseUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002';

  final dio.Dio _dio = dio.Dio(
    dio.BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  ApiClient() {
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
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
    return _dio.post(
      ApiConstants.register,
      data: {
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
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
  }) async {
    // Require at least one media type
    if ((imagePaths == null || imagePaths.isEmpty) && videoPath == null) {
      throw ArgumentError('Must provide either an image or a video.');
    }

    final formData = dio.FormData();
    formData.fields.add(MapEntry('title', title));
    formData.fields.add(MapEntry('description', description));
    formData.fields.add(MapEntry('latitude', latitude.toString()));
    formData.fields.add(MapEntry('longitude', longitude.toString()));
    formData.fields.add(MapEntry('on_private_property', onPrivateProperty.toString()));

    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (final imagePath in imagePaths) {
        formData.files.add(MapEntry(
          'image',
          await dio.MultipartFile.fromFile(imagePath),
        ));
      }
    }

    if (videoPath != null) {
      formData.files.add(MapEntry(
        'video',
        await dio.MultipartFile.fromFile(videoPath),
      ));
    }

    return _dio.post(ApiConstants.createReport, data: formData);
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

  Future<dio.Response> getCleanupTasks() async {
    return _dio.get(ApiConstants.cleanupTasks);
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
