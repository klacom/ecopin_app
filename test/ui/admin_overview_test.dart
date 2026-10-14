import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';

const summary = <String, dynamic>{
  'users': {'total': 17},
  'reports': {'total': 82},
  'auditLogs': {'total': 241},
};

class SyntheticAdminRepository extends AdminRepository {
  SyntheticAdminRepository() : super(ApiClient());
  var requests = 0;
  Object? error;
  @override
  Future<Map<String, dynamic>> getStats() async {
    requests++;
    if (error != null) throw error!;
    return summary;
  }
}

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true');
    await (FontLoader('Outfit')
          ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Outfit-SemiBold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final dark in [false, true]) {
    testWidgets(
      'real summary states and supported destinations at 320px / 2x / ${dark ? "dark" : "light"}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = SyntheticAdminRepository()
          ..error = const FormatException('Synthetic failure');
        final router = GoRouter(
          initialLocation: AdminAppRoutes.dashboard,
          routes: [
            GoRoute(
              path: AdminAppRoutes.dashboard,
              builder: (context, state) => const AdminDashboardScreen(),
            ),
            for (final path in [
              AdminAppRoutes.users,
              AdminAppRoutes.settings,
              AdminAppRoutes.auditLogs,
              AdminAppRoutes.notifications,
              AdminAppRoutes.profile,
              OfficerAppRoutes.reports,
            ])
              GoRoute(
                path: path,
                builder: (context, state) =>
                    Scaffold(body: Text('Destination: $path')),
              ),
          ],
        );
        addTearDown(router.dispose);
        const preview = Key('admin-overview-preview');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              adminRepositoryProvider.overrideWithValue(repository),
              unreadNotificationsCountProvider.overrideWith(
                (ref) => Stream.value(123),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => RepaintBoundary(
                key: preview,
                child: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Summary unavailable'), findsOneWidget);
        expect(find.text('17'), findsNothing);
        repository.error = null;
        await tester.ensureVisible(find.text('Try again'));
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(repository.requests, 2);
        expect(find.text('Account summary'), findsOneWidget);
        expect(find.text('17'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
        if (output != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(preview),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$output/mobile-admin-overview-${dark ? "dark" : "light"}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        for (final entry in {
          'Manage users': AdminAppRoutes.users,
          'Open security settings': AdminAppRoutes.settings,
          'Open audit logs': AdminAppRoutes.auditLogs,
          'Review reports': OfficerAppRoutes.reports,
        }.entries) {
          await tester.ensureVisible(find.text(entry.key));
          await tester.pumpAndSettle();
          await tester.tap(find.text(entry.key));
          await tester.pumpAndSettle();
          expect(find.text('Destination: ${entry.value}'), findsOneWidget);
          router.go(AdminAppRoutes.dashboard);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byTooltip('Notifications, 123 unread'));
        await tester.pumpAndSettle();
        expect(
          find.text('Destination: ${AdminAppRoutes.notifications}'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  test(
    'access errors offer account recovery and never expose server payloads',
    () {
      final error = dio.DioException(
        requestOptions: dio.RequestOptions(path: '/synthetic'),
        response: dio.Response(
          requestOptions: dio.RequestOptions(path: '/synthetic'),
          statusCode: 403,
          data: {'error': 'Synthetic internal payload'},
        ),
      );
      expect(adminRequiresAccountRecovery(error), isTrue);
      expect(adminErrorMessage(error), contains('administrator access'));
      expect(adminErrorMessage(error), isNot(contains('internal payload')));
    },
  );
}
