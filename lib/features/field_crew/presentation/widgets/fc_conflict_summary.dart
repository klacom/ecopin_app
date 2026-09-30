import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_result.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';

/// Displays a concise, dismissible banner when a sync run produced merged
/// or conflicted operations.
///
/// Designed to be shown inside a [Column] at the top of a scrollable screen
/// (e.g. the Field Crew dashboard or report detail) — not as a modal or
/// blocking dialog.  Field crew users never need to take action; the banner
/// is purely informational.
///
/// **Visibility rule:**
///   - Shown only when [FcSyncPhase] is `partialFailure` or `success` AND
///     there is at least one [FcConflictEvent] in the last mutation result.
///   - Auto-hides after [_kAutoDismissDuration] or when the user taps ×.
///   - Does not re-appear for the same sync run after dismissal.
class FcConflictSummary extends ConsumerStatefulWidget {
  const FcConflictSummary({super.key});

  @override
  ConsumerState<FcConflictSummary> createState() => _FcConflictSummaryState();
}

class _FcConflictSummaryState extends ConsumerState<FcConflictSummary> {
  static const Duration _kAutoDismissDuration = Duration(seconds: 12);

  /// The lastSyncAt timestamp of the run we already showed a banner for.
  /// Used to prevent the same banner appearing again on rebuild.
  DateTime? _shownForSync;
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(fcSyncStateProvider);
    final mutationResult = syncState.lastMutationResult;
    final syncAt = syncState.lastSyncAt;

    // Nothing to show yet.
    if (mutationResult == null || syncAt == null) return const SizedBox.shrink();

    // Auto-dismiss check: new sync run resets dismissal.
    if (_shownForSync != syncAt) {
      _dismissed = false;
      _shownForSync = syncAt;

      // Schedule auto-dismiss.
      Future<void>.delayed(_kAutoDismissDuration, () {
        if (mounted && !_dismissed) {
          setState(() => _dismissed = true);
        }
      });
    }

    if (_dismissed) return const SizedBox.shrink();

    final events = mutationResult.conflictEvents;
    if (events.isEmpty) return const SizedBox.shrink();

    return _ConflictBanner(
      events: events,
      onDismiss: () => setState(() => _dismissed = true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner widget
// ─────────────────────────────────────────────────────────────────────────────

class _ConflictBanner extends StatelessWidget {
  final List<FcConflictEvent> events;
  final VoidCallback onDismiss;

  const _ConflictBanner({required this.events, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final mergedCount =
        events.where((e) => e.status == FcOpStatus.merged).length;
    final conflictCount =
        events.where((e) => e.status == FcOpStatus.conflict).length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppColors.spaceMD),
      padding: const EdgeInsets.symmetric(
          horizontal: AppColors.spaceMD, vertical: AppColors.spaceSM),
      decoration: BoxDecoration(
        color: _bannerColor(mergedCount, conflictCount),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(
          color: _borderColor(mergedCount, conflictCount),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                conflictCount > 0
                    ? Icons.warning_amber_rounded
                    : Icons.merge_type,
                size: 16,
                color: _iconColor(mergedCount, conflictCount),
              ),
              const SizedBox(width: AppColors.spaceSM),
              Expanded(
                child: Text(
                  _headlineText(mergedCount, conflictCount),
                  style: AppTypography.label.copyWith(
                    color: _iconColor(mergedCount, conflictCount),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: _iconColor(mergedCount, conflictCount)
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          // Show individual event messages only when there are ≤3 events,
          // to keep the banner compact. Above that, just show the headline.
          if (events.length <= 3) ...[
            const SizedBox(height: AppColors.spaceSM),
            ...events.map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontSize: 11, color: Colors.white70)),
                    Expanded(
                      child: Text(
                        e.message,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _headlineText(int merged, int conflict) {
    final parts = <String>[];
    if (merged > 0) {
      parts.add('$merged change${merged > 1 ? 's' : ''} merged');
    }
    if (conflict > 0) {
      parts.add(
          '$conflict change${conflict > 1 ? 's' : ''} not applied '
          '(another crew member\'s update was accepted first)');
    }
    return parts.join(' · ');
  }

  Color _bannerColor(int merged, int conflict) {
    if (conflict > 0) return AppColors.error.withValues(alpha: 0.15);
    return AppColors.warning.withValues(alpha: 0.15);
  }

  Color _borderColor(int merged, int conflict) {
    if (conflict > 0) return AppColors.error.withValues(alpha: 0.5);
    return AppColors.warning.withValues(alpha: 0.5);
  }

  Color _iconColor(int merged, int conflict) {
    if (conflict > 0) return AppColors.error;
    return AppColors.warning;
  }
}
