import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';

// This class is responsible for managing authentication-related data operations,
// such as retrieving user roles and managing the current session.

class AuthDataSource {
  final SupabaseClient _supabase;

  AuthDataSource(this._supabase);

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get User Email
  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }
}
