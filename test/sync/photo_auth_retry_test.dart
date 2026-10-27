import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide Headers, MultipartFile;

class PhotoAdapter implements HttpClientAdapter {
  bool alwaysUnauthorized = false;
  final tokens = <Object?>[];
  final bodies = <String>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    tokens.add(options.headers['Authorization']);
    bodies.add(utf8.decode(await requestStream!.expand((b) => b).toList()));
    return ResponseBody.fromString(
      jsonEncode({'error': 'Invalid token'}),
      alwaysUnauthorized || tokens.length == 1 ? 401 : 200,
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
  String token(String label) {
    String part(Object data) =>
        base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
    return '${part({'alg': 'HS256'})}.${part({'sub': 'crew', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600, 'label': label})}.synthetic';
  }

  Map<String, dynamic> session(String accessToken) => {
    'access_token': accessToken,
    'refresh_token': 'synthetic-refresh',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': {
      'id': 'crew',
      'aud': 'authenticated',
      'app_metadata': {},
      'user_metadata': {},
      'created_at': '2026-01-01T00:00:00Z',
    },
  };
  late String initialToken;
  late String refreshedToken;
  setUpAll(() async {
    dotenv.loadFromString(envString: 'BACKEND_URL=https://synthetic.invalid');
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://synthetic.supabase.co',
      publishableKey: 'synthetic',
      debug: false,
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode(session(refreshedToken)),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  for (final photoType in ['before', 'after']) {
    test(
      '$photoType photo is resent intact with refreshed authentication after 401',
      () async {
        initialToken = token('old');
        refreshedToken = token('new');
        await Supabase.instance.client.auth.setInitialSession(
          jsonEncode(session(initialToken)),
        );
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('dev.fluttercommunity.plus/connectivity'),
              (_) async => ['wifi'],
            );
        final api = ApiClient();
        addTearDown(() => api.dioClient.close());
        final adapter = PhotoAdapter();
        api.dioClient.httpClientAdapter = adapter;
        final response = await api.dioClient.post(
          '/api/reports/report/photo',
          data: FormData.fromMap({
            'photo_type': photoType,
            'photo_id': 'stable-photo-id',
            'image': MultipartFile.fromString(
              'synthetic-photo-bytes',
              filename: 'photo.jpg',
            ),
          }),
        );
        expect(response.statusCode, 200);
        expect(adapter.tokens, [
          'Bearer $initialToken',
          'Bearer $refreshedToken',
        ]);
        expect(adapter.bodies, hasLength(2));
        for (final body in adapter.bodies) {
          expect(body, contains('synthetic-photo-bytes'));
          expect(body, contains('stable-photo-id'));
          expect(body, contains(photoType));
        }
      },
    );
  }
  test(
    'a missing session blocks photo transport with a recovery message',
    () async {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      final api = ApiClient();
      addTearDown(() => api.dioClient.close());
      final adapter = PhotoAdapter();
      api.dioClient.httpClientAdapter = adapter;
      await expectLater(
        api.dioClient.post(
          '/api/reports/report/photo',
          data: FormData(),
          options: Options(extra: {'requiresSession': true}),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.data['error'],
            'recovery message',
            contains('Sign in again'),
          ),
        ),
      );
      expect(adapter.tokens, isEmpty);
    },
  );
  test('a second 401 stops after one refreshed upload attempt', () async {
    initialToken = token('old');
    refreshedToken = token('new');
    await Supabase.instance.client.auth.setInitialSession(
      jsonEncode(session(initialToken)),
    );
    final api = ApiClient();
    addTearDown(() => api.dioClient.close());
    final adapter = PhotoAdapter()..alwaysUnauthorized = true;
    api.dioClient.httpClientAdapter = adapter;
    await expectLater(
      api.dioClient.post(
        '/api/reports/report/photo',
        data: FormData.fromMap({
          'image': MultipartFile.fromString(
            'synthetic-photo-bytes',
            filename: 'photo.jpg',
          ),
        }),
      ),
      throwsA(isA<DioException>()),
    );
    expect(adapter.tokens, hasLength(2));
  });
}
