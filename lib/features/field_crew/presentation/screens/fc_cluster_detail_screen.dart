import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import '../widgets/tasks/fc_cluster_task_row_item.dart';

class FcClusterDetailScreen extends StatelessWidget {
  const FcClusterDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cluster #1 Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Context Header
            Container(
              padding: const EdgeInsets.all(AppColors.spaceMD),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppColors.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optimized Route Plan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoCol(context, Icons.access_time, '2h 30m', 'ETA', theme.colorScheme.primary),
                      _buildInfoCol(context, Icons.wb_sunny_outlined, '28°C', 'Sunny', Colors.orange),
                      _buildInfoCol(context, Icons.directions_car, 'Light', 'Traffic', AppColors.success),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.spaceLG),
            
            // Tasks Section
            Text(
              'Tasks (3)',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppColors.spaceMD),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(height: AppColors.spaceMD),
              itemBuilder: (context, index) {
                return _buildDetailedTaskItem(context, index);
              },
            ),
            const SizedBox(height: 80), // padding for FAB
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD),
        width: double.infinity,
        child: FloatingActionButton.extended(
          onPressed: () {
            // TODO: Navigate to map and layout path
          },
          icon: const Icon(Icons.map),
          label: const Text('Track All Tasks on Map', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildInfoCol(BuildContext context, IconData icon, String value, String label, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: AppColors.spaceXS),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedTaskItem(BuildContext context, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Illegal Dumping Report ${index + 1}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppColors.radiusChip),
                ),
                child: Text(
                  'Pending',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spaceSM),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '123 Main St, Springfield • ${(index + 1) * 2.5} km',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spaceSM),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              Text(
                'Issue: Large Appliance',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppColors.spaceMD),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.map, size: 16),
              label: const Text('Track Single Task'),
            ),
          ),
        ],
      ),
    );
  }
}
