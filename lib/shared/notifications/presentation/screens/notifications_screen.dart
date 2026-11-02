import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_row.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';
import 'package:ecopin_app/shared/widgets/sliding_switch.dart';
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

  /// Crew screens say alerts in plain words; other roles keep their own.
  bool get _crew => widget.role == UserRole.fieldCrew;
  String _w(String other, String crew) => _crew ? crew : other;

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
        _w(
          'Could not reload notifications. Please try again.',
          'Could not reload your alerts. Check your signal and try again.',
        ),
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
            ? _w(
                'All notifications are already read.',
                'All your alerts are already read.',
              )
            : _w(
                '$count ${count == 1 ? 'notification' : 'notifications'} marked as read.',
                '$count ${count == 1 ? 'alert' : 'alerts'} marked as read.',
              ),
      );
    } catch (_) {
      _message(
        _w(
          'Could not mark all notifications as read. Please try again.',
          'Could not mark your alerts as read. Try again.',
        ),
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
      _message(_w('Notification marked as read.', 'Alert marked as read.'));
    } catch (_) {
      _message(
        _w(
          'Could not mark this notification as read. Please try again.',
          'Could not mark this alert as read. Try again.',
        ),
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
        title: Text(_w('Remove notification?', 'Remove this alert?')),
        content: Text(
          _w(
            'Remove “${_text(row['title'], 'Notification')}” from your notifications. This removes the notification only.',
            'Remove “${_text(row['title'], 'Alert')}” from your alerts. This does not change any job or report.',
          ),
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
      _message(_w('Notification removed.', 'Alert removed.'));
    } catch (_) {
      _message(
        _w(
          'Could not remove this notification. Please try again.',
          'Could not remove this alert. Try again.',
        ),
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

  Widget _row(Map<String, dynamic> row) {
    final theme = Theme.of(context);
    final title = _text(row['title'], 'Notification');
    final body = _text(row['body'], 'No additional details.');
    final isRead = row['is_read'] == true;
    final working = _working.contains(row['id']);
    final enabled = !working && !_markingAll;
    final destination = notificationDestination(row, widget.role);
    final date = _date(row);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final unreadForeground = dark ? AppColors.linkDark : AppColors.accent;
    final time = date == null
        ? 'Time unavailable'
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(date),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          );
    // Opening a destination marks the alert read first; an alert without one
    // is simply marked read, and an already-read one has nothing to do.
    final VoidCallback? act = !enabled
        ? null
        : destination != null
        ? () => _open(row, destination)
        : !isRead && row['id'] is String
        ? () => _markRead(row)
        : null;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          key: const Key('notification-panel'),
          color: isRead
              ? Colors.transparent
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: .06),
                  scheme.surface,
                ),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: act,
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => scheme.primary.withValues(
                alpha: states.contains(WidgetState.focused)
                    ? .12
                    : states.contains(WidgetState.pressed)
                    ? .08
                    : states.contains(WidgetState.hovered)
                    ? .04
                    : 0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerTheme.color ?? scheme.outlineVariant,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color:
                                      (isRead
                                              ? scheme.onSurfaceVariant
                                              : unreadForeground)
                                          .withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  size: 24,
                                  color: isRead
                                      ? scheme.onSurfaceVariant
                                      : unreadForeground,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Positioned(
                                right: -3,
                                top: -3,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: unreadForeground,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: scheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Semantics(
                          button: act != null,
                          hint: act == null
                              ? null
                              : destination?.label ?? 'Mark as read',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                children: [
                                  Text(
                                    isRead ? 'Read,' : 'Unread,',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isRead
                                          ? scheme.onSurfaceVariant
                                          : unreadForeground,
                                      fontWeight: isRead
                                          ? null
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  Text(time, style: theme.textTheme.bodySmall),
                                ],
                              ),
                              if (working) ...[
                                const SizedBox(height: 12),
                                const LinearProgressIndicator(
                                  semanticsLabel: 'Updating notification',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_crew && destination != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: ExcludeSemantics(
                            child: Icon(Icons.chevron_right, size: 24),
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
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(
                              _w('Remove notification', 'Remove alert'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
        title: Text(
          widget.role == UserRole.citizen || _crew ? 'Alerts' : 'Notifications',
        ),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        actions: [
          IconButton(
            tooltip: _w('Reload notifications', 'Reload alerts'),
            onPressed: busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: widget.role != UserRole.citizen,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SlidingSwitch(
                        selectedIndex: _unreadOnly ? 1 : 0,
                        onChanged: (index) =>
                            setState(() => _unreadOnly = index == 1),
                        options: [
                          const SlidingSwitchOption(label: 'All'),
                          SlidingSwitchOption(
                            label: 'Unread',
                            semanticsLabel: rows == null
                                ? 'Unread'
                                : 'Unread, $unread',
                            badge: rows == null
                                ? null
                                : SwitchCountBadge('$unread'),
                          ),
                        ],
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
                      if (_markingAll ||
                          _refreshing ||
                          (state.isLoading && rows != null)) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          semanticsLabel: _markingAll
                              ? 'Marking notifications as read'
                              : 'Reloading notifications',
                        ),
                      ],
                      if (state.hasError && rows != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _w(
                            'Updates are unavailable. Showing the last loaded notifications.',
                            'Updates are unavailable. Showing the last loaded alerts.',
                          ),
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
                          title: _w(
                            'Notifications unavailable',
                            'Alerts unavailable',
                          ),
                          message: _w(
                            'We could not load your updates. Reload them to try again.',
                            'Check your signal and try again.',
                          ),
                          icon: Icons.notifications_off_outlined,
                          actionLabel: _w(
                            'Reload notifications',
                            'Reload alerts',
                          ),
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
                        : _w('No notifications yet', 'No alerts yet'),
                    message: _unreadOnly
                        ? _w(
                            'There are no unread updates in your notifications.',
                            'There are no unread alerts.',
                          )
                        : _w(
                            'Report and account updates will appear here.',
                            'New jobs and report updates appear here.',
                          ),
                    icon: Icons.notifications_none,
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    4,
                    0,
                    4,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  sliver: SliverList.list(
                    children: [
                      for (final (index, group) in groups.entries.indexed) ...[
                        ReportGroupHeader(
                          label: group.key,
                          first: index == 0,
                          trailing: index == 0 && unread > 0
                              ? TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onPressed:
                                      !busy &&
                                          !state.hasError &&
                                          !state.isLoading
                                      ? _markAll
                                      : null,
                                  child: const Text('Mark all as read'),
                                )
                              : null,
                        ),
                        ...group.value.map(_row),
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
