import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';

class FcShiftProgressBar extends ConsumerWidget {
  const FcShiftProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myCleanupTasksProvider);

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox();
        final completed = tasks.where((t) => t.status == 'completed').length;
        final total = tasks.length;
        final progress = total > 0 ? completed / total : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Shift Progress', style: AppTypography.h6.copyWith(color: AppColors.textPrimaryDark)),
                Text('$completed/$total Tasks', style: AppTypography.label.copyWith(color: AppColors.primaryDark)),
              ],
            ),
            const SizedBox(height: AppColors.spaceSM),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppColors.radiusButton),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: AppColors.surfaceDark,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
              ),
            ),
          ],
        );
      },
      loading: () => const _ProgressBarSkeleton(),
      error: (err, stack) => const SizedBox(),
    );
  }
}

class _ProgressBarSkeleton extends StatelessWidget {
  const _ProgressBarSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppColors.radiusButton),
      ),
    );
  }
}
