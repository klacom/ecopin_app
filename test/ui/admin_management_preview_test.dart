import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_user_detail_screen.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_account_form.dart';
import 'package:ecopin_app/features/admin/presentation/screens/admin_audit_logs_screen.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'admin_users_test.dart' show SyntheticUsersRepository;
import 'admin_audit_test.dart' show SyntheticAuditRepository;

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true');
    await (FontLoader('Outfit')
          ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Outfit-Medium.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Outfit-SemiBold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final systemMono = File(r'C:\Windows\Fonts\consola.ttf');
    final mono = FontLoader('monospace');
    if (Platform.isWindows && await systemMono.exists()) {
      mono.addFont(
        Future.value(ByteData.sublistView(await systemMono.readAsBytes())),
      );
    } else {
      mono.addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'));
    }
    await mono.load();
  });
  for (final dark in [false, true]) {
    for (final entry in <String, Widget>{
      'users': const AdminUsersScreen(),
      'user-details': const AdminUserDetailScreen(userId: 'other-account'),
      'account-form': const AdminAccountForm(),
      'audit': const AdminAuditLogsScreen(),
    }.entries) {
      testWidgets('${entry.key} at 320px / 2x / ${dark ? "dark" : "light"}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final users = SyntheticUsersRepository();
        const preview = Key('admin-management-preview');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              adminRepositoryProvider.overrideWithValue(
                entry.key == 'audit' ? SyntheticAuditRepository() : users,
              ),
              profileProvider.overrideWith((ref) => Stream.value(users.own)),
              unreadNotificationsCountProvider.overrideWith(
                (ref) => Stream.value(0),
              ),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(2),
                  padding: EdgeInsets.only(bottom: 24),
                ),
                child: RepaintBoundary(key: preview, child: entry.value),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
        if (output != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(preview),
          );
          await tester.runAsync(() async {
            final warm = await boundary.toImage();
            warm.dispose();
          });
          await tester.pump();
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final pixels = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            expect(
              pixels!.buffer.asUint32List().toSet().length,
              greaterThan(10),
              reason: 'Preview must contain rendered content',
            );
            if (entry.key == 'users') {
              final label = tester.getRect(find.text('Create account'));
              final rgba = pixels.buffer.asUint8List();
              var visibleLabelPixels = 0;
              for (var y = label.top.ceil(); y < label.bottom.floor(); y++) {
                for (var x = label.left.ceil(); x < label.right.floor(); x++) {
                  final offset = (y * image.width + x) * 4;
                  if (rgba[offset] > 220 &&
                      rgba[offset + 1] > 220 &&
                      rgba[offset + 2] > 220 &&
                      rgba[offset + 3] > 220) {
                    visibleLabelPixels++;
                  }
                }
              }
              expect(
                visibleLabelPixels,
                greaterThan(20),
                reason: 'Create account label must be visible in the capture',
              );
            }
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$output/mobile-admin-${entry.key}-${dark ? "dark" : "light"}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        if (entry.key == 'users') {
          await tester.ensureVisible(
            find.byKey(const ValueKey('admin-view-other-account')),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('admin-view-other-account')),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const Key('admin-user-role')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('admin-user-role')));
          await tester.pumpAndSettle();
          expect(find.text('Field crew'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
