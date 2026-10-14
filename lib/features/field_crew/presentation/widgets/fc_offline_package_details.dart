import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package.dart';
import 'fc_offline_ui.dart';

class FcOfflinePackageDetails extends StatelessWidget {
  const FcOfflinePackageDetails({super.key, required this.state});
  final FcOfflinePackageState state;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final warnings = state.steps.where((step) => step.error != null).length;
    final verified =
        state.steps.isNotEmpty &&
        state.steps.every((step) => step.completed && step.error == null);
    final heading = state.isDownloading
        ? 'Preparing assigned work'
        : state.isReady
        ? warnings > 0
              ? 'Prepared with gaps'
              : verified
              ? 'Offline data prepared'
              : 'Previously cached work'
        : state.phase == FcOfflinePackagePhase.failed
        ? 'Preparation needs another attempt'
        : 'Ready to prepare';
    return FcOfflineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(heading, style: text.titleMedium),
          ),
          if (state.isDownloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              semanticsLabel: state.phase == FcOfflinePackagePhase.estimating
                  ? 'Estimating storage'
                  : 'Downloading assigned work',
            ),
          ],
          if (warnings > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '$warnings preparation ${warnings == 1 ? 'section needs' : 'sections need'} another attempt. Cached records may be incomplete. Reconnect and update the package.',
                style: text.bodyMedium,
              ),
            ),
          if (state.isReady && !verified && warnings == 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'This is an earlier preparation receipt. Update the package online to check each section and current assignments.',
                style: text.bodyMedium,
              ),
            ),
          if (state.estimatedBytes > 0)
            FcOfflineFact(
              'Estimated record storage',
              '${state.formattedEstimate} (approximate; excludes full-size photos and map tiles)',
            ),
          if (state.steps.isNotEmpty) ...[
            const Divider(height: 32),
            for (final step in state.steps) _DownloadStep(step: step),
          ],
          if (state.isReady ||
              state.taskCount +
                      state.reportCount +
                      state.evidenceCount +
                      state.noteCount >
                  0) ...[
            const Divider(height: 32),
            FcOfflineFact('Tasks cached', '${state.taskCount}'),
            FcOfflineFact('Reports cached', '${state.reportCount}'),
            FcOfflineFact(
              'Evidence metadata records cached',
              '${state.evidenceCount}',
            ),
            FcOfflineFact('Notes cached', '${state.noteCount}'),
          ],
          if (state.preparedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Preparation recorded: ${fcLocalTime(state.preparedAt!)}',
                style: text.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _DownloadStep extends StatelessWidget {
  const _DownloadStep({required this.step});
  final FcDownloadStep step;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context),
        status = Theme.of(context).extension<AppStatusColors>();
    final label = step.error != null
        ? 'Needs another attempt'
        : step.completed
        ? step.label == FcOfflineStepLabel.issueTypes
              ? 'Reference service checked'
              : 'Downloaded'
        : step.inProgress
        ? 'Downloading'
        : 'Waiting';
    final color = step.error != null
        ? status?.warning ?? theme.colorScheme.error
        : step.completed
        ? status?.success ?? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              step.error != null
                  ? Icons.warning_amber_rounded
                  : step.completed
                  ? Icons.check_circle_outline
                  : step.inProgress
                  ? Icons.downloading
                  : Icons.schedule,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(step.label, style: theme.textTheme.titleSmall),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
                if (step.error != null)
                  Text(step.error!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
