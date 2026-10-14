import 'dart:convert';
import 'package:ecopin_app/shared/notifications/data/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  late SupabaseNotificationRepository repository;
  final requests = <http.Request>[];
  var responseRows = <Map<String, dynamic>>[];
  const owner = '00000000-0000-4000-8000-000000000001';
  setUp(() async {
    requests.clear();
    responseRows = [
      {'id': 'one'},
    ];
    client = SupabaseClient(
      'https://synthetic.example.invalid',
      'synthetic-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(responseRows),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    // Installed SDK's local-session initialization is used only in this test;
    // no Flutter singleton, real token, remote session or persistence is used.
    await client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'synthetic-token',
        'refresh_token': 'synthetic-refresh',
        'expires_in': 3600,
        'token_type': 'bearer',
        'user': {
          'id': owner,
          'aud': 'authenticated',
          'app_metadata': {},
          'user_metadata': {},
          'created_at': '2026-10-14T00:00:00Z',
        },
      }),
    );
    repository = SupabaseNotificationRepository(client);
  });
  tearDown(() async => client.dispose());
  test(
    'read and removal stay owner-scoped and require a returned record',
    () async {
      await repository.markRead('one');
      expect(requests.single.method, 'PATCH');
      expect(requests.single.url.path, '/rest/v1/notifications');
      expect(requests.single.url.queryParameters, {
        'user_id': 'eq.$owner',
        'id': 'eq.one',
        'select': 'id',
      });
      expect(jsonDecode(requests.single.body), {'is_read': true});
      await repository.delete('one');
      expect(requests.last.method, 'DELETE');
      expect(requests.last.url.queryParameters['user_id'], 'eq.$owner');
      responseRows = [];
      await expectLater(repository.markRead('missing'), throwsStateError);
      await expectLater(repository.delete('missing'), throwsStateError);
    },
  );
  test(
    'mark-all uses unread owner records and reports the acknowledged count',
    () async {
      responseRows = [
        {'id': 'one'},
        {'id': 'two'},
      ];
      expect(await repository.markAllRead(), 2);
      expect(requests.single.url.queryParameters, {
        'user_id': 'eq.$owner',
        'is_read': 'eq.false',
        'select': 'id',
      });
    },
  );
}
