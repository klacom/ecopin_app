import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class PendingChangeAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'message': 'Synthetic result'}),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiClient api;
  late PendingChangeAdapter adapter;
  setUp(() {
    dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (_) async => ['wifi'],
        );
    api = ApiClient();
    adapter = PendingChangeAdapter();
    api.dioClient.httpClientAdapter = adapter;
    // Keep the real interceptors and leave Supabase uninitialized. This request
    // must use only the explicit pending token, without reading an SDK session.
  });
  tearDown(() {
    api.dioClient.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          null,
        );
  });
  test(
    'pending update preserves endpoint/body and uses only its explicit token',
    () async {
      await api.forceChangePassword(
        newPassword: 'NewPassword123!',
        accessToken: 'synthetic-pending',
      );
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/auth/force-change-password');
      expect(request.data, {'new_password': 'NewPassword123!'});
      expect(request.headers['Authorization'], 'Bearer synthetic-pending');
    },
  );
  test(
    'expired pending request never refreshes or retries a persisted session',
    () async {
      adapter.status = 401;
      await expectLater(
        api.forceChangePassword(
          newPassword: 'NewPassword123!',
          accessToken: 'synthetic-expired',
        ),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests.length, 1);
    },
  );
  test('missing pending credentials never start a request', () async {
    await expectLater(
      api.forceChangePassword(newPassword: 'NewPassword123!', accessToken: ''),
      throwsArgumentError,
    );
    expect(adapter.requests, isEmpty);
  });
}
