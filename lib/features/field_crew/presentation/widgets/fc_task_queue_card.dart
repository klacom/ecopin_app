import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import '../controllers/fc_dashboard_presentation.dart';
import '../controllers/fc_sync_ui_providers.dart';
import 'fc_task_status_badge.dart';

class FcTaskQueueCard extends ConsumerWidget {
  const FcTaskQueueCard({super.key, required this.task});
  final CleanupTask task;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
    button: true,
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(
          color:
              Theme.of(context).dividerTheme.color ??
              Theme.of(context).dividerColor,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        onTap: () async {
          await context.push(crewTaskPath(task.id));
          if (context.mounted) ref.invalidate(fcPendingSummaryProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(task.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                crewTaskLocation(task),
                style: Theme.of(context).textTheme.bodyMedium,
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
              Text(
                'Open task details',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.linkDark
                      : AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
