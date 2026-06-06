import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final apiClientProvider = Provider((ref) => ApiClient());

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
            // Token refresh is handled by Supabase SDK
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
      '/api/auth/register',
      data: {
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<dio.Response> login(String email, String password) async {
    return _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
  }

  Future<dio.Response> getMe() async {
    return _dio.get('/api/auth/me');
  }

  Future<dio.Response> logout() async {
    return _dio.post('/api/auth/logout');
  }

  // Report methods
  Future<dio.Response> createReport({
    required String title,
    required String description,
    required String issueType,
    required double latitude,
    required double longitude,
    String? imagePath,
  }) async {
    final formData = dio.FormData.fromMap({
      'title': title,
      'description': description,
      'issue_type': issueType,
      'latitude': latitude,
      'longitude': longitude,
      if (imagePath != null)
        'image': await dio.MultipartFile.fromFile(imagePath),
    });

    return _dio.post('/api/reports', data: formData);
  }

  Future<dio.Response> getMyReports() async {
    return _dio.get('/api/reports/my');
  }

  Future<dio.Response> getPublicReports() async {
    return _dio.get('/api/reports/public');
  }

  Future<dio.Response> getReportById(String id) async {
    return _dio.get('/api/reports/$id');
  }

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

    return _dio.post('/api/reports/$reportId/evidence', data: formData);
  }

  Future<dio.Response> getReportEvidence(String reportId) async {
    return _dio.get('/api/reports/$reportId/evidence');
  }
}
