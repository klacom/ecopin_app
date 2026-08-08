import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/routes/app_routes.dart';

class NotificationBadgeAction extends ConsumerWidget {
  const NotificationBadgeAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () {
          // Go to notifications screen. Since it's shared, we use the protected route.
          context.push(ProtectedAppRoutes.notifications);
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
