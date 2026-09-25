import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/officer/providers/officer_optimization_provider.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import 'package:intl/intl.dart';

class OfficerOptimizationScreen extends ConsumerStatefulWidget {
  const OfficerOptimizationScreen({super.key});

  @override
  ConsumerState<OfficerOptimizationScreen> createState() => _OfficerOptimizationScreenState();
}

class _OfficerOptimizationScreenState extends ConsumerState<OfficerOptimizationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(optimizationProvider).loadRuns();
    });
  }

  void _generateOptimization() {
    ref.read(optimizationProvider).runOptimization({
      'weather_condition': 'normal',
      'traffic_condition': 'low',
    });
  }

  void _showRunDetails(BuildContext context, dynamic run) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Optimization Run Details',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Status: ${run['status']?.toString().toUpperCase()}'),
              Text('Tasks Optimized: ${run['num_tasks_optimized']}'),
              Text('Weather: ${run['weather_condition']}'),
              Text('Traffic: ${run['traffic_condition']}'),
              const SizedBox(height: 24),
              if (run['status'] == 'proposed') ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(optimizationProvider).approveRun(run['id']);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(optimizationProvider).discardRun(run['id']);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        child: const Text('Discard'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(optimizationProvider);
    final state = notifier.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Optimization'),
        elevation: 0,
        actions: const [NotificationBadgeAction()],
      ),
      body: Column(
        children: [
          _buildControls(state),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const Divider(),
          _buildRunsList(state),
        ],
      ),
    );
  }

  Widget _buildControls(OptimizationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: state.isGenerating ? null : _generateOptimization,
            icon: state.isGenerating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.rocket_launch),
            label: Text(state.isGenerating ? 'Generating...' : 'Generate Optimization'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunsList(OptimizationState state) {
    if (state.isLoading && state.runs.isEmpty) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (state.runs.isEmpty) {
      return const Expanded(child: Center(child: Text('No optimization runs yet.')));
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => ref.read(optimizationProvider).loadRuns(),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 80), // To clear bottom nav bar
          itemCount: state.runs.length,
          itemBuilder: (context, index) {
            final run = state.runs[index];
            final dateStr = run['created_at'];
            final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
            final formattedDate = date != null ? DateFormat('MMM d, y h:mm a').format(date) : 'N/A';

            Color statusColor = Colors.grey;
            if (run['status'] == 'proposed') statusColor = AppColors.warning;
            if (run['status'] == 'approved') statusColor = AppColors.success;
            if (run['status'] == 'discarded') statusColor = Colors.grey;
            if (run['status'] == 'failed') statusColor = AppColors.error;

            return ListTile(
              title: Text('Run from $formattedDate', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          run['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${run['num_tasks_optimized'] ?? 0} tasks'),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showRunDetails(context, run),
            );
          },
        ),
      ),
    );
  }
}
