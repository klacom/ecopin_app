import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/notification_destination.dart';
import '../../data/notification_repository.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, this.role = UserRole.citizen});
  final UserRole role;
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _working = <String>{};
  final _feedbackKey = GlobalKey();
  bool _markingAll = false, _refreshing = false, _unreadOnly = false;
  String? _feedback;
  bool _failed = false;

  void _message(String message, {bool failed = false}) {
    if (!mounted) return;
    setState(() {
      _feedback = message;
      _failed = failed;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _feedbackKey.currentContext == null) return;
      Scrollable.ensureVisible(
        _feedbackKey.currentContext!,
        alignment: .5,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
      );
    });
  }

  void _invalidate() {
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsCountProvider);
  }

  Future<void> _refresh() async {
    if (_refreshing || _markingAll || _working.isNotEmpty) return;
    setState(() => _refreshing = true);
    _invalidate();
    try {
      await ref.read(notificationsProvider.future);
    } catch (_) {
      _message(
        'Could not reload notifications. Please try again.',
        failed: true,
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _markAll() async {
    if (_markingAll || _working.isNotEmpty) return;
    setState(() => _markingAll = true);
    try {
      final count = await ref
          .read(notificationRepositoryProvider)
          .markAllRead();
      if (!mounted) return;
      _invalidate();
      _message(
        count == 0
            ? 'All notifications are already read.'
            : '$count ${count == 1 ? 'notification' : 'notifications'} marked as read.',
      );
    } catch (_) {
      _message(
        'Could not mark all notifications as read. Please try again.',
        failed: true,
      );
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id is! String ||
        _working.contains(id) ||
        _markingAll ||
        row['is_read'] == true) {
      return;
    }
    setState(() => _working.add(id));
    try {
      await ref.read(notificationRepositoryProvider).markRead(id);
      if (!mounted) return;
      _invalidate();
      _message('Notification marked as read.');
    } catch (_) {
      _message(
        'Could not mark this notification as read. Please try again.',
        failed: true,
      );
    } finally {
      if (mounted) setState(() => _working.remove(id));
    }
  }

  Future<void> _remove(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id is! String || _working.contains(id) || _markingAll) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Remove notification?'),
        content: Text(
          'Remove “${_text(row['title'], 'Notification')}” from your notifications. This removes the notification only.',
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _working.contains(id) || _markingAll) {
      return;
    }
    setState(() => _working.add(id));
    try {
      await ref.read(notificationRepositoryProvider).delete(id);
      if (!mounted) return;
      _invalidate();
      _message('Notification removed.');
    } catch (_) {
      _message(
        'Could not remove this notification. Please try again.',
        failed: true,
      );
    } finally {
      if (mounted) setState(() => _working.remove(id));
    }
  }

  Future<void> _open(
    Map<String, dynamic> row,
    NotificationDestination destination,
  ) async {
    if (_working.contains(row['id']) || _markingAll) return;
    await _markRead(row);
    if (mounted) context.push(destination.path);
  }

  String _text(Object? value, String fallback) =>
      value is String && value.trim().isNotEmpty ? value : fallback;
  DateTime? _date(Map<String, dynamic> row) =>
      DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
  String _group(Map<String, dynamic> row) {
    final date = _date(row);
    if (date == null) return 'Date unavailable';
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now), day = DateUtils.dateOnly(date);
    if (day == today) return 'Today';
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday';
    }
    return MaterialLocalizations.of(context).formatMediumDate(day);
  }

  Widget _card(Map<String, dynamic> row) {
    final title = _text(row['title'], 'Notification');
    final isRead = row['is_read'] == true;
    final working = _working.contains(row['id']);
    final enabled = !working && !_markingAll;
    final destination = notificationDestination(row, widget.role);
    final date = _date(row);
    final colors = Theme.of(context).colorScheme;
    final unreadForeground = Theme.of(context).brightness == Brightness.dark
        ? AppColors.linkDark
        : AppColors.accent;
    return Semantics(
      container: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: isRead ? colors.surface : colors.primary.withValues(alpha: .06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isRead
                ? (Theme.of(context).dividerTheme.color ?? colors.outlineVariant)
                : colors.primary.withValues(alpha: .35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Actions for $title',
                    enabled: enabled && row['id'] is String,
                    onSelected: (action) {
                      if (action == 'read') {
                        _markRead(row);
                      } else {
                        _remove(row);
                      }
                    },
                    itemBuilder: (_) => [
                      if (!isRead)
                        const PopupMenuItem(
                          value: 'read',
                          child: Text('Mark as read'),
                        ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove notification'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    isRead ? 'Read' : 'Unread',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isRead
                          ? colors.onSurfaceVariant
                          : unreadForeground,
                    ),
                  ),
                  Text(
                    date == null
                        ? 'Time unavailable'
                        : MaterialLocalizations.of(context).formatTimeOfDay(
                            TimeOfDay.fromDateTime(date),
                            alwaysUse24HourFormat:
                                MediaQuery.alwaysUse24HourFormatOf(context),
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _text(row['body'], 'No additional details.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (working) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(
                  semanticsLabel: 'Updating notification',
                ),
              ],
              if (destination != null) ...[
                const SizedBox(height: 12),
                AppButton(
                  text: destination.label,
                  variant: ButtonVariant.link,
                  onPressed: enabled ? () => _open(row, destination) : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final rows = state.value;
    final unread = rows?.where((row) => row['is_read'] == false).length ?? 0;
    final shown = rows
        ?.where((row) => !_unreadOnly || row['is_read'] == false)
        .toList();
    final busy = _markingAll || _working.isNotEmpty || _refreshing;
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final row in shown ?? <Map<String, dynamic>>[]) {
      groups.putIfAbsent(_group(row), () => []).add(row);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Reload notifications',
            onPressed: busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (rows != null)
                        Text(
                          '$unread unread · ${rows.length} total',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: !_unreadOnly,
                            onSelected: (_) =>
                                setState(() => _unreadOnly = false),
                          ),
                          ChoiceChip(
                            label: const Text('Unread'),
                            selected: _unreadOnly,
                            onSelected: (_) =>
                                setState(() => _unreadOnly = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Mark all as read',
                        variant: ButtonVariant.secondary,
                        isLoading: _markingAll,
                        onPressed:
                            unread > 0 &&
                                !busy &&
                                !state.hasError &&
                                !state.isLoading
                            ? _markAll
                            : null,
                      ),
                      if (_feedback != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          key: _feedbackKey,
                          liveRegion: true,
                          child: Text(
                            _feedback!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _failed
                                      ? Theme.of(context).colorScheme.error
                                      : null,
                                ),
                          ),
                        ),
                      ],
                      if (_refreshing || (state.isLoading && rows != null)) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(
                          semanticsLabel: 'Reloading notifications',
                        ),
                      ],
                      if (state.hasError && rows != null) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Updates are unavailable. Showing the last loaded notifications.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (rows == null)
                SliverFillRemaining(
                  child: state.hasError
                      ? AppStateView(
                          title: 'Notifications unavailable',
                          message:
                              'We could not load your updates. Reload them to try again.',
                          icon: Icons.notifications_off_outlined,
                          actionLabel: 'Reload notifications',
                          onAction: _refresh,
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Loading notifications',
                          ),
                        ),
                )
              else if (shown!.isEmpty)
                SliverFillRemaining(
                  child: AppStateView(
                    title: _unreadOnly
                        ? 'You are all caught up'
                        : 'No notifications yet',
                    message: _unreadOnly
                        ? 'There are no unread updates in your notifications.'
                        : 'Report and account updates will appear here.',
                    icon: Icons.notifications_none,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  sliver: SliverList.list(
                    children: [
                      for (final group in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          child: Semantics(
                            header: true,
                            child: Text(
                              group.key,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        ...group.value.map(_card),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
