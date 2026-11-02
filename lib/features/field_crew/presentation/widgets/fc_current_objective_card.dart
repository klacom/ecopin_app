import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import '../controllers/fc_dashboard_presentation.dart';
import '../controllers/fc_sync_ui_providers.dart';
import 'fc_offline_ui.dart';
import 'fc_task_status_badge.dart';

class FcCurrentObjectiveCard extends ConsumerWidget {
  const FcCurrentObjectiveCard({super.key, required this.task});
  final CleanupTask task;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final place = crewTaskPlace(task);
    final inProgress = crewTaskKey(task.status) == 'in_progress';
    return FcOfflineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Your job now',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FcTaskStatusBadge(status: task.status),
              FcPriorityChip(priority: task.priority),
            ],
          ),
          const SizedBox(height: 12),
          Text(task.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.location_on_outlined, size: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.primary, style: theme.textTheme.bodyMedium),
                    if (place.detail != null)
                      Text(
                        place.detail!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            text: inProgress ? 'Continue this job' : 'Open this job',
            icon: inProgress
                ? Icons.play_arrow_rounded
                : Icons.arrow_forward_rounded,
            onPressed: () async {
              await context.push(crewTaskPath(task.id));
              if (context.mounted) ref.invalidate(fcPendingSummaryProvider);
            },
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Show on map',
            icon: Icons.map_outlined,
            variant: ButtonVariant.secondary,
            onPressed: () => context.go(FieldCrewAppRoutes.map),
          ),
        ],
      ),
    );
  }
}

/// Written priority with a flag icon, so urgency never relies on color.
class FcPriorityChip extends StatelessWidget {
  const FcPriorityChip({super.key, required this.priority});
  final String priority;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
        border: Border.all(
          color: theme.dividerTheme.color ?? theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(child: Icon(Icons.flag_outlined, size: 16)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${crewTaskLabel(priority)} priority',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
