import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_status_badge.dart';
import 'package:go_router/go_router.dart';

class FcTaskListTile extends StatelessWidget {
  final CleanupTask task;

  const FcTaskListTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/field-crew/tasks/${task.id}'),
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppColors.spaceMD),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTypography.h5.copyWith(color: AppColors.textPrimaryDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppColors.spaceMD),
                FcTaskStatusBadge(status: task.status),
              ],
            ),
            const SizedBox(height: AppColors.spaceSM),
            Text(
              task.description,
              style: AppTypography.body.copyWith(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppColors.spaceSM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, size: 16, color: AppColors.primaryDark),
                    const SizedBox(width: 4),
                    Text(
                      '${task.assignedCrewIds.length} Assigned',
                      style: AppTypography.caption.copyWith(color: AppColors.primaryDark),
                    ),
                  ],
                ),
                Text(
                  task.createdAt.toString().split(' ').first,
                  style: AppTypography.caption.copyWith(color: Colors.grey),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
