import 'package:flutter/material.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import '../controllers/fc_dashboard_presentation.dart';
import 'fc_offline_ui.dart';

class FcShiftProgressBar extends StatelessWidget {
  const FcShiftProgressBar({super.key, required this.tasks});
  final List<CleanupTask> tasks;
  @override
  Widget build(BuildContext context) {
    final completed = tasks
        .where((task) => crewTaskKey(task.status) == 'completed')
        .length;
    final cancelled = tasks
        .where((task) => crewTaskKey(task.status) == 'cancelled')
        .length;
    return FcOfflineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Assigned task progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '$completed of ${tasks.length} loaded assignments are completed.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: completed / tasks.length,
              minHeight: 8,
              semanticsLabel:
                  'Completed loaded assignments: $completed of ${tasks.length}',
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Based on the loaded task records, including $cancelled cancelled assignments. This total is not limited to today or a shift. Locally recorded completion is shown separately.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
