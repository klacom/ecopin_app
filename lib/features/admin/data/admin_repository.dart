import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';

final adminRepositoryProvider = Provider.autoDispose(
  (ref) => AdminRepository(ref.watch(apiClientProvider)),
);
final adminStatsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(adminRepositoryProvider).getStats(),
  retry: (retryCount, error) => null,
);

const adminRoles = {
  'citizen': 'Citizen',
  'field_crew': 'Field crew',
  'officer': 'Officer',
  'admin': 'Administrator',
};

class AdminRepository {
  AdminRepository(this.api);
  final ApiClient api;
  Map<String, dynamic> _data(Response response) {
    if (response.data is! Map) {
      throw const FormatException('Admin response unavailable');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getStats() async =>
      _data(await api.getSystemStats());
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    String search = '',
    String role = '',
  }) async => _data(
    await api.dioClient.get(
      '/api/admin/users',
      queryParameters: {
        'page': page,
        'limit': 20,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (role.isNotEmpty) 'role': role,
      },
    ),
  );
  Future<Map<String, dynamic>> getUser(String id) async => _data(
    await api.dioClient.get('/api/admin/users/${Uri.encodeComponent(id)}'),
  );
  Future<Map<String, dynamic>> getSettings() async =>
      _data(await api.dioClient.get('/api/admin/settings'));
  Future<Map<String, dynamic>> saveSettings(
    Map<String, dynamic> settings,
  ) async => _data(
    await api.dioClient.patch(
      '/api/admin/settings',
      data: {
        for (final key in [
          'id',
          'password_min_length',
          'password_require_uppercase',
          'password_require_lowercase',
          'password_require_numbers',
          'password_require_special_chars',
          'session_timeout_minutes',
        ])
          if (settings.containsKey(key)) key: settings[key],
      },
    ),
  );
  Future<Map<String, dynamic>> getAuditLogs({
    int page = 1,
    String action = '',
    String userId = '',
    String startDate = '',
    String endDate = '',
  }) async => _data(
    await api.dioClient.get(
      '/api/admin/audit-logs',
      queryParameters: {
        'page': page,
        'limit': 50,
        if (action.isNotEmpty) 'action_type': action,
        if (userId.isNotEmpty) 'user_id': userId,
        if (startDate.isNotEmpty) 'start_date': startDate,
        if (endDate.isNotEmpty) 'end_date': endDate,
      },
    ),
  );
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    _checkRole(role);
    if (password.isEmpty) {
      throw ArgumentError('An explicit password is required.');
    }
    await api.dioClient.post(
      '/api/admin/users',
      data: {
        'email': email.trim(),
        'password': password,
        'full_name': name.trim(),
        'role': role,
      },
    );
  }

  Future<void> changeRole(String id, String role) async {
    _checkRole(role);
    await api.dioClient.patch(
      '/api/admin/users/${Uri.encodeComponent(id)}/role',
      data: {'role': role},
    );
  }

  Future<void> resetPassword(String id, String password) async {
    if (password.isEmpty) {
      throw ArgumentError('An explicit password is required.');
    }
    await api.dioClient.patch(
      '/api/admin/users/${Uri.encodeComponent(id)}/password',
      data: {'password': password},
    );
  }

  Future<void> deleteUser(String id) async {
    await api.dioClient.delete('/api/admin/users/${Uri.encodeComponent(id)}');
  }

  void _checkRole(String role) {
    if (!adminRoles.containsKey(role)) throw ArgumentError.value(role, 'role');
  }
}

String adminErrorMessage(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401) {
      return 'Your session could not be verified. Open Account to sign out and sign in again.';
    }
    if (status == 403) {
      return 'This action requires administrator access. Your account may no longer have permission.';
    }
    if (status == 429) {
      return 'Too many requests. Wait a moment before trying again.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The server could not be reached. Check your connection and try again.';
    }
  }
  return 'This information could not be loaded or saved. Try again.';
}

bool adminRequiresAccountRecovery(Object? error) =>
    error is DioException && [401, 403].contains(error.response?.statusCode);
