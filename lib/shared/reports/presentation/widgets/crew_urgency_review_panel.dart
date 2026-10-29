import 'package:dio/dio.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/data/models/crew_urgency_observation.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/fullscreen_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final crewUrgencyObservationsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, id) async {
      final response = await ref
          .watch(apiClientProvider)
          .getCrewUrgencyObservations(id);
      return (response.data['observations'] as List)
          .map((value) => Map<String, dynamic>.from(value as Map))
          .toList();
    });

class CrewUrgencyReviewPanel extends ConsumerWidget {
  const CrewUrgencyReviewPanel({super.key, required this.reportId});
  final String reportId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observations = ref.watch(crewUrgencyObservationsProvider(reportId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Crew on-site urgency observations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'Review observed conditions and supporting photos. Marking reviewed does not change trust or establish a false claim.',
            ),
            observations.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Column(
                children: [
                  const Text('Crew observations could not load.'),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      crewUrgencyObservationsProvider(reportId),
                    ),
                    child: const Text('Retry observations'),
                  ),
                ],
              ),
              data: (rows) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (rows.isEmpty)
                    const Text('No acknowledged crew observations.'),
                  for (final row in rows)
                    _ObservationReview(
                      key: ValueKey(row['operation_id']),
                      reportId: reportId,
                      observation: row,
                    ),
                  if (rows.length == 50)
                    const Text('Showing the latest 50 observations.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservationReview extends ConsumerStatefulWidget {
  const _ObservationReview({
    super.key,
    required this.reportId,
    required this.observation,
  });
  final String reportId;
  final Map<String, dynamic> observation;
  @override
  ConsumerState<_ObservationReview> createState() => _ObservationReviewState();
}

class _ObservationReviewState extends ConsumerState<_ObservationReview> {
  final _reason = TextEditingController();
  String _operation = const Uuid().v4();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _reason.text.trim().length < 3) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .reviewCrewUrgencyObservation(
            widget.reportId,
            widget.observation['operation_id'] as String,
            reason: _reason.text.trim(),
            operationId: _operation,
          );
      if (mounted) {
        ref.invalidate(crewUrgencyObservationsProvider(widget.reportId));
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.response?.data is Map
              ? e.response?.data['message']?.toString()
              : 'Review was not confirmed. Your reason is retained.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Review was not confirmed. Your reason is retained.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.observation, review = row['review'];
    final evidence = (row['evidence_snapshot'] as Map?) ?? {};
    final photos = <String>[];
    for (final slot in ['before', 'after']) {
      final entries = evidence['${slot}_photos'];
      if (entries is List) {
        for (final p in entries) {
          if (p is Map && p['url'] is String) photos.add(p['url'] as String);
        }
      }
      if (entries is! List || entries.isEmpty) {
        final url = evidence['${slot}_photo_url'];
        if (url is String) photos.add(url);
      }
    }
    final safePhotos = photos
        .where((value) {
          final uri = Uri.tryParse(value);
          return uri?.scheme == 'https' && uri!.host.isNotEmpty;
        })
        .toSet()
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            crewUrgencyLabels[row['observed_result']] ?? 'On-site observation',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(row['conditions']?.toString() ?? ''),
          Text('Recorded by server: ${row['recorded_at']}'),
          const Text('Evidence available when this observation synced:'),
          for (var i = 0; i < safePhotos.length; i++)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FullScreenImageView(imageUrl: safePhotos[i]),
                ),
              ),
              child: Text('View saved evidence ${i + 1}'),
            ),
          if (safePhotos.isEmpty)
            const Text(
              'No synced photos in this snapshot. Check report evidence for later uploads.',
            ),
          if (review is Map) ...[
            Text('Reviewed: ${review['reason']}'),
            Text('Review recorded: ${review['reviewed_at']}'),
          ] else ...[
            const Text('Pending officer review'),
            TextField(
              controller: _reason,
              enabled: !_saving,
              minLines: 2,
              maxLines: 4,
              maxLength: 1500,
              decoration: const InputDecoration(
                labelText: 'Officer review reason (required)',
              ),
              onChanged: (_) => setState(() => _operation = const Uuid().v4()),
            ),
            if (_error != null) Text(_error!),
            FilledButton(
              onPressed: _saving || _reason.text.trim().length < 3
                  ? null
                  : _save,
              child: Text(_saving ? 'Saving…' : 'Mark observation reviewed'),
            ),
            TextButton(
              onPressed: () => ref.invalidate(
                crewUrgencyObservationsProvider(widget.reportId),
              ),
              child: const Text('Refresh saved review'),
            ),
          ],
        ],
      ),
    );
  }
}
