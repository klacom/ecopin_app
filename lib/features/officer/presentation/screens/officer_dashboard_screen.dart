import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/officer/providers/officer_dashboard_provider.dart';

class OfficerDashboardScreen extends ConsumerStatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  ConsumerState<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends ConsumerState<OfficerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(officerDashboardProvider).stats;

    return Scaffold(
      appBar: AppBar(title: const Text('LGU Dashboard'), elevation: 0),
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
                const Text(
                  'Overview',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStatsGrid(stats),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Total Reports',
          stats.totalReports.toString(),
          Icons.description,
          Colors.blue,
        ),
        _buildStatCard(
          'Unresolved',
          stats.unresolved.toString(),
          Icons.error_outline,
          Colors.red,
        ),
        _buildStatCard(
          'In Progress',
          stats.inProgress.toString(),
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Resolved',
          stats.resolved.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Closed',
          stats.closed.toString(),
          Icons.done_all,
          Colors.grey,
        ),
        _buildStatCard(
          'Feedback Waiting',
          stats.waitingForFeedback.toString(),
          Icons.feedback,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}


