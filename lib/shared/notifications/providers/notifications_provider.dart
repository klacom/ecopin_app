import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return 0;

  try {
    final response = await Supabase.instance.client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .eq('is_read', false);

    return response.length;
  } catch (error) {
    return 0;
  }
});

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (error) {
    return [];
  }
});
