import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecopin_app/shared/widgets/private_media_image.dart';

class LocalHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer server;
  late List<int> png;
  final requests = <String>[];
  final authorizations = <String?>[];
  Completer<void>? slow;
  var denyOnce = false;
  var refreshes = 0;
  final token =
      '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({'sub': '11111111-1111-4111-8111-111111111111', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})))}.fixture';
  final session = {
    'access_token': token,
    'refresh_token': 'local-fixture',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': {
      'id': '11111111-1111-4111-8111-111111111111',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'fixture@ecopin.test',
      'app_metadata': {},
      'user_metadata': {},
      'created_at': '2026-10-12T00:00:00Z',
    },
  };

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // Real localhost HTTP is needed; Flutter otherwise forces all requests to 400.
    HttpOverrides.global = null;
    png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAACXBIWXMAAAPoAAAD6AG1e1JrAAAADklEQVQImWNg+A+FMAYAQ84H+QDi4rkAAAAASUVORK5CYII=',
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final base = 'http://127.0.0.1:${server.port}';
    server.listen((request) async {
      if (request.uri.path.endsWith('/token')) {
        refreshes++;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(session));
      } else if (request.uri.path.endsWith('/logout')) {
        request.response.statusCode = 204;
      } else {
        requests.add(request.uri.queryParameters['path'] ?? '');
        authorizations.add(request.headers.value('Authorization'));
        if (request.uri.queryParameters['path']?.contains('slow') == true) {
          await slow?.future;
        }
        if (denyOnce) {
          denyOnce = false;
          request.response.statusCode = 401;
        } else {
          request.response.headers.contentType = ContentType('image', 'png');
          request.response.add(png);
        }
      }
      await request.response.close();
    });
    dotenv.loadFromString(
      envString: 'NEXT_PUBLIC_SUPABASE_URL=$base\nBACKEND_URL=$base',
    );
    await Supabase.initialize(
      url: base,
      publishableKey: 'local-fixture',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );
  });
  tearDownAll(() async {
    slow?.complete();
    await Supabase.instance.dispose();
    await server.close(force: true);
  });
  setUp(() async {
    requests.clear();
    authorizations.clear();
    denyOnce = false;
    refreshes = 0;
    await Supabase.instance.client.auth.recoverSession(jsonEncode(session));
  });

  Widget photo(String path) => MaterialApp(
    home: PrivateMediaImage(
      'storage://Cleanup%20Task%20Photos/task/before/$path',
      width: 40,
      height: 40,
      errorBuilder: (_, error, stack) => Text('Media failure: $error'),
    ),
  );
  Future<void> render(WidgetTester tester, String path) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(photo(path));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 20));
  }

  Future<void> loaded(WidgetTester tester) async {
    for (var i = 0; i < 60 && find.byType(Image).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }

  testWidgets(
    'authorized PNG renders; source switch rejects stale response; logout clears bytes',
    (tester) => HttpOverrides.runZoned(() async {
      HttpOverrides.global = null;
      await render(tester, 'first.png');
      await loaded(tester);
      expect(
        find.byType(RawImage),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .join(';'),
      );
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      expect(authorizations.single, 'Bearer $token');
      slow = Completer<void>();
      await render(tester, 'slow.png');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      expect(find.byType(Image), findsNothing);
      await render(tester, 'next.png');
      await loaded(tester);
      expect(find.byType(Image), findsOneWidget);
      slow!.complete();
      slow = null;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
      expect(requests.last, 'task/before/next.png');
      final count = requests.length;
      await tester.runAsync(() => Supabase.instance.client.auth.signOut());
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(find.textContaining('Authentication required'), findsOneWidget);
      expect(requests.length, count);
      await tester.pumpWidget(const SizedBox.shrink());
    }, createHttpClient: LocalHttp().createHttpClient),
  );

  testWidgets(
    '401 refresh retries once and renders real PNG bytes',
    (tester) => HttpOverrides.runZoned(() async {
      HttpOverrides.global = null;
      denyOnce = true;
      await render(tester, 'refresh.png');
      await loaded(tester);
      expect(requests.length, 2);
      expect(refreshes, 1);
      expect(find.byType(RawImage), findsOneWidget);
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, createHttpClient: LocalHttp().createHttpClient),
  );
}
