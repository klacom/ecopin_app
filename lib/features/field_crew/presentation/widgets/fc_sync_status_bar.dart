import 'package:flutter/material.dart';
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
    final label = state.phase == FcSyncPhase.syncing
        ? 'Syncing queued work'
        : state.phase == FcSyncPhase.error ||
              state.phase == FcSyncPhase.partialFailure
        ? 'Sync needs attention'
        : queue.hasError
        ? 'Queue could not be checked'
        : queue.isLoading
        ? 'Checking local queue'
        : count == 0
        ? 'No queued crew work'
        : '$count ${count == 1 ? 'item' : 'items'} waiting to sync';
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
    return Semantics(
      label: 'Open Sync Center. $description',
      button: true,
      onTap: () => context.push(FieldCrewAppRoutes.syncCenter),
      child: Tooltip(
        message: 'Open Sync Center\n$description',
        child: ExcludeSemantics(
          child: IconButton(
            onPressed: () => context.push(FieldCrewAppRoutes.syncCenter),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            color: attention
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).brightness == Brightness.dark
                ? AppColors.linkDark
                : AppColors.accent,
            icon: _SyncPulse(
              active: (count ?? 0) > 0 || state.phase == FcSyncPhase.syncing,
              child: Icon(
                attention
                    ? Icons.sync_problem
                    : state.phase == FcSyncPhase.syncing || (count ?? 0) > 0
                    ? Icons.sync
                    : count == 0
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_outlined,
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
