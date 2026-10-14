import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => SupabaseNotificationRepository(Supabase.instance.client),
);

abstract interface class NotificationRepository {
  Stream<List<Map<String, dynamic>>> watch();
  Future<void> markRead(String id);
  Future<int> markAllRead();
  Future<void> delete(String id);
}

/// The existing user-scoped notification stream and mutations, with explicit
/// acknowledgement before UI success. RLS remains authoritative.
class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this.client);
  final SupabaseClient client;
  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Sign in to manage notifications');
    return id;
  }

  @override
  Stream<List<Map<String, dynamic>>> watch() {
    final user = client.auth.currentUser;
    if (user == null) return Stream.value([]);
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  @override
  Future<void> markRead(String id) async {
    final rows = await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _userId)
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) throw StateError('Notification is no longer available');
  }

  @override
  Future<int> markAllRead() async {
    final rows = await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _userId)
        .eq('is_read', false)
        .select('id');
    return rows.length;
  }

  @override
  Future<void> delete(String id) async {
    final rows = await client
        .from('notifications')
        .delete()
        .eq('user_id', _userId)
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) throw StateError('Notification is no longer available');
  }
}
