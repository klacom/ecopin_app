import 'package:ecopin_app/features/notifications/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // The fuck does this mean
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Catch "No URL and anonKey available" error
  await Supabase.initialize(
    url: dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] ?? '',
  );

  final container = ProviderContainer();
  await container.read(notificationServiceProvider).init();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const App(),
  ));
}
