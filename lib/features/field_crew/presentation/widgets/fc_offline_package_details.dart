import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package.dart';
import '../controllers/fc_download_presentation.dart';
import 'fc_offline_ui.dart';

/// The body of “What is on this phone”: the counts that were actually saved,
/// the approximate space, and the names of the saved jobs and reports.
class FcDownloadContents extends StatelessWidget {
  const FcDownloadContents({super.key, required this.state});
  final FcOfflinePackageState state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hasAny =
        state.isReady ||
        state.taskCount +
                state.reportCount +
                state.evidenceCount +
                state.noteCount >
            0;
    if (!hasAny) {
      return Text(
        'Nothing is saved on this phone yet.',
        style: text.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FcOfflineFact('Jobs', '${state.taskCount}'),
        FcOfflineFact('Reports in your jobs', '${state.reportCount}'),
        FcOfflineFact('Photo and evidence details', '${state.evidenceCount}'),
        FcOfflineFact('Notes', '${state.noteCount}'),
        FcOfflineFact('Route', '${state.routeCount}'),
        if (state.estimatedBytes > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Space used is about ${state.formattedEstimate}, not counting full-size photos or the map.',
              style: text.bodySmall,
            ),
          ),
        if (state.taskTitles.isNotEmpty)
          _Names(heading: 'Your jobs', names: state.taskTitles),
        if (state.reportTitles.isNotEmpty)
          _Names(heading: 'Reports', names: state.reportTitles),
      ],
    );
  }
}

class _Names extends StatelessWidget {
  const _Names({required this.heading, required this.names});
  final String heading;
  final List<String> names;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: text.titleSmall),
          for (final name in names)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(name, style: text.bodyMedium),
            ),
        ],
      ),
    );
  }
}

/// The body of “Download steps”: each step by its plain name, with a written
/// state. A step that needs another try shows its reason.
class FcDownloadSteps extends StatelessWidget {
  const FcDownloadSteps({super.key, required this.state});
  final FcOfflinePackageState state;

  @override
  Widget build(BuildContext context) {
    if (state.steps.isEmpty) {
      return Text(
        state.isReady
            ? 'This download was saved earlier, so its steps were not checked. Download again to check them.'
            : 'The steps show here once a download starts.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final step in state.steps) _DownloadStep(step: step)],
    );
  }
}

class _DownloadStep extends StatelessWidget {
  const _DownloadStep({required this.step});
  final FcDownloadStep step;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.extension<AppStatusColors>();
    final color = step.error != null
        ? status?.warning ?? theme.colorScheme.error
        : step.completed
        ? status?.success ?? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                Text(fcStepName(step.label), style: theme.textTheme.titleSmall),
                Text(
                  fcStepState(step),
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
