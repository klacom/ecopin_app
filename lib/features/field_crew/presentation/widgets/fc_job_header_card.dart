import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import '../controllers/fc_task_detail_presentation.dart';
import 'fc_current_objective_card.dart';
import 'fc_offline_ui.dart';
import 'fc_task_deadline_indicator.dart';
import 'fc_task_status_badge.dart';

/// Identity of the job: written status and priority, full title, address,
/// instructions, response deadline, a map shortcut and the crew (collapsed).
class FcJobHeaderCard extends StatelessWidget {
  const FcJobHeaderCard({
    super.key,
    required this.task,
    required this.reports,
    this.address,
    this.showDeadline = true,
  });
  final CleanupTask task;
  final List<ReportModel> reports;
  final String? address;
  final bool showDeadline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = taskPlaceParts(task, resolvedAddress: address);
    final members = task.assignedMembers.isNotEmpty
        ? task.assignedMembers.length
        : task.assignedCrewIds.length;
    final team = task.assignedTeamName?.trim().isNotEmpty == true
        ? task.assignedTeamName!
        : 'Assigned crew';
    return FcOfflineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FcTaskStatusBadge(status: task.status),
              FcPriorityChip(priority: task.priority),
              if (task.dispatchKind == 'sweeper')
                Text('Sweeper route', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(task.title, style: theme.textTheme.titleLarge),
          ),
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
          if (task.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(task.description, style: theme.textTheme.bodyMedium),
          ],
          if (showDeadline)
            FcTaskDeadlineIndicator(inline: true, reports: reports),
          const SizedBox(height: 16),
          AppButton(
            text: 'Show on map',
            icon: Icons.map_outlined,
            variant: ButtonVariant.secondary,
            height: 48,
            onPressed: () => context.go(FieldCrewAppRoutes.map),
          ),
          const SizedBox(height: 4),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              leading: const Icon(Icons.groups_outlined),
              title: Text(team, style: theme.textTheme.titleMedium),
              subtitle: Text(
                members == 0
                    ? 'No crew assigned'
                    : '$members ${members == 1 ? 'member' : 'members'}',
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.assignedMembers.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final member in task.assignedMembers)
                        Chip(
                          avatar: const Icon(Icons.person_outline, size: 18),
                          label: Text(
                            member['full_name']?.toString().trim().isNotEmpty ==
                                    true
                                ? member['full_name'].toString()
                                : 'Name not available',
                          ),
                        ),
                    ],
                  )
                else
                  Text(
                    members == 0
                        ? 'No crew assigned.'
                        : 'Names are not available.',
                    style: theme.textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
