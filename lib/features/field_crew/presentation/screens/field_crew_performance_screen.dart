import 'package:ecopin_app/core/utils/csat_rating_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/features/field_crew/providers/my_performance_provider.dart';

class FieldCrewPerformanceScreen extends ConsumerWidget {
  const FieldCrewPerformanceScreen({super.key});

  String _getSatisfactionEmoji(dynamic r) {
    final entry = CsatRatingScale.fromAverage(r);
    return entry == null ? '—' : '${entry.emoji} ${entry.label}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final perfAsync = ref.watch(myCrewPerformanceProvider);

    final perf = perfAsync.value?['performance'] as Map<String, dynamic>?;
    final crewTeam = perfAsync.value?['crew_team'] as Map<String, dynamic>?;
    final teamPerf = crewTeam?['performance'] as Map<String, dynamic>?;

    final totalCompleted = perf?['total_completed'] ?? 0;
    final rating = perf?['avg_satisfaction_rating'];
    final totalRatings = perf?['total_ratings_received'] ?? 0;
    final avgHours = perf?['avg_turnaround_hours'];

    final teamName = crewTeam?['name'] as String? ?? 'Field Squad';
    final teamLead = crewTeam?['team_lead'] as Map<String, dynamic>?;
    final teamLeadName = teamLead?['full_name'] as String? ?? 'Assigned Lead';
    final teamCompleted = teamPerf?['total_completed'] ?? 0;
    final teamRating = teamPerf?['avg_satisfaction_rating'];
    final teamRatingsCount = teamPerf?['total_ratings_received'] ?? 0;
    final teamAvgHours = teamPerf?['avg_turnaround_hours'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Performance & CSAT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myCrewPerformanceProvider);
          await ref.read(myCrewPerformanceProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppColors.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Personal Performance Card
              Container(
                padding: const EdgeInsets.all(AppColors.spaceLG),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E3A8A), const Color(0xFF172554)]
                        : [const Color(0xFF0052CC), const Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppColors.radiusCard),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x260052CC),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FIELD CREW RECORD',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            teamName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppColors.spaceMD),
                    Text(
                      rating != null ? '$rating / 5.0' : 'No ratings yet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rating != null
                          ? '${_getSatisfactionEmoji(rating)} • Verified citizen ratings ($totalRatings received)'
                          : 'Citizen ratings will appear after assigned cleanup tasks are closed',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppColors.spaceLG),

              // KPI Statistics Grid
              Text(
                'Personal Accomplishments',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppColors.spaceSM),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline,
                      iconColor: AppColors.success,
                      title: 'Tasks Resolved',
                      value: '$totalCompleted',
                      subtitle: 'Direct operations',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppColors.spaceMD),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFF0288D1),
                      title: 'Avg Turnaround',
                      value: avgHours != null ? '${avgHours}h' : '—',
                      subtitle: 'Response to resolution',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppColors.spaceLG),

              // Squad Collective Standing
              Text(
                'Squad Operations ($teamName)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppColors.spaceSM),
              Container(
                padding: const EdgeInsets.all(AppColors.spaceMD),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppColors.radiusCard),
                  border: Border.all(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  ),
                ),
                child: Column(
                  children: [
                    _SquadDetailRow(
                      icon: Icons.person_pin_outlined,
                      label: 'Squad Lead',
                      value: teamLeadName,
                    ),
                    const Divider(height: 20),
                    _SquadDetailRow(
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'Total Squad Cleared',
                      value: '$teamCompleted operations',
                    ),
                    const Divider(height: 20),
                    _SquadDetailRow(
                      icon: Icons.sentiment_satisfied_outlined,
                      label: 'Squad Average CSAT',
                      value: teamRating != null
                          ? '$teamRating (${_getSatisfactionEmoji(teamRating).split(" ").first}) • $teamRatingsCount reviews'
                          : 'No reviews yet',
                    ),
                    if (teamAvgHours != null) ...[
                      const Divider(height: 20),
                      _SquadDetailRow(
                        icon: Icons.speed_outlined,
                        label: 'Squad Avg Turnaround',
                        value: '${teamAvgHours}h per operation',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppColors.spaceLG),

              // Help / Explanation Banner
              Container(
                padding: const EdgeInsets.all(AppColors.spaceMD),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0052CC).withValues(alpha: 0.12)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(AppColors.radiusCard),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF0052CC).withValues(alpha: 0.3)
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppColors.spaceSM),
                    Expanded(
                      child: Text(
                        'Citizen satisfaction scores are calculated from verified post-cleanup ratings submitted by residents once reports are resolved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: AppColors.spaceSM),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquadDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SquadDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppColors.spaceSM),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
