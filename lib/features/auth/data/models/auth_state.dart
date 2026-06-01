import 'package:ecopin_app/core/constants/app_constants.dart';

// Represents the authentication state of the user, including whether they are authenticated and their role (if authenticated).

class AppAuthState {
  final bool isAuthenticated;
  final UserRole? role;
  final bool isLoading;

  const AppAuthState({
    required this.isAuthenticated,
    this.role,
    this.isLoading = false,
  });

  factory AppAuthState.initial() =>
      const AppAuthState(isAuthenticated: false, isLoading: true);

  factory AppAuthState.authenticated(UserRole? role) =>
      AppAuthState(isAuthenticated: true, role: role, isLoading: false);

  factory AppAuthState.unauthenticated() =>
      const AppAuthState(isAuthenticated: false, isLoading: false);

  @override
  String toString() =>
      'AppAuthState(isAuthenticated: $isAuthenticated, role: $role, isLoading: $isLoading)';
}
