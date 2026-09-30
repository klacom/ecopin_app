import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/routes/app_routes.dart';

/// Compact sync status bar shown at the top of the Field Crew dashboard.
///
/// Shows one of:
///   • Nothing — when synced and no pending work
///   • "● N pending" amber chip — when there are pending items
///   • Spinning indicator + "Syncing…" — when a run is active
///   • "⚠ Sync issues" red chip — when the last run had retryable/conflict
///   • "✓ Synced" green chip — briefly after a successful run (4 s)
///
/// Tapping navigates to the Sync Center screen.
class FcSyncStatusBar extends ConsumerStatefulWidget {
  const FcSyncStatusBar({super.key});

  @override
  ConsumerState<FcSyncStatusBar> createState() => _FcSyncStatusBarState();
}

class _FcSyncStatusBarState extends ConsumerState<FcSyncStatusBar> {
  FcPendingSummary? _summary;
  bool _showSuccessBadge = false;
  DateTime? _lastSuccessAt;

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

    // Watch for sync completions to refresh summary and show brief success badge.
    ref.listen<FcSyncState>(fcSyncStateProvider, (prev, next) {
      if (prev?.phase == FcSyncPhase.syncing &&
          next.phase == FcSyncPhase.success) {
        setState(() {
          _showSuccessBadge = true;
          _lastSuccessAt    = DateTime.now();
        });
        // Auto-hide after 4 seconds.
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted &&
              _lastSuccessAt != null &&
              DateTime.now().difference(_lastSuccessAt!) >=
                  const Duration(seconds: 4)) {
            setState(() => _showSuccessBadge = false);
          }
        });
        _refreshSummary();
      } else if (prev?.phase == FcSyncPhase.syncing &&
          next.phase != FcSyncPhase.syncing) {
        _refreshSummary();
      }
    });

    final phase = syncState.phase;

    // Determine what to show.
    final Widget? chip = _buildChip(phase, syncState);
    if (chip == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push(FieldCrewAppRoutes.syncCenter),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppColors.spaceMD),
        child: chip,
      ),
    );
  }

  Widget? _buildChip(FcSyncPhase phase, FcSyncState syncState) {
    // Syncing spinner.
    if (phase == FcSyncPhase.syncing) {
      return _StatusChip(
        leading: const SizedBox(
          width: 12, height: 12,
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: AppColors.backgroundDark),
        ),
        label:   'Syncing…',
        bgColor: AppColors.primaryDark,
        textColor: AppColors.backgroundDark,
      );
    }

    // Error / partial failure.
    if (phase == FcSyncPhase.error ||
        (phase == FcSyncPhase.partialFailure &&
            ((syncState.lastMutationResult?.retryable ?? 0) > 0 ||
             (syncState.lastMutationResult?.conflicted ?? 0) > 0))) {
      return _StatusChip(
        leading: const Icon(Icons.warning_amber_rounded,
            size: 12, color: Colors.white),
        label:   'Sync issues',
        bgColor: AppColors.error,
        textColor: Colors.white,
      );
    }

    // Brief success badge.
    if (_showSuccessBadge &&
        phase == FcSyncPhase.success &&
        (_summary == null || _summary!.isEmpty)) {
      return _StatusChip(
        leading: const Icon(Icons.check, size: 12,
            color: AppColors.backgroundDark),
        label:   'Synced',
        bgColor: AppColors.success,
        textColor: AppColors.backgroundDark,
      );
    }

    // Pending indicator.
    if (_summary != null && !_summary!.isEmpty) {
      final total = _summary!.mutationCount + _summary!.photoCount;
      return _StatusChip(
        leading: Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(
              color: AppColors.backgroundDark, shape: BoxShape.circle),
        ),
        label:   '$total pending',
        bgColor: AppColors.warning,
        textColor: AppColors.backgroundDark,
      );
    }

    return null;
  }
}

class _StatusChip extends StatelessWidget {
  final Widget leading;
  final String label;
  final Color bgColor;
  final Color textColor;

  const _StatusChip({
    required this.leading,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spaceMD, vertical: 7),
        decoration: BoxDecoration(
          color:        bgColor,
          borderRadius: BorderRadius.circular(AppColors.radiusButton),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Text(label,
                style: AppTypography.caption.copyWith(
                    color:      textColor,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
