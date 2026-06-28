import 'dart:async';
import 'package:ecopin_app/features/notifications/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:logging/logging.dart';

Future<void> main() async {

  // Logger Package for Logging

  Logger.root.level = Level.ALL;

  Logger.root.onRecord.listen((record){
    print(
      '${record.time} '
      '[${record.level.name}] '
      '${record.loggerName}: '
      '${record.message}'
    );
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

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
