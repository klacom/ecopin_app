import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import '../controllers/fc_sync_ui_providers.dart';

class FcSyncStatusBar extends ConsumerWidget {
  const FcSyncStatusBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fcSyncStateProvider);
    final queue = ref.watch(fcPendingSummaryProvider);
    final network = ref.watch(fcSyncNetworkProvider);
    final settings = ref.watch(fcSyncSettingsProvider);
    ref.listen<FcSyncState>(fcSyncStateProvider, (previous, next) {
      if (previous?.phase == FcSyncPhase.syncing &&
          next.phase != FcSyncPhase.syncing) {
        ref.invalidate(fcPendingSummaryProvider);
      }
    });
    final count = queue.hasValue
        ? queue.value!.mutationCount +
              queue.value!.photoCount +
              queue.value!.pendingDeleteCount
        : null;
    final offline = network.value == FcNetworkType.none;
    final label = state.phase == FcSyncPhase.syncing
        ? 'Sending your work'
        : state.phase == FcSyncPhase.error ||
              state.phase == FcSyncPhase.partialFailure
        ? 'Some work did not send'
        : queue.hasError
        ? 'Could not check your saved work'
        : queue.isLoading
        ? 'Checking your saved work'
        : count == 0
        ? offline
              ? 'No signal. Nothing is waiting to send'
              : 'All your work is sent'
        : offline
        ? 'No signal. $count ${count == 1 ? 'item is' : 'items are'} saved on this phone'
        : '$count ${count == 1 ? 'item' : 'items'} waiting to send';
    final connection = network.hasError
        ? 'Connection unavailable'
        : network.isLoading
        ? 'Checking connection'
        : switch (network.value) {
            FcNetworkType.wifi => 'Wi-Fi',
            FcNetworkType.mobile => 'Mobile data',
            _ => 'No Wi-Fi or mobile connection',
          };
    final blocked =
        settings.syncBlocked ||
        network.value == FcNetworkType.none ||
        (network.value == FcNetworkType.wifi && !settings.syncOverWifi) ||
        (network.value == FcNetworkType.mobile && !settings.syncOverMobileData);
    final attention =
        state.phase == FcSyncPhase.error ||
        state.phase == FcSyncPhase.partialFailure ||
        queue.hasError;
    final description =
        '$label. $connection · ${settings.mode.title}'
        '${state.resultMessage == null ? '' : '. ${state.resultMessage}'}'
        '${blocked ? '. ${fcSyncPolicy(settings, network.hasError ? null : network.value)}' : ''}'
        '${queue.hasError && count != null ? '. Last loaded count: $count' : ''}';
    final theme = Theme.of(context);
    final status = theme.extension<AppStatusColors>();
    final waiting = (count ?? 0) > 0;
    // Color supports the written state; it never carries it alone.
    final tone = attention
        ? status?.error ?? theme.colorScheme.error
        : offline || (blocked && waiting)
        ? status?.warning ?? theme.colorScheme.onSurface
        : count == 0 && state.phase != FcSyncPhase.syncing
        ? status?.success ?? theme.colorScheme.onSurface
        : theme.brightness == Brightness.dark
        ? AppColors.linkDark
        : AppColors.accent;
    final icon = attention
        ? Icons.sync_problem
        : state.phase == FcSyncPhase.syncing || waiting
        ? offline
              ? Icons.cloud_off_outlined
              : Icons.sync
        : offline
        ? Icons.cloud_off_outlined
        : count == 0
        ? Icons.cloud_done_outlined
        : Icons.cloud_outlined;
    void open() => context.push(FieldCrewAppRoutes.syncCenter);
    return Semantics(
      label: 'Open sending details. $description',
      button: true,
      onTap: open,
      child: Tooltip(
        message: 'Open sending details\n$description',
        child: ExcludeSemantics(
          child: Material(
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              side: BorderSide(
                color: attention
                    ? tone
                    : theme.dividerTheme.color ?? theme.dividerColor,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              onTap: open,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _SyncPulse(
                        active: waiting || state.phase == FcSyncPhase.syncing,
                        child: Icon(icon, color: tone, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              connection,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
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
}

class _SyncPulse extends StatefulWidget {
  const _SyncPulse({required this.active, required this.child});
  final bool active;
  final Widget child;
  @override
  State<_SyncPulse> createState() => _SyncPulseState();
}

class _SyncPulseState extends State<_SyncPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  void _update() {
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(covariant _SyncPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 1, end: .45).animate(_controller),
    child: widget.child,
  );
}
