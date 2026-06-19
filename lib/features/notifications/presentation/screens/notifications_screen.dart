import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _deletingIds = {};
  final ScrollController _scrollController = ScrollController();
  final int _itemsPerPage = 10;
  int _displayedItems = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Load more items
        setState(() {
          _displayedItems += _itemsPerPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

          final visibleNotifications = notifications
              .take(_displayedItems)
              .toList();
          return ListView.separated(
            controller: _scrollController,
            itemCount:
                visibleNotifications.length +
                (notifications.length > visibleNotifications.length ? 1 : 0),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == visibleNotifications.length) {
                // Loading indicator at bottom
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final notification = visibleNotifications[index];
              final bool isRead = notification['is_read'] ?? false;
              final bool isDeleting = _deletingIds.contains(notification['id']);

              return Slidable(
                key: ValueKey(notification['id']),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    if (!isRead)
                      SlidableAction(
                        onPressed: (context) async {
                          await Supabase.instance.client
                              .from('notifications')
                              .update({'is_read': true})
                              .eq('id', notification['id']);
                        },
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        icon: Icons.mark_email_read,
                        label: 'Read',
                      ),
                    SlidableAction(
                      onPressed: (context) async {
                        if (!isDeleting) {
                          setState(() {
                            _deletingIds.add(notification['id']);
                          });
                          try {
                            await Supabase.instance.client
                                .from('notifications')
                                .delete()
                                .eq('id', notification['id']);
                          } finally {
                            if (mounted) {
                              setState(() {
                                _deletingIds.remove(notification['id']);
                              });
                            }
                          }
                        }
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: isDeleting ? Icons.hourglass_empty : Icons.delete,
                      label: isDeleting ? 'Deleting' : 'Delete',
                    ),
                  ],
                ),
                child: ListTile(
                  tileColor: isRead
                      ? null
                      : Colors.blue.withValues(alpha: 0.05),
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey : Colors.green,
                    child: isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.notifications, color: Colors.white),
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
                        DateTime.parse(
                          notification['created_at'],
                        ).toLocal().toString().split('.')[0],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (isDeleting) return;
                    // Mark as read
                    if (!isRead) {
                      await Supabase.instance.client
                          .from('notifications')
                          .update({'is_read': true})
                          .eq('id', notification['id']);
                    }

                    // Navigate to report details if report_id exists
                    final reportId = notification['report_id'];
                    if (reportId != null && context.mounted) {
                      context.push('${ProtectedAppRoutes.reports}/$reportId');
                    }
                  },
                ),
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
