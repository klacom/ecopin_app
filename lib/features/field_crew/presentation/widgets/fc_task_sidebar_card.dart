import 'package:flutter/material.dart';
import '../../data/models/cleanup_task_model.dart';
import '../controllers/fc_dashboard_presentation.dart';
import '../controllers/fc_task_detail_presentation.dart';
import 'fc_offline_ui.dart';
import 'fc_task_status_badge.dart';

class FcTaskSidebarCard extends StatelessWidget {
  const FcTaskSidebarCard({super.key, required this.task, this.address});
  final CleanupTask task;
  final String? address;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FcOfflineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FcTaskStatusBadge(status: task.status),
              Text(
                '${crewTaskLabel(task.priority)} priority',
                style: text.bodySmall,
              ),
              if (task.dispatchKind == 'sweeper')
                Text('Sweeper route', style: text.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
          Text(task.title, style: text.headlineSmall),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  taskPlace(task, resolvedAddress: address),
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
          if (task.description.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(task.description, style: text.bodyMedium),
          ],
          const Divider(height: 32),
          Row(
            children: [
              const Icon(Icons.groups_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.assignedTeamName?.trim().isNotEmpty == true
                      ? task.assignedTeamName!
                      : 'Assigned crew',
                  style: text.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (task.assignedMembers.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final member in task.assignedMembers)
                  Chip(
                    avatar: const Icon(Icons.person_outline, size: 18),
                    label: Text(
                      member['full_name']?.toString().trim().isNotEmpty == true
                          ? member['full_name'].toString()
                          : 'Member name unavailable',
                    ),
                  ),
              ],
            )
          else
            Text(
              task.assignedCrewIds.isEmpty
                  ? 'No crew assigned'
                  : '${task.assignedCrewIds.length} assigned ${task.assignedCrewIds.length == 1 ? 'member' : 'members'} · names unavailable',
              style: text.bodyMedium,
            ),
        ],
      ),
    );
  }
}
