import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/officer/providers/officer_optimization_provider.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import 'package:intl/intl.dart';

class OfficerOptimizationScreen extends ConsumerStatefulWidget {
  const OfficerOptimizationScreen({super.key});

  @override
  ConsumerState<OfficerOptimizationScreen> createState() =>
      _OfficerOptimizationScreenState();
}

class _OfficerOptimizationScreenState
    extends ConsumerState<OfficerOptimizationScreen> {
  String _selectedWeather = 'normal';
  String _selectedTraffic = 'low';
  String? _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(optimizationProvider).loadRuns();
      ref.read(optimizationProvider).loadTemplates();
    });
  }

  void _triggerOptimization() {
    final Map<String, dynamic> settings = {
      'weather_condition': _selectedWeather,
      'traffic_condition': _selectedTraffic,
      'travel_mode': 'DRIVING',
      'break_duration_min': 60,
      'overtime_tolerance_min': 15,
      'priority_age_weight': 50,
    };
    if (_selectedTemplateId != null && _selectedTemplateId!.isNotEmpty) {
      settings['_templateId'] = _selectedTemplateId;
    }

    ref.read(optimizationProvider).startPlanningJob(settings);
  }

  void _confirmDisassemble(BuildContext context, String runId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disassemble Dispatched Plan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Disassembling this optimization run will unassign all generated routes, disband active tasks, and restore reports back to the operational backlog.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rollback',
                hintText: 'e.g., Severe weather warning / Shift cancellation',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final reason = reasonController.text.trim().isNotEmpty
                  ? reasonController.text.trim()
                  : 'Manual officer disassembly';
              ref.read(optimizationProvider).disassemble(runId, reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Disassemble Plan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(optimizationProvider);
    final state = notifier.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Optimization'),
        actions: const [NotificationBadgeAction()],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(optimizationProvider).loadRuns(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Generator Panel
            _buildPlanningForm(state, isDark),
            const SizedBox(height: 16),

            // In-flight solver progress banner
            if (state.isGenerating) ...[
              _buildSolverProgressBanner(state, isDark),
              const SizedBox(height: 16),
            ],

            // Draft Plan Preview (if generated)
            if (state.draftPlan != null) ...[
              _buildDraftPlanCard(state, isDark),
              const SizedBox(height: 24),
            ],

            // Error display
            if (state.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error: ${state.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Section Header: Previous Runs
            const Text(
              'Optimization Runs History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildRunsList(state, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningForm(OptimizationState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Capacity-Aware Dispatch Planning',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weather & Traffic Selection
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedWeather,
                  decoration: const InputDecoration(
                    labelText: 'Weather',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('☀️ Clear / Normal')),
                    DropdownMenuItem(value: 'rain', child: Text('🌧️ Rain / Wet')),
                    DropdownMenuItem(value: 'storm', child: Text('⛈️ Severe Storm')),
                  ],
                  onChanged: state.isGenerating
                      ? null
                      : (v) => setState(() => _selectedWeather = v ?? 'normal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedTraffic,
                  decoration: const InputDecoration(
                    labelText: 'Traffic',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('🟢 Low Traffic')),
                    DropdownMenuItem(value: 'moderate', child: Text('🟡 Moderate')),
                    DropdownMenuItem(value: 'heavy', child: Text('🔴 Heavy Gridlock')),
                  ],
                  onChanged: state.isGenerating
                      ? null
                      : (v) => setState(() => _selectedTraffic = v ?? 'low'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isGenerating ? null : _triggerOptimization,
              icon: state.isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.bolt, color: Colors.black),
              label: Text(
                state.isGenerating ? 'Solving Optimization...' : 'Generate Dispatch Plan',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolverProgressBanner(OptimizationState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.solverMessage,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '${state.solverProgress}%',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: state.solverProgress / 100,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftPlanCard(OptimizationState state, bool isDark) {
    final plan = state.draftPlan!;
    final planId = plan['id']?.toString() ?? '';
    final capacity = state.capacity;
    final routes = state.proposedRoutes;
    final rejected = state.rejectedBundles;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.success, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Draft Plan Ready for Review',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => ref.read(optimizationProvider).clearDraft(),
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Dismiss Draft',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Capacity Stats Badges
          if (capacity != null) ...[
            Row(
              children: [
                _buildStatBadge(
                  'Payload Vol',
                  '${capacity['used_volume_m3'] ?? 0} / ${capacity['limit_volume_m3'] ?? 0} m³',
                  Icons.inventory_2_outlined,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  'Payload Wt',
                  '${capacity['used_weight_kg'] ?? 0} / ${capacity['limit_weight_kg'] ?? 0} kg',
                  Icons.scale_outlined,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  'Shift Hours',
                  '${capacity['used_hours'] ?? 0} / ${capacity['limit_hours'] ?? 0} h',
                  Icons.schedule_outlined,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Proposed Crew Routes
          Text(
            '${routes.length} Proposed Routes:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...routes.map((r) {
            final crewName = r['field_crews']?['name'] ?? r['crewName'] ?? 'Crew Route';
            final stops = (r['stops'] as List<dynamic>?) ?? [];
            final distanceKm = ((r['total_distance_meters'] as num?) ?? 0) / 1000;
            final durationMin = ((r['total_duration_minutes'] as num?) ?? 0).round();

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(crewName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          '${stops.length} stops · ${distanceKm.toStringAsFixed(1)} km · ~$durationMin min',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Rejected / Omitted Items
          if (rejected.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${rejected.length} Tasks Queued for Next Shift:',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatOperationalReason(rejected.first['reason']?.toString()),
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Action Buttons: Commit & Discard
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isCommitting
                      ? null
                      : () => ref.read(optimizationProvider).commitDraft(planId),
                  icon: state.isCommitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(state.isCommitting ? 'Dispatching...' : 'Commit & Dispatch'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => ref.read(optimizationProvider).clearDraft(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.black38 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRunsList(OptimizationState state, bool isDark) {
    if (state.isLoading && state.runs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.runs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('No optimization runs recorded yet.'),
      );
    }

    return Column(
      children: state.runs.map((run) {
        final dateStr = run['created_at'];
        final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
        final formattedDate =
            date != null ? DateFormat('MMM d, y · h:mm a').format(date) : 'N/A';
        final status = run['status']?.toString() ?? 'unknown';
        final runId = run['id']?.toString() ?? '';

        Color statusColor = Colors.grey;
        if (status == 'approved') statusColor = AppColors.success;
        if (status == 'proposed' || status == 'draft') statusColor = AppColors.warning;
        if (status == 'failed') statusColor = AppColors.error;
        if (status == 'disassembled') statusColor = Colors.purpleAccent;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${run['num_tasks_optimized'] ?? 0} tasks optimized',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  if (run['weather_condition'] != null) ...[
                    const Text(' · ', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${run['weather_condition']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
              if (status == 'approved') ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _confirmDisassemble(context, runId),
                    icon: const Icon(Icons.undo, size: 16, color: Colors.redAccent),
                    label: const Text(
                      'Disassemble Plan',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
