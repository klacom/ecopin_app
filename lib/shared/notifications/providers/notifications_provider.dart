import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/shared/auth/providers/auth_notifier.dart';
import '../data/notification_repository.dart';

final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  ref.watch(authNotifierProvider);
  return ref.watch(notificationRepositoryProvider).watch();
}, retry: (count, error) => null);

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  ref.watch(authNotifierProvider);
  return ref
      .watch(notificationRepositoryProvider)
      .watch()
      .map((rows) => rows.where((row) => row['is_read'] == false).length);
}, retry: (count, error) => null);
