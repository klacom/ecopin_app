import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final apiClientProvider = Provider((ref) => ApiClient());

class ApiClient {
  static String get baseUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000';
  // static const String baseUrl = 'https://your-backend.onrender.com'; // Production

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  ApiClient() {
    // Add auth token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
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
            // Supabase handles token refresh automatically in the background.
            // If we still get a 401, it might mean the session is truly invalid/expired.
            // We could attempt to force a refresh here if needed, but usually
            // Supabase.instance.client.auth.currentSession handles it.
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Auth methods
  Future<Response> register(
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

  Future<Response> login(String email, String password) async {
    return _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
  }

  Future<Response> getMe() async {
    return _dio.get('/api/auth/me');
  }

  Future<Response> logout() async {
    return _dio.post('/api/auth/logout');
  }
}
