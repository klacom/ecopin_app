import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_result.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal provider for current network type
// ─────────────────────────────────────────────────────────────────────────────

final _currentNetworkTypeProvider =
    FutureProvider.autoDispose<FcNetworkType>((ref) async {
  final results = await Connectivity().checkConnectivity();
  if (results.contains(ConnectivityResult.wifi))   return FcNetworkType.wifi;
  if (results.contains(ConnectivityResult.mobile)) return FcNetworkType.mobile;
  return FcNetworkType.none;
});

// ─────────────────────────────────────────────────────────────────────────────
// Sync Center Screen
// ─────────────────────────────────────────────────────────────────────────────

class FieldCrewSyncCenterScreen extends ConsumerStatefulWidget {
  const FieldCrewSyncCenterScreen({super.key});

  @override
  ConsumerState<FieldCrewSyncCenterScreen> createState() =>
      _FieldCrewSyncCenterScreenState();
}

class _FieldCrewSyncCenterScreenState
    extends ConsumerState<FieldCrewSyncCenterScreen> {
  FcPendingSummary? _summary;

  @override
  void initState() {
    super.initState();
    _refreshSummary();
  }

  Future<void> _refreshSummary() async {
    final gate    = ref.read(fcSyncGateProvider);
    final summary = await gate.getPendingSummary();
    if (mounted) setState(() => _summary = summary);
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(fcSyncStateProvider);
    final settings  = ref.watch(fcSyncSettingsProvider);
    final networkAsync = ref.watch(_currentNetworkTypeProvider);
    final isSyncing = syncState.phase == FcSyncPhase.syncing;

    // Refresh summary after each sync completes.
    ref.listen<FcSyncState>(fcSyncStateProvider, (prev, next) {
      if (prev?.phase == FcSyncPhase.syncing &&
          next.phase != FcSyncPhase.syncing) {
        _refreshSummary();
      }
    });

    final networkType =
        networkAsync.asData?.value ?? FcNetworkType.none;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text('Sync Center',
            style: AppTypography.h5
                .copyWith(color: AppColors.textPrimaryDark)),
        iconTheme:
            const IconThemeData(color: AppColors.textPrimaryDark),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSummary,
        color: AppColors.primaryDark,
        backgroundColor: AppColors.surfaceDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppColors.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusCard(
                syncState:   syncState,
                summary:     _summary,
                networkType: networkType,
              ),
              const SizedBox(height: AppColors.spaceLG),

              if (settings.mode != FcSyncMode.automatic) ...[
                _CommitButton(
                  isSyncing: isSyncing,
                  summary:   _summary,
                  onCommit:  () => _handleCommit(context),
                ),
                const SizedBox(height: AppColors.spaceLG),
              ],

              if (syncState.lastMutationResult != null) ...[
                _LastRunCard(result: syncState.lastMutationResult!),
                const SizedBox(height: AppColors.spaceLG),
              ],

              _SectionLabel('SYNC MODE'),
              const SizedBox(height: AppColors.spaceSM),
              _SyncModeSelector(current: settings.mode),
              const SizedBox(height: AppColors.spaceLG),

              _SectionLabel('DATA SETTINGS'),
              const SizedBox(height: AppColors.spaceSM),
              _DataSettingsCard(settings: settings),
              const SizedBox(height: AppColors.spaceXL),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCommit(BuildContext context) async {
    final gate    = ref.read(fcSyncGateProvider);
    final trigger = ref.read(fcSyncTriggerProvider);
    final decision = await gate.checkManualCommit();

    if (!decision.allowed) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(decision.reason ?? 'Cannot sync right now'),
          backgroundColor: AppColors.error,
        ));
      }
      return;
    }

    if (decision.requiresConfirmation && context.mounted) {
      final confirmed = await _showMobileDataDialog(context);
      if (!confirmed) return;
    }

    await trigger.manualCommit();
    if (mounted) _refreshSummary();
  }

  Future<bool> _showMobileDataDialog(BuildContext context) async {
    final summary = _summary;
    final result  = await showDialog<bool>(
      context:          context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusCard)),
        title: Text('Commit over Mobile Data?',
            style: AppTypography.h6
                .copyWith(color: AppColors.textPrimaryDark)),
        content: Column(
          mainAxisSize:        MainAxisSize.min,
          crossAxisAlignment:  CrossAxisAlignment.start,
          children: [
            if (summary != null && !summary.isEmpty)
              Text(summary.summaryLine,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textPrimaryDark)),
            const SizedBox(height: AppColors.spaceSM),
            Text(
              "You're on mobile data. Uploading may use significant data.",
              style: AppTypography.bodySmall.copyWith(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Commit Anyway',
                style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Card
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final FcSyncState      syncState;
  final FcPendingSummary? summary;
  final FcNetworkType    networkType;

  const _StatusCard({
    required this.syncState,
    required this.summary,
    required this.networkType,
  });

  @override
  Widget build(BuildContext context) {
    final phase = syncState.phase;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _SectionLabel('SYNC STATUS'),
            const Spacer(),
            _PhaseIndicator(phase: phase),
          ]),
          const SizedBox(height: AppColors.spaceMD),

          if (summary != null && !summary!.isEmpty) ...[
            Text(
              '${summary!.mutationCount + summary!.photoCount} pending changes',
              style: AppTypography.h5
                  .copyWith(color: AppColors.textPrimaryDark),
            ),
            if (summary!.photoCount > 0 ||
                summary!.formattedSize.isNotEmpty)
              Text(
                [
                  if (summary!.photoCount > 0)
                    '${summary!.photoCount} ${summary!.photoCount == 1 ? "photo" : "photos"}',
                  if (summary!.formattedSize.isNotEmpty)
                    summary!.formattedSize,
                ].join(' · '),
                style: AppTypography.body.copyWith(color: Colors.grey),
              ),
          ] else
            Text('Nothing pending',
                style: AppTypography.h5.copyWith(
                    color:      AppColors.primaryDark,
                    fontWeight: FontWeight.w600)),

          const SizedBox(height: AppColors.spaceMD),
          const Divider(color: AppColors.dividerDark),
          const SizedBox(height: AppColors.spaceSM),

          _InfoRow(
            icon:  Icons.schedule,
            label: 'Last sync',
            value: syncState.lastSyncAt != null
                ? _formatTime(syncState.lastSyncAt!)
                : 'Never synced',
          ),
          const SizedBox(height: AppColors.spaceSM),
          _NetworkInfoRow(networkType: networkType),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(dt.year, dt.month, dt.day);
    final time  = DateFormat.jm().format(dt);
    if (d == today) return 'Today, $time';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday, $time';
    return '${DateFormat('MMM d').format(dt)}, $time';
  }
}

