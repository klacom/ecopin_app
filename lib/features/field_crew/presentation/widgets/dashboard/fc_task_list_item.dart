import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';

enum TaskPriority {
  high,
  medium,
  low;

  Color get color {
    switch (this) {
      case TaskPriority.high:
        return AppColors.error;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.success;
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }
}

enum TaskStatus {
  pending,
  inProgress,
  done;

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.pending:
        return Colors.grey;
      case TaskStatus.inProgress:
        return AppColors.info;
      case TaskStatus.done:
        return AppColors.success;
    }
  }
}

class FcTaskListItem extends StatelessWidget {
  final String title;
  final String location;
  final TaskPriority priority;
  final TaskStatus status;
  final String estimatedTime;
  final VoidCallback? onTap;

  const FcTaskListItem({
    super.key,
    required this.title,
    required this.location,
    required this.priority,
    required this.status,
    required this.estimatedTime,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = textPrimary.withValues(alpha: 0.6);
    final itemBg = isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surfaceLight;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppColors.spaceXS),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(AppColors.radiusCard - 4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusCard - 4),
          child: Padding(
            padding: const EdgeInsets.all(AppColors.spaceMD),
            child: Row(
              children: [
                // Priority color indicator dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: priority.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: priority.color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppColors.spaceMD),
                // Task details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.body.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: AppTypography.caption.copyWith(
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppColors.spaceMD),
                // Status chip & Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppColors.spaceSM,
                        vertical: AppColors.spaceXS - 2,
                      ),
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppColors.radiusChip),
                        border: Border.all(
                          color: status.color.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.label,
                        style: AppTypography.caption.copyWith(
                          color: status.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estimatedTime,
                      style: AppTypography.caption.copyWith(
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
