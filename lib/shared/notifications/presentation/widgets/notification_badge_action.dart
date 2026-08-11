import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/auth/providers/auth_notifier.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/routes/app_routes.dart';

// Displays a notification bell icon with a badge for unread count.
// Navigates to the role-scoped notifications path so the correct shell
// (OfficerMainScreen, AdminMainScreen, etc.) is preserved — not the citizen shell.
class NotificationBadgeAction extends ConsumerWidget {
  const NotificationBadgeAction({super.key});

  String _notificationsRouteForRole(UserRole? role) {
    switch (role) {
      case UserRole.officer:
        return OfficerAppRoutes.notifications;
      case UserRole.admin:
        return AdminAppRoutes.notifications;
      case UserRole.fieldCrew:
        return FieldCrewAppRoutes.notifications;
      default:
        // Citizens stay within their own shell
        return ProtectedAppRoutes.notifications;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;
    final role = ref.watch(authNotifierProvider).state.role;

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () {
          context.push(_notificationsRouteForRole(role));
        },
        child: Center(
          child: badges.Badge(
            showBadge: unreadCount > 0,
            badgeContent: Text(
              unreadCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            position: badges.BadgePosition.topEnd(top: -5, end: -5),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
      ),
    );
  }
}
