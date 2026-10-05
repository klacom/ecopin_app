import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_status_badge.dart';

class FcTaskSidebarCard extends StatelessWidget {
  final CleanupTask task;

  const FcTaskSidebarCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.spaceLG),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: AppTypography.h4.copyWith(color: AppColors.textPrimaryDark)),
                    if (task.isOutlier)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Outlier Collection Route',
                          style: AppTypography.caption.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppColors.spaceSM),
              FcTaskStatusBadge(status: task.status),
            ],
          ),
          const SizedBox(height: AppColors.spaceMD),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.location,
                  style: AppTypography.caption.copyWith(color: Colors.grey),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spaceMD),
          Text(task.description, style: AppTypography.body.copyWith(color: AppColors.textPrimaryDark)),
          const SizedBox(height: AppColors.spaceLG),
          Text('Assigned Crew (${task.assignedCrewIds.length})', style: AppTypography.h6.copyWith(color: AppColors.textPrimaryDark)),
          const SizedBox(height: AppColors.spaceSM),
          if (task.assignedCrewIds.isEmpty)
            Text('No crew assigned.', style: AppTypography.body.copyWith(color: Colors.grey))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: task.assignedCrewIds.map((id) {
                // Ideally fetch profile from a provider, but showing initials for now
                return Tooltip(
                  message: 'Crew $id',
                  child: CircleAvatar(
                    backgroundColor: AppColors.primaryDark.withValues(alpha: 0.2),
                    foregroundColor: AppColors.primaryDark,
                    child: Text(id.substring(0, 2).toUpperCase(), style: AppTypography.label),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
