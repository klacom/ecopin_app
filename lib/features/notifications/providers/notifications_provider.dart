import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value(0);

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((data) => data.length);
});

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final response = await Supabase.instance.client
      .from('notifications')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});
