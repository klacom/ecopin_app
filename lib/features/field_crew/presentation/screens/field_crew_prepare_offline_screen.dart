import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_notifier.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Prepare Offline Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Lets Field Crew download their assigned work package before going offline.
///
/// Layout:
///   1. Header card — explains what will be downloaded and why
///   2. Storage estimate chip
///   3. Step-by-step progress list (shown while downloading)
///   4. Summary card (shown when ready)
///   5. "Prepare for Field" / "Re-prepare" button
///   6. Mode recommendation — suggests switching to "Offline Only" after prep
class FieldCrewPrepareOfflineScreen extends ConsumerWidget {
  const FieldCrewPrepareOfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pkgState = ref.watch(fcOfflinePackageNotifierProvider);
    final settings  = ref.watch(fcSyncSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text('Prepare Offline Work',
            style: AppTypography.h5
                .copyWith(color: AppColors.textPrimaryDark)),
        iconTheme:
            const IconThemeData(color: AppColors.textPrimaryDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColors.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ───────────────────────────────────────────────
            _InfoCard(),
            const SizedBox(height: AppColors.spaceLG),

            // ── Storage estimate ──────────────────────────────────────────
            if (pkgState.estimatedBytes > 0 && !pkgState.isReady)
              _EstimateChip(bytes: pkgState.estimatedBytes),
            if (pkgState.estimatedBytes > 0 && !pkgState.isReady)
              const SizedBox(height: AppColors.spaceLG),

            // ── Progress steps ────────────────────────────────────────────
            if (pkgState.isDownloading || pkgState.steps.isNotEmpty) ...[
              _StepsCard(steps: pkgState.steps),
              const SizedBox(height: AppColors.spaceLG),
            ],

            // ── Ready summary ─────────────────────────────────────────────
            if (pkgState.isReady) ...[
              _ReadySummaryCard(pkgState: pkgState),
              const SizedBox(height: AppColors.spaceLG),

              // Recommend switching to Offline Only if not already set.
              if (settings.mode != FcSyncMode.offlineOnly)
                _ModeRecommendation(
                  onEnable: () => ref
                      .read(fcSyncSettingsProvider.notifier)
                      .setMode(FcSyncMode.offlineOnly),
                ),
              if (settings.mode != FcSyncMode.offlineOnly)
                const SizedBox(height: AppColors.spaceLG),
            ],

            // ── Error message ─────────────────────────────────────────────
            if (pkgState.errorMessage != null) ...[
              _ErrorBanner(message: pkgState.errorMessage!),
              const SizedBox(height: AppColors.spaceLG),
            ],

            // ── Action button ─────────────────────────────────────────────
            _ActionButton(
              pkgState: pkgState,
              onPrepare: () =>
                  ref.read(fcOfflinePackageNotifierProvider.notifier).prepare(),
              onReset:   () =>
                  ref.read(fcOfflinePackageNotifierProvider.notifier).reset(),
            ),
            const SizedBox(height: AppColors.spaceXL),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Card
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.download_for_offline,
                  color: AppColors.primaryDark, size: 20),
              const SizedBox(width: AppColors.spaceSM),
              Text('Offline Work Package',
                  style: AppTypography.label.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: AppColors.spaceSM),
            Text(
              'Downloads your assigned tasks, reports, evidence, and notes so '
              'you can work without internet access in the field.',
              style: AppTypography.bodySmall.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: AppColors.spaceMD),
            _BulletRow('Assigned cleanup tasks'),
            _BulletRow('All linked reports and details'),
            _BulletRow('Citizen evidence metadata'),
            _BulletRow('Field notes and reference data'),
          ],
        ),
      );
}

class _BulletRow extends StatelessWidget {
  final String text;
  const _BulletRow(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: AppColors.primaryDark, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textPrimaryDark)),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Storage estimate
// ─────────────────────────────────────────────────────────────────────────────

class _EstimateChip extends StatelessWidget {
  final int bytes;
  const _EstimateChip({required this.bytes});

