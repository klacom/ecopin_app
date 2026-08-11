import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'fc_cluster_task_row_item.dart';

class FcTaskClusterCard extends StatelessWidget {
  final VoidCallback onTapCard;

  const FcTaskClusterCard({
    super.key,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD, vertical: AppColors.spaceSM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: InkWell(
        onTap: onTapCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section with Environmental Context
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.primary.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(AppColors.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cluster #1',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppColors.spaceSM, vertical: AppColors.spaceXS),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(AppColors.radiusChip),
                        ),
                        child: Text(
                          'Optimized',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                  // Info Row (ETA, Weather, Traffic)
                  Row(
                    children: [
                      _buildInfoBadge(
                        context,
                        icon: Icons.access_time,
                        label: '2h 30m',
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppColors.spaceSM),
                      _buildInfoBadge(
                        context,
                        icon: Icons.wb_sunny_outlined,
                        label: '28°C',
                        color: Colors.orange,
                      ),
                      const SizedBox(width: AppColors.spaceSM),
                      _buildInfoBadge(
                        context,
                        icon: Icons.directions_car,
                        label: 'Light',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tasks Section
            Padding(
              padding: const EdgeInsets.all(AppColors.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tasks in this cluster',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppColors.spaceSM),
                  // Mock list of tasks inside the cluster
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    separatorBuilder: (context, index) => const SizedBox(height: AppColors.spaceSM),
                    itemBuilder: (context, index) {
                      return FcClusterTaskRowItem(
                        title: 'Illegal Dumping Report ${index + 1}',
                        location: '123 Main St, Springfield',
                        distance: '${(index + 1) * 2.5} km',
                        onTrack: () {
                          // TODO: Implement track navigation for individual task
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onTapCard,
                      child: const Text('View Full Details'),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(BuildContext context, {required IconData icon, required String label, required Color color}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceSM, vertical: AppColors.spaceXS),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusButton),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
