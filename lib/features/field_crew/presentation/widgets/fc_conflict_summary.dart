import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_result.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'fc_offline_ui.dart';

/// Informational server outcomes. No manual conflict resolution is offered.
class FcConflictSummary extends ConsumerStatefulWidget {
  const FcConflictSummary({super.key});
  @override
  ConsumerState<FcConflictSummary> createState() => _FcConflictSummaryState();
}

class _FcConflictSummaryState extends ConsumerState<FcConflictSummary> {
  DateTime? _shownForSync;
  bool _dismissed = false;
  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(fcSyncStateProvider);
    if (sync.phase != FcSyncPhase.success &&
        sync.phase != FcSyncPhase.partialFailure) {
      return const SizedBox.shrink();
    }
    final events =
        sync.lastMutationResult?.conflictEvents ?? const <FcConflictEvent>[];
    if (events.isEmpty || sync.lastSyncAt == null) {
      return const SizedBox.shrink();
    }
    if (_shownForSync != sync.lastSyncAt) {
      _shownForSync = sync.lastSyncAt;
      _dismissed = false;
    }
    if (_dismissed) return const SizedBox.shrink();
    return FcResponseUpdates(
      events: events,
      onDismiss: () => setState(() => _dismissed = true),
    );
  }
}

class FcResponseUpdates extends StatelessWidget {
  const FcResponseUpdates({
    super.key,
    required this.events,
    required this.onDismiss,
  });
  final List<FcConflictEvent> events;
  final VoidCallback onDismiss;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: FcOfflineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Response updates',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: onDismiss,
                tooltip: 'Dismiss response updates',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            'Some changes were merged, kept by the server, or sent for review. Open the task for its current instructions.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            initiallyExpanded: events.length <= 3,
            title: Text(
              '${events.length} response ${events.length == 1 ? 'update' : 'updates'}',
            ),
            children: events
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ExcludeSemantics(
                          child: Icon(Icons.info_outline, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event.message,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );
}
