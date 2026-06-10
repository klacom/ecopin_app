import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                await Supabase.instance.client
                    .from('notifications')
                    .update({'is_read': true})
                    .eq('user_id', user.id);
                ref.invalidate(notificationsProvider);
              }
            },
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final bool isRead = notification['is_read'] ?? false;

              return ListTile(
                tileColor: isRead ? null : Colors.blue.withValues(alpha: 0.05),
                leading: CircleAvatar(
                  backgroundColor: isRead ? Colors.grey : Colors.green,
                  child: const Icon(Icons.notifications, color: Colors.white),
                ),
                title: Text(
                  notification['title'] ?? 'No Title',
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification['body'] ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      DateTime.parse(notification['created_at'])
                          .toLocal()
                          .toString()
                          .split('.')[0],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () async {
                  // Mark as read
                  if (!isRead) {
                    await Supabase.instance.client
                        .from('notifications')
                        .update({'is_read': true})
                        .eq('id', notification['id']);
                    ref.invalidate(notificationsProvider);
                  }

                  // Navigate to report details if report_id exists
                  final reportId = notification['report_id'];
                  if (reportId != null && context.mounted) {
                    context.push('${ProtectedAppRoutes.reports}/$reportId');
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