class _NetworkInfoRow extends StatelessWidget {
  final FcNetworkType networkType;
  const _NetworkInfoRow({required this.networkType});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (networkType) {
      FcNetworkType.wifi   => (Icons.wifi, 'Wi-Fi ✓',     AppColors.success),
      FcNetworkType.mobile => (Icons.signal_cellular_alt, 'Mobile Data', AppColors.warning),
      FcNetworkType.none   => (Icons.cloud_off, 'Offline',  Colors.grey),
    };
    return _InfoRow(icon: icon, label: 'Connection', value: label, valueColor: color);
  }
}

class _PhaseIndicator extends StatelessWidget {
  final FcSyncPhase phase;
  const _PhaseIndicator({required this.phase});

  @override
  Widget build(BuildContext context) => switch (phase) {
        FcSyncPhase.syncing => const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primaryDark)),
        FcSyncPhase.success => const Icon(Icons.check_circle,
            color: AppColors.success, size: 20),
        FcSyncPhase.error ||
        FcSyncPhase.partialFailure =>
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 20),
        _ => const SizedBox.shrink(),
      };
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label:  ',
            style: AppTypography.caption.copyWith(color: Colors.grey)),
        Flexible(
          child: Text(value,
              style: AppTypography.caption.copyWith(
                  color:      valueColor ?? AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w600)),
        ),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Commit Button
// ─────────────────────────────────────────────────────────────────────────────

class _CommitButton extends StatelessWidget {
  final bool isSyncing;
  final FcPendingSummary? summary;
  final VoidCallback onCommit;

  const _CommitButton({
    required this.isSyncing,
    required this.summary,
    required this.onCommit,
  });

