import 'dart:ui' as ui;
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_profile_screen.dart';
import 'package:ecopin_app/core/providers/theme_mode_provider.dart';
import 'package:ecopin_app/shared/profile/presentation/screens/profile_screen.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://synthetic.supabase.co',
      publishableKey: 'synthetic',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  for (final fail in [false, true]) {
    testWidgets('officer photo removal preserves profile on failure: $fail', (
      tester,
    ) async {
      final api = _AvatarApi(fail);
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
      final image = recorder.endRecording().toImageSync(1, 1);
      PaintingBinding.instance.imageCache.putIfAbsent(
        const NetworkImage('https://synthetic.invalid/avatar.png'),
        () =>
            OneFrameImageStreamCompleter(Future.value(ImageInfo(image: image))),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(api),
            profileProvider.overrideWith(
              (ref) => Stream.value({
                'role': 'officer',
                'full_name': 'Synthetic Person',
                'avatar_url': api.removed
                    ? null
                    : 'https://synthetic.invalid/avatar.png',
              }),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OfficerProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();
      expect(api.calls, 1);
      expect(find.text('Remove photo'), fail ? findsOneWidget : findsNothing);
    });
  }
  for (final role in ['citizen', 'officer', 'field_crew', 'admin', null]) {
    testWidgets('profile account settings for $role', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith(
              (ref) =>
                  Stream.value({'role': role, 'full_name': 'Synthetic Person'}),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: role == 'officer'
                ? const OfficerProfileScreen()
                : const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Delete Account'),
        role == 'citizen' ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Share Personal Information'),
        role == 'citizen' ? findsOneWidget : findsNothing,
      );
      if (role == 'officer') {
        expect(find.text('Assigned permissions role'), findsOneWidget);
        expect(find.text('Theme preference'), findsOneWidget);
        final themePicker = find.byType(DropdownButtonFormField<ThemeMode>);
        await tester.ensureVisible(themePicker);
        await tester.tap(themePicker);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Light').last);
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(OfficerProfileScreen)),
        );
        expect(container.read(themeModeProvider), ThemeMode.light);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

class _AvatarApi implements ApiClient {
  _AvatarApi(this.fail);
  final bool fail;
  int calls = 0;
  bool removed = false;

  @override
  Future<dio.Response> removeAvatar() async {
    calls++;
    if (fail) throw Exception('Synthetic failure');
    removed = true;
    return dio.Response(
      requestOptions: dio.RequestOptions(path: '/api/profile/avatar'),
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
