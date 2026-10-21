import 'dart:async';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/citizen/presentation/screens/citizen_main_screen.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Outfit')
          ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Outfit-SemiBold.ttf')))
        .load();
  });
  for (final dark in [false, true]) {
    testWidgets(
      'citizen profile photo and initials update from profile / $dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final profiles = StreamController<Map<String, dynamic>?>();
        addTearDown(profiles.close);
        final router = GoRouter(
          initialLocation: ProtectedAppRoutes.maps,
          routes: [
            ShellRoute(
              builder: (_, _, child) => CitizenMainScreen(child: child),
              routes: [
                GoRoute(
                  path: ProtectedAppRoutes.maps,
                  builder: (_, _) => const Scaffold(body: Text('Public map')),
                ),
                GoRoute(
                  path: ProtectedAppRoutes.profile,
                  builder: (_, _) => const Scaffold(body: Text('Account page')),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              profileProvider.overrideWith((ref) => profiles.stream),
              unreadNotificationsCountProvider.overrideWith(
                (ref) => Stream.value(0),
              ),
            ],
            child: MaterialApp.router(
              theme: dark ? AppTheme.dark : AppTheme.light,
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
            ),
          ),
        );
        profiles.add({'full_name': '  Juan  Dela Cruz ', 'avatar_url': null});
        await tester.pumpAndSettle();
        expect(find.text('JC'), findsOneWidget);
        expect(
          tester
              .widget<CircleAvatar>(find.byType(CircleAvatar))
              .foregroundImage,
          isNull,
        );
        profiles.add({
          'full_name': 'Juan Dela Cruz',
          'avatar_url': 'https://synthetic.invalid/avatar.png',
        });
        await tester.pumpAndSettle();
        final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
        expect(
          (avatar.foregroundImage as NetworkImage).url,
          'https://synthetic.invalid/avatar.png',
        );
        expect(avatar.onForegroundImageError, isNotNull);
        profiles.add({'full_name': 'Ana', 'avatar_url': '  '});
        await tester.pumpAndSettle();
        expect(find.text('A'), findsOneWidget);
        expect(
          tester
              .widget<CircleAvatar>(find.byType(CircleAvatar))
              .foregroundImage,
          isNull,
        );
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Account page'), findsOneWidget);
        profiles.add({'full_name': ' '});
        await tester.pumpAndSettle();
        expect(find.text('?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
