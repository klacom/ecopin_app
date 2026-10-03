import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_shimmer_card.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';

class FcMetricsHeader extends ConsumerWidget {
  const FcMetricsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myCleanupTasksProvider);
    final profileAsync = ref.watch(profileProvider);

    return tasksAsync.when(
      data: (tasks) {
        final completed = tasks.where((t) => t.status == 'completed').length;
        final pending = tasks.where((t) => t.status != 'completed').length;

        final profile = profileAsync.value;
        final fullName = ((profile?['full_name'] as String?)?.trim()) ?? 'Crew';
        final firstName = fullName.isEmpty ? 'Crew' : fullName.split(' ').first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $firstName!',
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
      loading: () => const _MetricsSkeleton(),
      error: (err, stack) => const SizedBox(),
    );
  }
}

class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const FcShimmerCard(height: 60);
  }
}
