import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import '../widgets/dashboard/fc_offline_sync_banner.dart';
import '../widgets/dashboard/fc_performance_metrics_card.dart';
import '../widgets/dashboard/fc_priority_tasks_card.dart';

class FieldCrewDashboardScreen extends ConsumerWidget {
  const FieldCrewDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final fullName =
        profileAsync.value?['full_name'] as String? ?? 'Field Crew Member';

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = textPrimary.withValues(alpha: 0.6);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom Premium Header App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppColors.spaceMD,
                  AppColors.spaceMD,
                  AppColors.spaceMD,
                  AppColors.spaceSM,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: AppColors.spaceSM),
                    // Greeting text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: AppTypography.caption.copyWith(
                              color: textSecondary,
                            ),
                          ),
                          Text(
                            fullName,
                            style: AppTypography.h5.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Notification Icon
                    const NotificationBadgeAction(),
                  ],
                ),
              ),
            ),

            // Dashboard Widgets List
            SliverList(
              delegate: SliverChildListDelegate([
                // 1. Offline Sync Banner (Top priority alert banner)
                const FcOfflineSyncBanner(),

                // 2. Weekly Performance Metrics Widget
                const FcPerformanceMetricsCard(
                  completedTasks: 18,
                  totalTasks: 24,
                  quality: WorkQuality.great,
                  dailyCounts: [3, 5, 4, 7, 6, 8, 5],
                ),

                // 3. Priority and Feasible Tasks Card
                const FcPriorityTasksCard(),

                // Extra spacing at the bottom so content clears the bottom floating navigation bar
                const SizedBox(height: 100),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
