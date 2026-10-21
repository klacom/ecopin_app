import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/profile/presentation/screens/profile_screen.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:flutter/material.dart';
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
  for (final role in ['citizen', 'officer', 'field_crew', 'admin', null]) {
    testWidgets('profile self-deletion visibility for $role', (tester) async {
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
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Delete Account'),
        role == 'citizen' ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