  @override
  Widget build(BuildContext context) {
    final hasPending = summary != null && !summary!.isEmpty;
    final enabled    = hasPending && !isSyncing;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onCommit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:        AppColors.primaryDark,
          disabledBackgroundColor: AppColors.dividerDark,
          foregroundColor:         AppColors.backgroundDark,
          padding:      const EdgeInsets.symmetric(vertical: 16),
          shape:        RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusButton)),
        ),
        child: isSyncing
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.backgroundDark))
            : Text(
                hasPending ? 'Commit Changes' : 'Nothing to commit',
                style: AppTypography.button.copyWith(
                    color: enabled
                        ? AppColors.backgroundDark
                        : Colors.grey)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Last Run Card
// ─────────────────────────────────────────────────────────────────────────────

class _LastRunCard extends StatelessWidget {
  final FcSyncRunResult result;
  const _LastRunCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('LAST SYNC RESULT'),
          const SizedBox(height: AppColors.spaceMD),
          if (result.allSucceeded)
            Row(children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 16),
              const SizedBox(width: 6),
              Text('All changes synced',
                  style: AppTypography.body
                      .copyWith(color: AppColors.success)),
            ])
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.succeeded > 0)
                  _ResultRow(result.succeeded, 'synced',     AppColors.success),
                if (result.merged  > 0)
                  _ResultRow(result.merged,    'merged',     AppColors.info),
                if (result.retryable > 0)
                  _ResultRow(result.retryable, 'needs retry', AppColors.warning),
                if (result.conflicted > 0)
                  _ResultRow(result.conflicted, 'conflict',  AppColors.error),
              ],
            ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _ResultRow(this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('$count $label',
              style: AppTypography.body
                  .copyWith(color: AppColors.textPrimaryDark)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sync Mode Selector
// ─────────────────────────────────────────────────────────────────────────────

class _SyncModeSelector extends ConsumerWidget {
  final FcSyncMode current;
  const _SyncModeSelector({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
        children: FcSyncMode.values.map((mode) {
          final selected = mode == current;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppColors.spaceSM),
            child: InkWell(
              onTap: () =>
                  ref.read(fcSyncSettingsProvider.notifier).setMode(mode),
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              child: Container(
                padding: const EdgeInsets.all(AppColors.spaceMD),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryDark.withValues(alpha: 0.08)
                      : AppColors.surfaceDark,
                  borderRadius:
                      BorderRadius.circular(AppColors.radiusCard),
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.dividerDark,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mode.title,
                            style: AppTypography.label.copyWith(
                                color: selected
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimaryDark,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(mode.description,
                            style: AppTypography.caption
                                .copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle,
                        color: AppColors.primaryDark, size: 20),
                ]),
              ),
            ),
          );
        }).toList(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Settings Card
// ─────────────────────────────────────────────────────────────────────────────

class _DataSettingsCard extends ConsumerWidget {
  final FcSyncSettings settings;
  const _DataSettingsCard({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(fcSyncSettingsProvider.notifier);
    return _Card(
      child: Column(children: [
        _ToggleRow(
          title:    'Sync over Wi-Fi',
          value:    settings.syncOverWifi,
          onChanged: notifier.setSyncOverWifi,
        ),
        const Divider(color: AppColors.dividerDark, height: AppColors.spaceLG),
        _ToggleRow(
          title:    'Sync over Mobile Data',
          value:    settings.syncOverMobileData,
          onChanged: notifier.setSyncOverMobileData,
          subtitle: settings.syncOverMobileData
              ? 'Large photo uploads may use significant data.'
              : null,
        ),
      ]),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final bool value;
  final Future<void> Function(bool) onChanged;
  final String? subtitle;

  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(title,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textPrimaryDark)),
            ),
            Switch(
              value:              value,
              onChanged:          onChanged,
              activeColor:        AppColors.primaryDark,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: AppColors.dividerDark,
            ),
          ]),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle!,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.warning)),
            ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared primitives
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width:   double.infinity,
        padding: const EdgeInsets.all(AppColors.spaceMD),
        decoration: BoxDecoration(
          color:        AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          border:       Border.all(color: AppColors.dividerDark),
        ),
        child: child,
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTypography.caption
          .copyWith(color: Colors.grey, letterSpacing: 1.2));
}

