import 'package:ecopin_app/core/utils/csat_rating_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/my_performance_provider.dart';

/// Short greeting plus the crew's team name when the server supplies it.
class FcGreetingHeader extends ConsumerWidget {
  const FcGreetingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(profileProvider).value?['full_name'];
    final firstName = name is String && name.trim().isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).first
        : null;
    final teamName =
        ref.watch(myCrewPerformanceProvider).value?['crew_team']?['name']
            as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            firstName == null ? 'Your assigned work' : 'Hello, $firstName',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (teamName != null && teamName.trim().isNotEmpty)
          Text(
            teamName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Two summary numbers that open the Performance screen. Unavailable data
/// reads as "—", never as a zero the crew did not earn.
class FcMetricsHeader extends ConsumerWidget {
  const FcMetricsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final perf =
        ref.watch(myCrewPerformanceProvider).value?['performance']
            as Map<String, dynamic>?;
    final completed = perf?['total_completed'];
    final rating = perf?['avg_satisfaction_rating'];
    final emoji = CsatRatingScale.fromAverage(rating)?.emoji;
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        onTap: () => context.push(FieldCrewAppRoutes.performance),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Your results',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const ExcludeSemantics(child: Icon(Icons.chevron_right)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _Stat(
                    label: 'Finished jobs you were on',
                    value: completed == null ? '—' : '$completed',
                  ),
                  _Stat(
                    label: 'Citizen rating',
                    value: rating == null
                        ? '—'
                        : '${emoji == null ? '' : '$emoji '}$rating',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
