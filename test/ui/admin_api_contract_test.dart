import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';

class CapturingAdminAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Object response = <String, dynamic>{};
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late ApiClient api;
  late CapturingAdminAdapter adapter;
  late AdminRepository repository;
  setUp(() {
    dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true');
    api = ApiClient();
    // Contract tests use a local adapter only; authentication is not simulated here.
    api.dioClient.interceptors.clear();
    adapter = CapturingAdminAdapter();
    api.dioClient.httpClientAdapter = adapter;
    repository = AdminRepository(api);
  });
  tearDown(() => api.dioClient.close());
  test(
    'users and audit filters use the existing server pagination contracts',
    () async {
      await repository.getUsers(
        page: 3,
        search: '  Rosario  ',
        role: 'officer',
      );
      expect(adapter.requests.last.path, '/api/admin/users');
      expect(adapter.requests.last.queryParameters, {
        'page': 3,
        'limit': 20,
        'search': 'Rosario',
        'role': 'officer',
      });
      await repository.getAuditLogs(
        page: 2,
        action: 'profile_update',
        startDate: '2026-10-01',
        endDate: '2026-10-14',
      );
      expect(adapter.requests.last.path, '/api/admin/audit-logs');
      expect(adapter.requests.last.queryParameters, {
        'page': 2,
        'limit': 50,
        'action_type': 'profile_update',
        'start_date': '2026-10-01',
        'end_date': '2026-10-14',
      });
    },
  );
  test(
    'settings keep the existing row identifier and allow only supported settings',
    () async {
      await repository.saveSettings({
        'id': 'existing-settings',
        'password_min_length': 12,
        'session_timeout_minutes': 30,
        'role': 'admin',
        'unrelated': 'discard',
      });
      expect(adapter.requests.last.method, 'PATCH');
      expect(adapter.requests.last.path, '/api/admin/settings');
      expect(adapter.requests.last.data, {
        'id': 'existing-settings',
        'password_min_length': 12,
        'session_timeout_minutes': 30,
      });
    },
  );
  test(
    'account actions retain method and payload and reject unknown roles',
    () async {
      await repository.createUser(
        email: ' synthetic@example.invalid ',
        password: 'SyntheticOnly!123',
        name: ' Synthetic User ',
        role: 'field_crew',
      );
      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.last.data, {
        'email': 'synthetic@example.invalid',
        'password': 'SyntheticOnly!123',
        'full_name': 'Synthetic User',
        'role': 'field_crew',
      });
      await repository.changeRole('encoded/id', 'officer');
      expect(adapter.requests.last.path, '/api/admin/users/encoded%2Fid/role');
      expect(adapter.requests.last.data, {'role': 'officer'});
      await repository.resetPassword('synthetic-id', 'NewSynthetic!123');
      expect(
        adapter.requests.last.path,
        '/api/admin/users/synthetic-id/password',
      );
      expect(adapter.requests.last.data, {'password': 'NewSynthetic!123'});
      await repository.deleteUser('synthetic-id');
      expect(adapter.requests.last.method, 'DELETE');
      expect(adapter.requests.last.path, '/api/admin/users/synthetic-id');
      final count = adapter.requests.length;
      await expectLater(
        repository.changeRole('synthetic-id', 'unsupported-role'),
        throwsArgumentError,
      );
      expect(adapter.requests.length, count);
      await expectLater(
        repository.createUser(
          email: 'synthetic@example.invalid',
          password: '',
          name: 'Synthetic',
          role: 'citizen',
        ),
        throwsArgumentError,
      );
      await expectLater(
        repository.resetPassword('synthetic-id', ''),
        throwsArgumentError,
      );
      expect(adapter.requests.length, count);
    },
  );
  test(
    'malformed summaries are unavailable instead of fabricated zero counts',
    () async {
      adapter.response = 'unavailable';
      await expectLater(repository.getStats(), throwsFormatException);
    },
  );
}
