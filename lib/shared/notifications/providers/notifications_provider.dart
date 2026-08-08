import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value(0);

  final stream = Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .map(
        (rows) => rows
            .where(
              (row) => row['user_id'] == user.id && row['is_read'] == false,
            )
            .length,
      );

  return stream;
});

final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value([]);

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .map((data) => List<Map<String, dynamic>>.from(data));
});
