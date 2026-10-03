import 'dart:async';
import 'package:ecopin_app/shared/notifications/services/notification_service.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
Future<void> main() async {

  // Logger Package for Logging

  Logger.root.level = kReleaseMode ? Level.WARNING : Level.ALL;

  Logger.root.onRecord.listen((record) {
    if (kDebugMode || record.level >= Level.WARNING) {
      debugPrint(
        '${record.time} '
        '[${record.level.name}] '
        '${record.loggerName}: '
        '${record.message}'
      );
    }
  });

  // dafuq is this
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Catch "No URL and anonKey available" error
  await Supabase.initialize(
    url: dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['NEXT_PUBLIC_PUBLISHABLE_KEY'] ?? '',
  );

  // Handle deep links
  final appLinks = AppLinks();

  // Get initial link if app was opened by a deep link
  final initialLink = await appLinks.getInitialLink();
  Logger('main').info('Skipping migration initialization on web');
  if (initialLink != null) {
    await Supabase.instance.client.auth.getSessionFromUrl(initialLink);
  }

  // Listen for incoming deep links
  appLinks.uriLinkStream.listen((Uri? uri) async {
    if (uri != null) {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    }
  });

  final container = ProviderContainer();
  await container.read(notificationServiceProvider).init();

  // â”€â”€ Phase 4: Sync engine crash recovery â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Reset any outbox items or photos that were in-flight when the app was last
  // killed, so they are retried rather than stuck permanently.
  final syncManager = container.read(fcSyncManagerProvider);
  final photoSyncManager = container.read(fcPhotoSyncManagerProvider);
  await Future.wait([
    syncManager.recoverInFlight(),
    photoSyncManager.recoverInFlight(),
  ]);

  // ── Phase 7: Offline package crash recovery ────────────────────────────────
  // Note: Crash recovery is now handled gracefully inside FcOfflinePackageNotifier._initFromPrefs().
  // Only completed packages are persisted, so mid-flight interruptions naturally revert to idle.

  // Start the connectivity-driven sync trigger (periodic + on-reconnect).
  container.read(fcSyncTriggerProvider).start();

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}

