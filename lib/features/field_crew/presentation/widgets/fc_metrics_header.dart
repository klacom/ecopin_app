import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/my_performance_provider.dart';

class FcMetricsHeader extends ConsumerWidget {
  const FcMetricsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(profileProvider).value?['full_name'];
    final firstName = name is String && name.trim().isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).first
        : null;

    final perfAsync = ref.watch(myCrewPerformanceProvider);
    final perf = perfAsync.value?['performance'] as Map<String, dynamic>?;
    final crewTeam = perfAsync.value?['crew_team'] as Map<String, dynamic>?;
    final teamPerf = crewTeam?['performance'] as Map<String, dynamic>?;

    final totalCompleted = perf?['total_completed'] ?? 0;
    final rating = perf?['avg_satisfaction_rating'];
    final avgHours = perf?['avg_turnaround_hours'];

    final teamName = crewTeam?['name'] as String?;
    final teamRating = teamPerf?['avg_satisfaction_rating'];
    final teamCompleted = teamPerf?['total_completed'];

    String getSatisfactionEmoji(dynamic r) {
      if (r == null) return '';
      final numVal = num.tryParse(r.toString());
      if (numVal == null) return '';
      final rounded = numVal.round();
      if (rounded >= 5) return '😄 ';
      if (rounded == 4) return '😊 ';
      if (rounded == 3) return '😐 ';
      if (rounded == 2) return '😕 ';
      return '😢 ';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Semantics(
              header: true,
              child: Text(
                firstName == null ? 'Your assigned work' : 'Hello, $firstName',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (teamName != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  teamName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(FieldCrewAppRoutes.performance),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricItem(
                        icon: Icons.check_circle_outline,
                        iconColor: Colors.green,
                        label: 'Personal Done',
                        value: '$totalCompleted',
                      ),
                      Container(width: 1, height: 28, color: Theme.of(context).dividerColor.withOpacity(0.2)),
                      _MetricItem(
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        iconColor: Colors.amber,
                        label: 'Citizen CSAT',
                        value: rating != null ? '${getSatisfactionEmoji(rating)}$rating' : '—',
                      ),
                      Container(width: 1, height: 28, color: Theme.of(context).dividerColor.withOpacity(0.2)),
                      _MetricItem(
                        icon: Icons.timer_outlined,
                        iconColor: Colors.blueAccent,
                        label: 'Avg Speed',
                        value: avgHours != null ? '${avgHours}h' : '—',
                      ),
                    ],
                  ),
                  if (teamCompleted != null && teamCompleted > 0) ...[
                    const SizedBox(height: 8),
                    Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.15)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Team ${teamName ?? "Crew"}: $teamCompleted cleared • ${teamRating != null ? "${getSatisfactionEmoji(teamRating)}$teamRating" : "No rating yet"}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

