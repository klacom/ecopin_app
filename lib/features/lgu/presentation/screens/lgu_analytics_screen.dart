import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/lgu/providers/lgu_dashboard_provider.dart';

class LguAnalyticsScreen extends ConsumerWidget {
  const LguAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(lguDashboardProvider).stats;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: () => ref.read(lguDashboardProvider).loadStats(),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(lguDashboardProvider).loadStats(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (stats) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildResolutionRateCard(stats, context),
                const SizedBox(height: 16),
                _buildIssueDistributionCard(stats, context),
                const SizedBox(height: 16),
                _buildTrendsCard(stats, context),
                const SizedBox(height: 96),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResolutionRateCard(DashboardStats stats, BuildContext context) {
    final total = stats.totalReports;
    final resolved = stats.resolved;
    final resolutionRate = total > 0 ? (resolved / total * 100).toInt() : 0;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resolution Rate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$resolutionRate%',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of $total reports resolved',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: resolutionRate / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueDistributionCard(
    DashboardStats stats,
    BuildContext context,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Status Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              'Unresolved',
              stats.unresolved,
              stats.totalReports,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'In Progress',
              stats.inProgress,
              stats.totalReports,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Resolved',
              stats.resolved,
              stats.totalReports,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Closed',
              stats.closed,
              stats.totalReports,
              Colors.grey,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Waiting for Feedback',
              stats.waitingForFeedback,
              stats.totalReports,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text('$count ($percentage%)')],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsCard(DashboardStats stats, BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Reports',
                    stats.totalReports.toString(),
                    Icons.description,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Active Issues',
                    (stats.unresolved + stats.inProgress).toString(),
                    Icons.error_outline,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Completed',
                    stats.resolved.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Pending Review',
                    stats.waitingForFeedback.toString(),
                    Icons.feedback,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
