import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import '../controllers/fc_dashboard_presentation.dart';
import '../controllers/fc_sync_ui_providers.dart';
import 'fc_offline_ui.dart';
import 'fc_task_status_badge.dart';

class FcCurrentObjectiveCard extends ConsumerWidget {
  const FcCurrentObjectiveCard({super.key, required this.task});
  final CleanupTask task;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FcOfflineCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Current task',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FcTaskStatusBadge(status: task.status),
            Text(
              '${crewTaskLabel(task.priority)} priority',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(task.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(
              child: Icon(Icons.location_on_outlined, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                crewTaskLocation(task),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppButton(
          text: 'Open current task',
          onPressed: () async {
            await context.push(crewTaskPath(task.id));
            if (context.mounted) ref.invalidate(fcPendingSummaryProvider);
          },
        ),
      ],
    ),
  );
}
