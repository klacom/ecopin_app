import 'package:ecopin_app/shared/notifications/services/notification_service.dart';
import 'dart:async';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/auth/data/models/auth_state.dart';
import 'package:ecopin_app/features/officer/providers/officer_clusters_provider.dart';
import 'package:ecopin_app/features/officer/providers/officer_cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_response_logs_screen.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for AuthNotifier
final authNotifierProvider = ChangeNotifierProvider((ref) => AuthNotifier(ref));

class AuthNotifier extends ChangeNotifier {
  final Ref _ref;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _log = Logger('Auth Notifier');
  AppAuthState _state = AppAuthState.initial();
  StreamSubscription<AuthState>? _authSubscription;

  AuthNotifier(this._ref) {
    _initialize();
  }

  AppAuthState get state => _state;

  void _clearCachedData() {
    // Clear cached data from providers when switching accounts
    if (_ref.container.exists(officerClustersProvider)) {
      _ref.read(officerClustersProvider.notifier).reset();
    }
    if (_ref.container.exists(officerCleanupTasksProvider)) {
      _ref.read(officerCleanupTasksProvider.notifier).reset();
    }
    if (_ref.container.exists(officerResponseLogsProvider)) {
      _ref.read(officerResponseLogsProvider.notifier).reset();
    }
    // Invalidate profile provider to reset it
    _ref.invalidate(profileProvider);
  }

  void _initialize() {
    // Check current session
    final session = _supabase.auth.currentSession;
    _updateState(session);

    // Listen to auth changes
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _ref.read(notificationServiceProvider).subscribeToNotifications();
        // Clear cached data when signing in (account switch)
        _clearCachedData();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _ref.read(notificationServiceProvider).unsubscribe();
      }
      _updateState(data.session);
    });

    if (session != null) {
      _ref.read(notificationServiceProvider).subscribeToNotifications();
    }
  }

  Future<void> _updateState(Session? session) async {
    if (session == null) {
      _state = AppAuthState.unauthenticated();
      notifyListeners();
    } else {
      // First set state to loading while fetching user/role
      _state = const AppAuthState(isAuthenticated: true, isLoading: true);
      notifyListeners();
      try {
        // Fetch user and role from backend (database-driven)
        final apiClient = _ref.read(apiClientProvider);
        final response = await apiClient.getMe();

        final userData = response.data['user'];
        final roleString = userData['role'] as String?;

        _log.info('User data from backend: $userData');
        _log.info('Role string from backend: $roleString');

        UserRole? role;
        if (roleString != null) {
          // Special case for snake_case coming from backend
          if (roleString == 'field_crew') {
            role = UserRole.fieldCrew;
          } else {
            role = UserRole.values.firstWhere(
              (e) => e.name == roleString,
              orElse: () {
                _log.warning(
                  'Role "$roleString" not found in UserRole enum, defaulting to citizen',
                );
                return UserRole.citizen;
              },
            );
          }
        } else {
          _log.warning('Role string is null, defaulting to citizen');
          role = UserRole.citizen;
        }

        _log.info('Resolved UserRole: ${role.name}');
        _state = AppAuthState.authenticated(role);
      } catch (e, stackTrace) {
        // If backend fails, we might still have a Supabase session but
        // we can't verify the role/user in our DB.
        // For safety, we can either treat as unauthenticated or use a default.
        _log.severe('Error fetching user role: $e', stackTrace);
        _state = AppAuthState.unauthenticated();
      }
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      // 1. Clear cached data from providers
      _clearCachedData();

      // 2. Call backend logout if possible
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.logout();
    } catch (e, stackTrace) {
      // Ignore backend logout errors and proceed with local signout
      _log.severe(e, stackTrace);
    } finally {
      // 3. Clear Supabase session locally
      await _supabase.auth.signOut();
      // _updateState will be triggered by onAuthStateChange listener
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}


