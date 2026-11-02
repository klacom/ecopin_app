import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_performance_presentation.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_offline_ui.dart';
import 'package:ecopin_app/features/field_crew/providers/my_performance_provider.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';

/// “Your results”: the crew member's own numbers first, then the squad's, in
/// the same words as the Home card. Anything the server did not send is left
/// out or written as unavailable, never shown as a zero.
class FieldCrewPerformanceScreen extends ConsumerWidget {
  const FieldCrewPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCrewPerformanceProvider);
    final results = crewResultsFrom(async.value);
    Future<void> reload() async {
      ref.invalidate(myCrewPerformanceProvider);
      await ref.read(myCrewPerformanceProvider.future);
    }

    final Widget body;
    if (results == null && async.isLoading) {
      body = const Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Loading your results',
        ),
      );
    } else if (results == null) {
      body = AppStateView(
        title: 'Your results are not available',
        message:
            'Check your signal and try again. If it keeps happening, tell the office.',
        icon: Icons.cloud_off_outlined,
        actionLabel: 'Try again',
        onAction: reload,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _YouCard(results: results),
            const SizedBox(height: 12),
            if (results.squad != null || results.squadName != null) ...[
              _SquadCard(results: results),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Ratings come from residents after a cleanup is closed.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Your results')),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _YouCard extends StatelessWidget {
  const _YouCard({required this.results});
  final CrewResults results;

  @override
  Widget build(BuildContext context) {
    final you = results.you;
    final rating = you.rating;
    return FcOfflineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('You', style: Theme.of(context).textTheme.titleMedium),
          ),
          _Stat(
            label: 'Finished jobs you were on',
            value: you.completed == null ? '—' : '${you.completed}',
          ),
          const Divider(height: 1),
          _Stat(
            label: 'Citizen rating',
            value: rating == null ? 'No ratings yet' : crewRatingText(rating),
            detail: rating == null
                ? 'Residents rate a cleanup after it is closed. Your rating shows here once they do.'
                : '${crewRatingWord(rating)} · ${crewRatingCount(you.ratingCount)}',
          ),
        ],
      ),
    );
  }
}

class _SquadCard extends StatelessWidget {
  const _SquadCard({required this.results});
  final CrewResults results;

  @override
  Widget build(BuildContext context) {
    final squad = results.squad;
    final rating = squad?.rating;
    final rows = <(String, String)>[
      if (squad?.completed != null)
        ('Finished jobs for your squad', '${squad!.completed}'),
      if (squad != null)
        (
          'Squad rating',
          rating == null
              ? 'No ratings yet'
              : '${crewRatingText(rating)} · ${crewRatingCount(squad.ratingCount)}',
        ),
    ];
    return FcOfflineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              results.squadName == null
                  ? 'Your squad'
                  : 'Your squad: ${results.squadName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final (label, value) in rows) FcOfflineFact(label, value),
        ],
      ),
    );
  }
}

/// A label, its value large, and an optional sentence under it.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.detail});
  final String label, value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(detail!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
