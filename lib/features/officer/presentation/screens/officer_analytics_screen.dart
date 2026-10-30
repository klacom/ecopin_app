import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/officer/providers/officer_dashboard_provider.dart';

class OfficerAnalyticsScreen extends ConsumerWidget {
  const OfficerAnalyticsScreen({super.key});

  Widget _buildSectionContainer(BuildContext context, Widget child) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(officerDashboardProvider).stats;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(officerDashboardProvider).loadStats(),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(officerDashboardProvider).loadStats(),
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

    return _buildSectionContainer(
      context,
      Padding(
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
    return _buildSectionContainer(
      context,
      Padding(
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
}
