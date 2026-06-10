import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value(null);

  return Supabase.instance.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((data) => data.isNotEmpty ? data.first : null);
});
