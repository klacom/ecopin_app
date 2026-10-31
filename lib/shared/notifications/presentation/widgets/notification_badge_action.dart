import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/auth/providers/auth_notifier.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/routes/app_routes.dart';

// Displays a notification bell icon with a badge for unread count.
// Navigates to the role-scoped notifications path so the correct shell
// (field crew or citizen) is preserved — not the citizen shell.
class NotificationBadgeAction extends ConsumerWidget {
  const NotificationBadgeAction({super.key, this.role});
  // A role-scoped page may provide its known destination; guards stay authoritative.
  final UserRole? role;

  String _notificationsRouteForRole(UserRole? role) {
    switch (role) {
      case UserRole.fieldCrew:
        return FieldCrewAppRoutes.notifications;
      default:
        // Citizens stay within their own shell
        return ProtectedAppRoutes.notifications;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    final unreadCount = unread.value ?? 0;
    
    // Determine destination role:
    // 1. Explicit role passed in widget constructor
    // 2. Auth state role
    // 3. Fallback based on current route location (e.g. /field-crew/* -> field crew)
    UserRole? resolvedRole = role ?? ref.watch(authNotifierProvider).state.role;
    if (resolvedRole == null || resolvedRole == UserRole.citizen) {
      final location = GoRouterState.of(context).matchedLocation;
      if (location.startsWith('/field-crew')) {
        resolvedRole = UserRole.fieldCrew;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: IconButton(
        tooltip: unread.hasError
            ? 'Notifications, unread count unavailable'
            : unread.isLoading
            ? 'Notifications, loading unread count'
            : 'Notifications, $unreadCount unread',
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: () {
          context.push(_notificationsRouteForRole(resolvedRole));
        },
        icon: Badge(
          isLabelVisible: unreadCount > 0,
          label: ExcludeSemantics(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          child: const Icon(Icons.notifications_outlined),
        ),
      ),
    );
  }
}
