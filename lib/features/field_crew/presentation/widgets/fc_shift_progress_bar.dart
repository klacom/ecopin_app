import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import '../controllers/fc_dashboard_presentation.dart';
import 'fc_offline_ui.dart';

/// Progress across every assignment the app has loaded. It is not today's
/// total, and the card says so in plain words.
class FcShiftProgressBar extends StatelessWidget {
  const FcShiftProgressBar({super.key, required this.tasks});
  final List<CleanupTask> tasks;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = tasks
        .where((task) => crewTaskKey(task.status) == 'completed')
        .length;
    final cancelled = tasks
        .where((task) => crewTaskKey(task.status) == 'cancelled')
        .length;
    final left = tasks.length - completed - cancelled;
    final bar = theme.brightness == Brightness.dark
        ? AppColors.linkDark
        : AppColors.accent;
    return FcOfflineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 12,
            runSpacing: 4,
            children: [
              Semantics(
                header: true,
                child: Text(
                  '$completed of ${tasks.length} jobs done',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text('$left left', style: theme.textTheme.bodyMedium),
            ],
          ),
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: completed / tasks.length,
                minHeight: 10,
                color: bar,
                backgroundColor: bar.withValues(alpha: .2),
                semanticsLabel: 'Jobs done: $completed of ${tasks.length}',
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            cancelled == 0
                ? 'All jobs assigned to you, not only today.'
                : 'All jobs assigned to you, not only today.\n$cancelled cancelled.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