  String _fmt(int b) {
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) => Row(children: [
        const Icon(Icons.storage, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text('Estimated storage: ',
            style: AppTypography.caption.copyWith(color: Colors.grey)),
        Text(_fmt(bytes),
            style: AppTypography.caption.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text('(approximate)',
            style: AppTypography.caption.copyWith(color: Colors.grey)),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Steps card
// ─────────────────────────────────────────────────────────────────────────────

class _StepsCard extends StatelessWidget {
  final List<FcDownloadStep> steps;
  const _StepsCard({required this.steps});

  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('DOWNLOAD PROGRESS'),
            const SizedBox(height: AppColors.spaceMD),
            ...steps.map((s) => _StepRow(step: s)),
          ],
        ),
      );
}

class _StepRow extends StatelessWidget {
  final FcDownloadStep step;
  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    final Widget icon;
    final Color textColor;

    if (step.completed && step.error == null) {
      icon = const Icon(Icons.check_circle, size: 16, color: AppColors.success);
      textColor = AppColors.textPrimaryDark;
    } else if (step.completed && step.error != null) {
      icon = const Icon(Icons.warning_amber_rounded,
          size: 16, color: AppColors.warning);
      textColor = AppColors.textPrimaryDark;
    } else if (step.inProgress) {
      icon = const SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.primaryDark),
      );
      textColor = AppColors.primaryDark;
    } else {
      icon = const Icon(Icons.radio_button_unchecked,
          size: 16, color: Colors.grey);
      textColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.label,
                    style: AppTypography.label.copyWith(color: textColor)),
                if (step.error != null)
                  Text(step.error!,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.warning)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ready summary
// ─────────────────────────────────────────────────────────────────────────────

class _ReadySummaryCard extends StatelessWidget {
  final FcOfflinePackageState pkgState;
  const _ReadySummaryCard({required this.pkgState});

  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text('Ready for Offline Work ✓',
                  style: AppTypography.label.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: AppColors.spaceMD),
            _SummaryRow(Icons.handyman, '${pkgState.taskCount} tasks cached'),
            _SummaryRow(Icons.description, '${pkgState.reportCount} reports cached'),
            _SummaryRow(Icons.photo_library, '${pkgState.evidenceCount} evidence items cached'),
            _SummaryRow(Icons.notes, '${pkgState.noteCount} notes cached'),
            if (pkgState.preparedAt != null) ...[
              const SizedBox(height: AppColors.spaceSM),
              const Divider(color: AppColors.dividerDark),
              const SizedBox(height: AppColors.spaceSM),
              Row(children: [
                const Icon(Icons.schedule, size: 12, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Prepared ${DateFormat.jm().format(pkgState.preparedAt!)} '
                  'on ${DateFormat.MMMd().format(pkgState.preparedAt!)}',
                  style: AppTypography.caption.copyWith(color: Colors.grey),
                ),
              ]),
            ],
          ],
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SummaryRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textPrimaryDark)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode recommendation
// ─────────────────────────────────────────────────────────────────────────────

class _ModeRecommendation extends StatelessWidget {
  final VoidCallback onEnable;
  const _ModeRecommendation({required this.onEnable});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        decoration: BoxDecoration(
          color:        AppColors.primaryDark.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          border:       Border.all(
              color: AppColors.primaryDark.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.tips_and_updates,
                  color: AppColors.primaryDark, size: 16),
              const SizedBox(width: 6),
              Text('Recommended',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ]),
            const SizedBox(height: AppColors.spaceSM),
            Text(
              'Switch to Offline Only mode to prevent the app from making '
              'unexpected network calls while in the field.',
              style: AppTypography.bodySmall.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: AppColors.spaceMD),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onEnable,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryDark),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusButton)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Enable Offline Only',
                    style: AppTypography.button.copyWith(
                        color: AppColors.primaryDark)),
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        decoration: BoxDecoration(
          color:        AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          border:       Border.all(color: AppColors.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textPrimaryDark)),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final FcOfflinePackageState pkgState;
  final VoidCallback onPrepare;
  final VoidCallback onReset;

  const _ActionButton({
    required this.pkgState,
    required this.onPrepare,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = pkgState.isDownloading;
    final isReady       = pkgState.isReady;
    final isFailed      = pkgState.phase == FcOfflinePackagePhase.failed;

    String label;
    VoidCallback? onTap;
    if (isDownloading) {
      label = 'Preparing…';
      onTap = null; // disabled
    } else if (isReady) {
      label = 'Re-prepare';
      onTap = onReset; // let user reset and re-download
    } else if (isFailed) {
      label = 'Retry';
      onTap = () { onReset(); onPrepare(); };
    } else {
      label = 'Prepare for Field';
      onTap = onPrepare;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:        AppColors.primaryDark,
          disabledBackgroundColor: AppColors.dividerDark,
          foregroundColor:         AppColors.backgroundDark,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusButton)),
        ),
        child: isDownloading
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.backgroundDark)),
                const SizedBox(width: 10),
                Text(label,
                    style: AppTypography.button
                        .copyWith(color: AppColors.backgroundDark)),
              ])
            : Text(label,
                style: AppTypography.button.copyWith(
                    color: onTap != null
                        ? AppColors.backgroundDark
                        : Colors.grey)),
      ),
    );
  }
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
